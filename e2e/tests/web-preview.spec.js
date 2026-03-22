const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { test, expect } = require('@playwright/test');

const repoRoot = path.resolve(__dirname, '../..');

function referenceEpubPath() {
  const tempDir = path.join(repoRoot, 'e2e', '.tmp');
  const outputPath = path.join(tempDir, 'reference-style.epub');
  if (fs.existsSync(outputPath)) {
    return outputPath;
  }

  fs.mkdirSync(tempDir, { recursive: true });
  execFileSync(
    'python3',
    [
      '-c',
      `
import sys
import zipfile
from pathlib import Path

output = Path(sys.argv[1])
output.parent.mkdir(parents=True, exist_ok=True)

with zipfile.ZipFile(output, 'w') as archive:
    archive.writestr('mimetype', 'application/epub+zip', compress_type=zipfile.ZIP_STORED)
    archive.writestr('META-INF/container.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''')
    archive.writestr('OPS/content.opf', '''<?xml version="1.0" encoding="utf-8"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>레퍼런스 EPUB</dc:title>
    <dc:creator>스타일 저자</dc:creator>
  </metadata>
  <manifest>
    <item id="style" href="Styles/reference.css" media-type="text/css"/>
    <item id="toc" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="font-main" href="Fonts/serif.ttf" media-type="font/ttf"/>
  </manifest>
</package>''')
    archive.writestr('OPS/Styles/reference.css', '''
@font-face {
  font-family: "Imported Serif";
  src: url("../Fonts/serif.ttf");
}
h1.chapter-title { letter-spacing: 0.08em; }
h2.section-title { margin-top: 2em; }
p.body-copy { text-indent: 1em; }
body { color: #171c22; font-family: "Imported Serif"; }
''')
    archive.writestr('OPS/toc.ncx', '''<?xml version="1.0" encoding="utf-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="nav-1" playOrder="1">
      <navLabel><text>1장</text></navLabel>
      <content src="Text/chapter01.xhtml"/>
      <navPoint id="nav-2" playOrder="2">
        <navLabel><text>소절</text></navLabel>
        <content src="Text/chapter01.xhtml#section-1"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''')
    archive.writestr('OPS/Fonts/serif.ttf', b'font')
      `,
      outputPath,
    ],
    {
      cwd: repoRoot,
    },
  );
  return outputPath;
}

async function enableFlutterSemantics(page) {
  await page.waitForFunction(
    () => Boolean(document.querySelector('flt-semantics-placeholder')),
    { timeout: 15000 },
  );
  await page
      .locator('flt-semantics-placeholder')
      .first()
      .evaluate((element) => element.click());
}

async function collectRuntimeIssues(page) {
  const issues = [];
  page.on('pageerror', (error) => {
    issues.push(`pageerror: ${error.message}`);
  });
  page.on('console', (message) => {
    if (message.type() !== 'error') {
      return;
    }
    const text = message.text();
    if (
      /easyEpubPreview|EPUB render failed|TypeError|Cannot read/i.test(text)
    ) {
      issues.push(`console: ${text}`);
    }
  });
  return issues;
}

async function openCreateScreen(page) {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await enableFlutterSemantics(page);
  await page.waitForFunction(
    () => document.querySelectorAll('flt-semantics').length > 0,
  );
  await expect(page.getByText('새 전자책').first()).toBeVisible();
  await page.getByText('새 전자책').first().click();
  await expect(page.getByText('EPUB 스타일 가져오기').last()).toBeVisible();
}

async function fillDraft(page, title) {
  await page.locator('input[aria-label="제목"]').fill(title);
  await page
      .locator('textarea[aria-label*="본문"]')
      .fill('# 1장 시작\n\n본문 단락입니다.\n\n## 소절 A\n\n세부 설명입니다.');
}

async function importStyleReference(page) {
  const chooserPromise = page.waitForEvent('filechooser');
  await page.getByText('EPUB 스타일 가져오기').last().click();
  const chooser = await chooserPromise;
  await chooser.setFiles(referenceEpubPath());
  await expect(page.getByRole('button', { name: '레퍼런스 해제' })).toBeVisible();
}

async function waitForPreviewReady(page) {
  await page.waitForFunction(() => {
    const host = document.querySelector('[data-location]');
    if (!host) {
      return false;
    }
    if (host.getAttribute('data-error')) {
      return false;
    }
    try {
      const location = JSON.parse(host.getAttribute('data-location') || '{}');
      const items = JSON.parse(host.getAttribute('data-navigation') || '[]');
      return (
        Array.isArray(items) &&
        items.some((item) => `${item.label}`.includes('1장')) &&
        typeof location.href === 'string' &&
        location.href.length > 0
      );
    } catch (_) {
      return false;
    }
  });
}

test.describe('web epub preview', () => {
  test('create screen live preview renders exported epub bytes', async ({ page }) => {
    const issues = await collectRuntimeIssues(page);

    await openCreateScreen(page);
    await fillDraft(page, '웹 미리보기 스모크');
    await importStyleReference(page);
    await waitForPreviewReady(page);

    await page.getByText('페이지형').click();
    await page.waitForFunction(() => {
      const host = document.querySelector('[data-location]');
      return Boolean(host && !host.getAttribute('data-error'));
    });

    await page.getByText('스크롤형').click();
    await waitForPreviewReady(page);

    const navigation = await page.evaluate(() => {
      const host = document.querySelector('[data-navigation]');
      return host ? host.getAttribute('data-navigation') : null;
    });
    expect(navigation).toContain('1장 시작');
    expect(issues).toEqual([]);
  });

  test('saved-book preview reuses the same renderer path', async ({ page }) => {
    const issues = await collectRuntimeIssues(page);

    await openCreateScreen(page);
    await fillDraft(page, '저장본 EPUB 미리보기');
    await importStyleReference(page);

    await page.getByRole('button', { name: '임시 저장' }).last().click();
    await expect(page.getByText(/초안을 저장했습니다/)).toBeVisible();
    await page.getByRole('button', { name: '닫기' }).click();

    await page.getByRole('button', { name: '미리보기' }).first().click();

    await page.waitForFunction(() => {
      const host = document.querySelector('[data-location]');
      return Boolean(host && host.getAttribute('data-location'));
    });

    await page.getByText('페이지형').click();
    await page.waitForFunction(() => {
      const host = document.querySelector('[data-location]');
      return Boolean(host && !host.getAttribute('data-error'));
    });

    expect(issues).toEqual([]);
  });
});
