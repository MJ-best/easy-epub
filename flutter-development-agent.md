# Flutter Development Agents

## Purpose
This document provides a unified coding and architecture guideline for Flutter team development. It is based on Flutter’s official recommendations, proven industry examples like Very Good Ventures, and community best practices.

### ✨ Core Principles
This guideline is built upon the following core principles:
*   **Maintainability:** Code should be easy to understand and modify in the long term.
*   **Scalability:** The architecture should be flexible for adding new features and scaling the application.
*   **Performance:** The application should deliver an optimized user experience.
*   **Readability:** All team members should be able to quickly and easily comprehend the codebase.
*   **Team Collaboration:** Consistent standards aim for efficient collaboration within the team.

## Architecture Principles

### Layered (MVVM-Inspired) Structure
- **Mandatory:** Separate app logic into UI and Data layers, with each layer split by responsibility (Views, ViewModels, Repositories, Services).
- **Directory Structure Example:**
  ```
  lib/
  ├── data/          # External data sources (APIs, databases)
  ├── domain/        # Business logic, entities, repositories
  ├── presentation/  # UI, widgets, viewmodels
  └── core/          # Utilities, constants, theme
  ```

#### MVVM Pattern Applied
- **View:** Stateless widget layer — pure rendering
- **ViewModel:** Handles UI logic, state, transforms data
- **Repository (and Services):** Abstracts data logic, acts as the source of truth

### Repository Pattern
- **Mandatory:** Encapsulate data access in repositories interfacing with APIs/databases.

## Code Style & Standards

### Effective Dart and Official Style Guide

- **Key Points:**
  - Code should optimize for readability.
  - All public APIs are documented.
  - Error messages must suggest actionable solutions.
  - Avoid non-deterministic behavior and global state.

### Naming Conventions
- Class: `UpperCamelCase`
- Functions/variables: `lowerCamelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private: `_underscorePrefix`
- Files: `snake_case.dart`

### Linting
- **Mandatory:** Always use the `flutter_lints` package in `analysis_options.yaml`:
  ```yaml
  include: package:flutter_lints/flutter.yaml

  linter:
    rules:
      prefer_final_locals: true
      sort_constructors_first: true
  ```

<h2>State Management</h2>

<h3>Choosing an Approach</h3>
<ul>
<li><strong>Widget-local state:</strong> Use <code>StatefulWidget</code> for simple, contained state.</li>
<li><strong>Screen-level state:</strong> <strong>Recommended:</strong> Use <code>ChangeNotifier</code> with <code>Provider</code>.</li>
<li><strong>App-wide state:</strong> <strong>Recommended:</strong> Use advanced solutions like <code>Provider</code>, <code>Riverpod</code>, or <code>Bloc</code> for global app state.</li>
</ul>

<h2>Data Principles</h2>

<h3>One-way Data Flow</h3>
<ul>
<li><strong>Mandatory:</strong> Ensure data flows from source to UI, not vice-versa.</li>
</ul>

<h3>Immutable Data Models</h3>
<ul>
<li><strong>Recommended:</strong> Use immutable objects to prevent unintended state changes.</li>
</ul>

<h3>Code Generation (Optional)</h3>
<ul>
<li><strong>(Optional):</strong> Use utilities like <code>freezed</code> or <code>built_value</code> for boilerplate reduction.</li>
</ul>

<h2>Dependency Injection</h2>
<ul>
<li><strong>Recommended:</strong> Use the <code>provider</code> package (or alternatives such as <code>get_it</code>) for DI, avoiding direct global access.</li>
</ul>

<h2>Testing Strategy</h2>

<h3>Pyramid Approach</h3>
<ul>
<li><strong>Unit tests:</strong> Validate business logic and models.</li>
<li><strong>Widget tests:</strong> Check UI rendering and interactions.</li>
<li><strong>Integration tests:</strong> Exercise end-to-end scenarios.</li>
</ul>
<ul>
<li><strong>Mandatory:</strong> Mock all dependencies for unit and widget testing.</li>
</ul>

<h2>Navigation Management</h2>
<ul>
<li><strong>Recommended:</strong> Prefer declarative routing solutions such as <code>go_router</code> or <code>auto_route</code>.</li>
</ul>

<h2>Performance Optimization</h2>

<ul>
<li>Utilize <code>const</code> constructors where possible.</li>
<li>Limit rebuild areas using e.g., <code>RepaintBoundary</code>.</li>
<li>Use lazy loading widgets (e.g., <code>ListView.builder</code>).</li>
<li>Dispose of <code>ChangeNotifier</code>, streams, controllers, and timers appropriately.</li>
<li>Use Dart and Flutter performance tools regularly.</li>
</ul>

<h2>Internationalization (i18n)</h2>
<ul>
<li><strong>Mandatory:</strong> Configure with <code>flutter_localizations</code> and <code>intl</code> from project start.</li>
<li>Structure message files with ARB, manage locales in <code>l10n.yaml</code>.</li>
</ul>

<h2>Accessibility</h2>
<ul>
<li><strong>Mandatory:</strong> Always provide semantic labels for interactive widgets.</li>
<li><strong>Mandatory:</strong> Ensure large enough touch targets (min. 44x44).</li>
<li><strong>Mandatory:</strong> Follow color contrast requirements.</li>
</ul>

<h2>Commit Message Conventions</h2>

<h3>Conventional Commits</h3>
<ul>
<li><strong>Mandatory:</strong> Adhere to the Conventional Commits specification.</li>
</ul>
<pre><code>&lt;type&gt;[optional scope]: &lt;description&gt;

[optional body]

[optional footer(s)]
</code></pre>
<p><strong>Types include:</strong> <code>feat</code>, <code>fix</code>, <code>docs</code>, <code>style</code>, <code>refactor</code>, <code>test</code>, <code>chore</code>.</p>

<h2>Branching Strategy (Example)</h2>
<ul>
<li><strong>Recommended / Reference:</strong> Follow a strategy similar to Git Flow or GitHub Flow, and refer to the following example.</li>
<li><code>main</code>: Release branch</li>
<li><code>develop</code>: Integration branch</li>
<li><code>feature/*</code>: Feature branches</li>
<li><code>hotfix/*</code>, <code>release/*</code>: For production fixes or releases</li>
</ul>

<h2>CI/CD Pipelines</h2>
<ul>
<li><strong>Mandatory:</strong> Run analyzer and linter on build.</li>
<li><strong>Mandatory:</strong> Require all tests to pass before merging.</li>
<li><strong>Mandatory:</strong> Regularly update dependencies (using <code>flutter pub outdated</code> and <code>upgrade</code>).</li>
</ul>

<h2>Documentation Standards</h2>
<ul>
<li><strong>Mandatory:</strong> Use triple-slash comments (<code>///</code>) for all public APIs.</li>
<li>Document usage, parameters, errors, and sample code.</li>
</ul>

<h2>Security Considerations</h2>
<ul>
<li><strong>Mandatory:</strong> Never hardcode API keys directly in the code.</li>
<li><strong>Mandatory:</strong> Omit sensitive information from logs.</li>
</ul>

<h2>Migration Strategy</h2>
<ul>
<li><strong>For legacy projects:</strong> <strong>Recommended:</strong> Apply guidelines incrementally.</li>
<li><strong>For new projects:</strong> <strong>Recommended:</strong> Use a generator like Very Good CLI (<code>very_good create</code>) or set up directories and dependencies manually.</li>
</ul>

<h2>⚠️ Pragmatic Application</h2>
<p>These guidelines aim to enhance team productivity and code quality. However, there may be exceptional circumstances where a 100% adherence is not feasible. In such cases, <strong>Recommended:</strong> discuss within the team to make a reasonable decision, and if necessary, document the rationale behind that decision.</p>

<h2>📚 Additional Resources & FAQ</h2>
<ul>
<li><strong>Flutter Official Documentation:</strong> <a href="https://flutter.dev/docs">https://flutter.dev/docs</a></li>
<li><strong>Effective Dart:</strong> <a href="https://dart.dev/guides/language/effective-dart">https://dart.dev/guides/language/effective-dart</a></li>
<li><strong>Conventional Commits:</strong> <a href="https://www.conventionalcommits.org/">https://www.conventionalcommits.org/</a></li>
<li><strong>FAQ:</strong> (You can add frequently asked questions here.)
<ul>
<li>Q: What procedure should be followed when introducing a new package?</li>
<li>A: ...</li>
</ul>
</li>
</ul>