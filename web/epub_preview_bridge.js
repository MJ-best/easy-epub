(function () {
  const sessions = new Map();
  let nextSessionId = 0;

  function availabilityError() {
    if (typeof window.ePub !== "function") {
      return "epub.js renderer is not loaded.";
    }
    if (typeof window.JSZip === "undefined") {
      return "JSZip dependency is not loaded.";
    }
    return null;
  }

  function normalizeFlow(flow) {
    return flow === "paginated" ? "paginated" : "scrolled-doc";
  }

  function managerForFlow(flow) {
    return flow === "paginated" ? "default" : "continuous";
  }

  function toProgress(value) {
    const progress = Number(value);
    if (!Number.isFinite(progress)) {
      return 0;
    }
    return Math.max(0, Math.min(1, progress));
  }

  function normalizeHref(href) {
    return typeof href === "string" ? href.split("#")[0] : "";
  }

  function normalizeNavigation(items, depth, list) {
    if (!Array.isArray(items)) {
      return list;
    }

    for (const item of items) {
      if (!item) {
        continue;
      }

      const label =
        (item.label && item.label.trim()) ||
        (item.title && item.title.trim()) ||
        "";
      const href = typeof item.href === "string" ? item.href : "";
      if (label && href) {
        list.push({ label, href, depth });
      }

      const subitems = item.subitems || item.subItems || item.items || [];
      normalizeNavigation(subitems, depth + 1, list);
    }

    return list;
  }

  function setAttribute(hostElement, name, value) {
    if (value == null) {
      hostElement.removeAttribute(name);
      return;
    }
    hostElement.setAttribute(name, value);
  }

  function dispatch(hostElement, eventName, sessionId) {
    hostElement.dispatchEvent(
      new CustomEvent(eventName, {
        detail: {
          sessionId,
        },
      }),
    );
  }

  function dispatchWarning(hostElement, message, sessionId) {
    hostElement.dispatchEvent(
      new CustomEvent("easy-epub-warning", {
        detail: {
          sessionId,
          message,
        },
      }),
    );
  }

  function resolveChapterTitle(session, href) {
    const normalized = normalizeHref(href);
    const match = session.navigation.find(
      (item) => normalizeHref(item.href) === normalized,
    );
    return match ? match.label : "";
  }

  function emitError(session, error) {
    if (session.disposed) {
      return;
    }
    const message =
      error instanceof Error ? error.message : String(error || "EPUB render failed");
    setAttribute(session.hostElement, "data-error", message);
    dispatch(session.hostElement, "easy-epub-error", session.id);
  }

  function emitNavigation(session) {
    if (session.disposed) {
      return;
    }
    setAttribute(
      session.hostElement,
      "data-navigation",
      JSON.stringify(session.navigation),
    );
  }

  function emitRelocated(session, location) {
    if (session.disposed) {
      return;
    }
    const href =
      location?.start?.href ||
      location?.end?.href ||
      session.rendition?.location?.start?.href ||
      "";
    const progress = toProgress(
      location?.start?.percentage ?? location?.percentage ?? location?.end?.percentage,
    );
    const payload = {
      href,
      chapterTitle: resolveChapterTitle(session, href),
      progress,
    };
    setAttribute(
      session.hostElement,
      "data-location",
      JSON.stringify(payload),
    );
    dispatch(session.hostElement, "easy-epub-relocated", session.id);
  }

  async function loadNavigation(session) {
    try {
      const navigation = await session.book.loaded.navigation;
      const rawItems = navigation?.toc || navigation?.items || [];
      session.navigation = normalizeNavigation(rawItems, 0, []);
      emitNavigation(session);
    } catch (error) {
      session.navigation = [];
      emitNavigation(session);
      dispatchWarning(
        session.hostElement,
        error instanceof Error ? error.message : String(error || "Navigation unavailable"),
        session.id,
      );
    }
  }

  function clearHost(session) {
    session.hostElement.innerHTML = "";
    setAttribute(session.hostElement, "data-error", null);
    setAttribute(session.hostElement, "data-location", null);
  }

  function attachRenditionHandlers(session) {
    session.rendition.on("relocated", (location) => {
      emitRelocated(session, location);
    });
  }

  function queueOperation(session, operation) {
    const previous = session.operationQueue || Promise.resolve();
    const next = previous.catch(() => undefined).then(async () => {
      if (session.disposed) {
        return undefined;
      }
      return operation();
    });
    session.operationQueue = next.catch(() => undefined);
    return next;
  }

  async function resolveArchiveInput(objectUrl) {
    if (typeof objectUrl === "string" && objectUrl.startsWith("blob:")) {
      const response = await fetch(objectUrl);
      if (!response.ok) {
        throw new Error(`Failed to read EPUB blob: ${response.status} ${response.statusText}`);
      }
      return response.blob();
    }

    return objectUrl;
  }

  async function displaySession(session, target) {
    clearHost(session);
    session.rendition = session.book.renderTo(session.hostElement, {
      width: "100%",
      height: "100%",
      manager: managerForFlow(session.flow),
      flow: session.flow,
      allowScriptedContent: false,
    });
    attachRenditionHandlers(session);
    session.rendition.themes.fontSize(`${session.fontScale}%`);
    await session.rendition.display(target);
    emitNavigation(session);
    const currentLocation = session.rendition.currentLocation();
    if (currentLocation) {
      emitRelocated(session, currentLocation);
    }
    dispatch(session.hostElement, "easy-epub-ready", session.id);
  }

  async function cleanupSession(session) {
    if (session.cleanedUp) {
      return;
    }

    session.cleanedUp = true;

    if (session.rendition) {
      try {
        session.rendition.destroy();
      } catch (_) {
        // Ignore rendition cleanup failures during teardown.
      }
      session.rendition = null;
    }

    if (session.book) {
      try {
        session.book.destroy();
      } catch (_) {
        // Ignore book cleanup failures during teardown.
      }
      session.book = null;
    }

    clearHost(session);
    emitNavigation(session);

    if (session.objectUrl) {
      URL.revokeObjectURL(session.objectUrl);
      session.objectUrl = null;
    }
  }

  function currentTarget(session) {
    const location = session.rendition?.currentLocation();
    return (
      location?.start?.cfi ||
      location?.start?.href ||
      location?.end?.cfi ||
      location?.end?.href ||
      undefined
    );
  }

  async function create(hostElement, objectUrl, options) {
    const rendererError = availabilityError();
    if (rendererError) {
      throw new Error(rendererError);
    }

    let archiveInput;
    try {
      archiveInput = await resolveArchiveInput(objectUrl);
    } catch (error) {
      if (objectUrl) {
        URL.revokeObjectURL(objectUrl);
      }
      throw error;
    }

    const sessionId = `easy-epub-session-${++nextSessionId}`;
    const session = {
      id: sessionId,
      hostElement,
      objectUrl,
      flow: normalizeFlow(options?.flow),
      fontScale: Number(options?.fontScale) || 100,
      navigation: [],
      book: window.ePub(archiveInput),
      rendition: null,
      disposed: false,
      cleanedUp: false,
      operationQueue: Promise.resolve(),
    };
    sessions.set(sessionId, session);

    try {
      await queueOperation(session, async () => {
        await loadNavigation(session);
        await displaySession(session);
      });
      return sessionId;
    } catch (error) {
      session.disposed = true;
      await cleanupSession(session);
      sessions.delete(sessionId);
      emitError(session, error);
      throw error;
    }
  }

  async function setFlow(sessionId, flow) {
    const session = sessions.get(sessionId);
    if (!session) {
      return;
    }

    const nextFlow = normalizeFlow(flow);
    if (session.flow === nextFlow) {
      return;
    }

    try {
      await queueOperation(session, async () => {
        const target = currentTarget(session);
        session.flow = nextFlow;
        if (session.rendition) {
          session.rendition.destroy();
          session.rendition = null;
        }
        await displaySession(session, target);
      });
    } catch (error) {
      emitError(session, error);
      throw error;
    }
  }

  function setFontScale(sessionId, fontScale) {
    const session = sessions.get(sessionId);
    if (!session) {
      return;
    }

    session.fontScale = Number(fontScale) || 100;
    if (session.rendition?.themes) {
      session.rendition.themes.fontSize(`${session.fontScale}%`);
    }
  }

  async function next(sessionId) {
    const session = sessions.get(sessionId);
    if (!session?.rendition) {
      return;
    }

    try {
      await queueOperation(session, async () => {
        if (session.rendition) {
          await session.rendition.next();
        }
      });
    } catch (error) {
      emitError(session, error);
      throw error;
    }
  }

  async function prev(sessionId) {
    const session = sessions.get(sessionId);
    if (!session?.rendition) {
      return;
    }

    try {
      await queueOperation(session, async () => {
        if (session.rendition) {
          await session.rendition.prev();
        }
      });
    } catch (error) {
      emitError(session, error);
      throw error;
    }
  }

  async function goToHref(sessionId, href) {
    const session = sessions.get(sessionId);
    if (!session?.rendition || !href) {
      return;
    }

    try {
      await queueOperation(session, async () => {
        if (session.rendition) {
          await session.rendition.display(href);
        }
      });
    } catch (error) {
      emitError(session, error);
      throw error;
    }
  }

  function getNavigation(sessionId) {
    const session = sessions.get(sessionId);
    return session ? session.navigation.slice() : [];
  }

  async function dispose(sessionId) {
    const session = sessions.get(sessionId);
    if (!session) {
      return;
    }

    try {
      session.disposed = true;
      await cleanupSession(session);
    } finally {
      sessions.delete(sessionId);
    }
  }

  window.easyEpubPreview = {
    isAvailable() {
      return availabilityError() == null;
    },
    availabilityError,
    create,
    setFlow,
    setFontScale,
    next,
    prev,
    goToHref,
    getNavigation,
    dispose,
  };
})();
