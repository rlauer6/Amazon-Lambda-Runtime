# Release Notes — Amazon-Lambda-Runtime v2.2.2

**Released:** Fri Aug 21 2026  
**Maintainer:** Rob Lauer \<rclauer@gmail.com\>

---

## Overview

Version 2.2.2 is a maintenance and infrastructure release. It delivers
two new API methods in the Lambda event layer, hardens ALB error-body
serialisation, and syncs the entire build toolchain with the latest
`CPAN::Maker::Bootstrapper` conventions (renamed CLI tool, grouped
dependency scanning, POD checking, version-drift detection, and more).

---

## New Features

### `Amazon::Lambda::Runtime::Event::ALB`

- **`_error_body()`** — new internal helper that converts any response
  body (plain scalar, hash ref, blessed exception object) into a
  well-formed JSON string before it is sent to the ALB.
  - Uses a single, consistently configured `JSON::PP` encoder (`utf8`,
    `canonical`, `allow_blessed`, `convert_blessed`) so the result is
    stable and byte-for-byte deterministic.
  - Handles blessed objects that lack a `TO_JSON` hook by extracting
    the exception message instead of encoding to `null`.
  - Wraps the encode in `eval` and falls back to a plain `{
    errorMessage => … }` shape so the error path itself can never
    throw.
- **`_exception_message()`** — new internal helper used by
  `_error_body()` to extract a human-readable string from any kind of
  exception value:
  - Tries string-overloading first.
  - Falls back through common accessor names (`get_message_raw`,
    `get_message`, `message`, `error`, `as_string`).
  - Falls back to the ref-address string as a last resort — always
    safe, never throws.
- **`_alb_response()`** — updated to delegate body encoding to
  `_error_body()` instead of an inline `ref $body ?
  encode_json($body) : $body` expression.
- Added `use Scalar::Util qw(blessed)` import.

### `Amazon::Lambda::Runtime::Event::Base`

- **`get_headers($header?)`** — new public method.
  - Called with no arguments: returns the entire `headers` hash ref
    from the event.
  - Called with a header name: returns the value of that specific
    header (looked up case-insensitively via `lc`).
  - Returns `undef` immediately when the event carries no `headers` key.

---

## Build System Changes

The `Makefile` and all managed `.includes/` fragments were regenerated
and updated to align with the current `CPAN::Maker::Bootstrapper`
release. Key changes include:

### Command rename

- The bootstrapper CLI is now **`cmb`** (previously
  `bootstrapper`). All `Makefile` targets and `.includes/` fragments
  have been updated accordingly.
- `scandeps-static` replaces `scandeps-static.pl`; `markdown-render`
  replaces `md-utils.pl`.

### Dependency scanning — three-tier model

- A **single grouped scan** (`requires.raw recommends.raw suggests.raw
  &:`) now produces all three library dependency tiers in one
  `scandeps-static` invocation, replacing the previous single-tier
  per-target approach.
- Separate targets for **`recommends`** (soft, non-eval conditional
  dependencies) and **`suggests`** (eval-wrapped, optional
  dependencies) are now first-class build targets with corresponding
  `.raw` intermediates and `cpanfile` sections.
- `cpanfile` is now assembled from three intermediate files
  (`cpanfile.requires`, `cpanfile.recommends`, `cpanfile.suggests`)
  via `cpan-maker create-cpanfile --dependency-type`.
- Dependency filtering uses `cmb filter` in place of the previous inline Perl `filter_requires` here-doc.

### `deps.mk` — chicken-and-egg fix

- `deps.mk` now depends on **`.pm.in` / `.pl.in` source files** rather
  than the built `.pm` / `.pl` targets, eliminating the cycle where
  `make clean` could force a build-then-delete pass before dependency
  information was available.

### Syntax checking — combined rules and POD checking

- The separate `%.pm.checked` / `%.pl.checked` sentinel phase is
  replaced by **combined build + syntax-check pattern rules** (`%.pm:
  %.pm.in`, `%.pl: %.pl.in`).
- **`podchecker`** is now run automatically as part of syntax checking
  for every `.pm` and `.pl` target.
- `PERL5LIB=` is cleared when invoking `perl -wc` to avoid pollution
  from the host environment; `local/lib/perl5` is added to
  `PERLINCLUDE` instead.
- New `PODCHECKER`, `CPM`, and `CARTON` variables are detected via
  `command -v`.
- New `PERLCRITIC_SEVERITY` (default: `5`) and `PERLCRITIC_THEME`
  (default: `pbp`) variables are exposed and wired through all
  `perlcritic` invocations.
- `check-syntax` is retained as a `.PHONY` convenience alias that
  builds all modules and scripts.

### Version-bump targets now depend on `clean`

- `release`, `minor`, and `major` targets now run `clean` first to
  ensure a pristine rebuild after a version bump.

### Version-drift detection

- `update-available` now also checks whether the **local `.includes/`
  files match the installed `CPAN::Maker::Bootstrapper`** using
  `md5sum` against a distributed `cmb_md5sums.txt`.
- Drift behaviour is controlled by the new `CMB_VERSION_DRIFT`
  variable (`fail` / `warn` / `ignore`; default: `fail`).
- CPAN update checking is controlled by `CMB_UPDATE_CHECK` (default: `on`).

### New managed files

- `.includes/bash-completion.mk` — shell completion support.
- `.includes/modulino.mk` — modulino wrapper support (extracted from `Makefile`).
- `.includes/local.mk` — local library (`local/`) installation support.
- `deps.mk` — inter-module dependency graph, now generated from source files.

### Template variable system

- Variable substitution is now handled by `cmb resolve-vars` with a
  `TEMPLATE_VARS` list (`PACKAGE_VERSION`, `MODULE_NAME`, `GIT_SHA`,
  `GIT_DIRTY`, `GIT_EMAIL`, `GIT_USER`, `GIT_NAME`,
  `MIN_PERL_VERSION`, `PROJECT_NAME`), replacing the previous `sed -e
  's/@FOO@/…/'` approach.
- `GIT_SHA` and `GIT_DIRTY` are now computed at make time and
  available as template variables.

### `git` / `repo` targets

- `git`: suppresses noisy output, respects a `NO_COMMIT=1` variable to
  stage without committing.
- `repo`: new target to create a GitHub repository via `gha-aws`
  (`make repo REPO=name [PUBLIC=1] [REPO_DESCRIPTION="…"]`).

### `help` target

- Output is now written to a temp file and paged through `$PAGER`
  (falling back to `less`, `more`, or `cat`).
- Added `SYNTAX_CHECKING=OFF` and `SKIP_TESTS=1` to the documented
  variables list; removed the now-obsolete `MODULINO_NAME` entry.

### `update` / `post-update` targets

- `post-update` now merges missing entries from the bootstrapper's
  reference `.gitignore` into the project's `.gitignore` using `comm`.
- `update` now applies `post-update` before overwriting `Makefile` (order corrected).

### Other `Makefile` improvements

- `find-files` macro filters out editor backup files (`#*`, `.#*`,
  `*~`, `*.bak`) and sorts results for reproducibility.
- `build-ci` mounts the working directory into the Docker container
  and passes `REPO` from `git remote get-url`.
- `INSTALLER` renamed to `DOCKER_CPAN_INSTALLER` to avoid collision
  with the general `CPAN_INSTALLER` variable.
- `extra-files.mk` is generated from `buildspec.yml` and included to
  wire extra distribution files into the tarball dependency graph.
- New `package` target: runs `clean` then a full `LINT=on SCAN=on` build.
- `SKIP_TESTS=1` environment variable is respected by the tarball target (`cpan-maker --skip-tests`).
- `NO_COLOR` variable suppresses `--color` output from `cpan-maker`.
- `config.mk` is included (silently, with a no-op rule) to allow project-local overrides.

### `.gitignore` additions

```
**/*.checked
**/*.raw
**/*.sh
*-review-2*.annotate
*-review-2*.code
*-review-2*.pod
buildspec.yml.current
buildspec.yml.tmpl
module.pm.tmpl
test.t.tmpl
extra-files.mk
local/**
```

### `cpanfile`

- Entries are now sorted alphabetically; `Test::More` moved to its
  correct sorted position (previously listed first out of order).

---

## Dependency Changes

No new runtime dependencies. `Scalar::Util` (core) is now explicitly imported in `ALB.pm`.

---

## Upgrade Notes

1. Run `make update` to pull the latest managed `.includes/` files
   from the installed `CPAN::Maker::Bootstrapper`.
2. The bootstrapper CLI has been renamed from `bootstrapper` to
   **`cmb`**. Ensure the new binary is on your `$PATH` (it is
   installed alongside `CPAN::Maker::Bootstrapper`).
3. Projects that reference `bootstrapper` in custom scripts or CI
   pipelines should update those references to `cmb`.
4. The `INSTALLER` Makefile variable has been renamed to
   `DOCKER_CPAN_INSTALLER` to avoid ambiguity. Update any local
   `config.mk` overrides.
5. `CMB_VERSION_DRIFT=fail` (the new default) will cause `make` to
   error if local `.includes/` files differ from the installed
   bootstrapper. Set `CMB_VERSION_DRIFT=warn` or
   `CMB_VERSION_DRIFT=ignore` in `config.mk` to relax this check
   during a staged migration.
