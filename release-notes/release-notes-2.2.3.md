# Release Notes — Amazon-Lambda-Runtime 2.2.3

**Released:** 2026-10-01

---

## Overview

This release focuses on build-system modernisation (via
`CPAN::Maker::Bootstrapper`), documentation improvements, a
correctness fix in the event-loop response handling, and a tidy-up of
declared dependencies.

---

## What's New

### Runtime

#### `Amazon::Lambda::Runtime`

- **`$EVENT_ALB` added to `@EXPORT_OK`** — the ALB event-source
  constant is now exported when callers request `:all` or name it
  explicitly, bringing it into line with the other four event-source
  constants.
- **`run()` — falsy-response fix** — the check `elsif ($response)` has
  been corrected to `elsif (defined $response)`. Previously a handler
  returning `0` or an empty string would silently suppress the
  invocation response; it is now sent correctly.

#### `Amazon::Lambda::Runtime::Event`

- `$EVENT_ALB` added to `@EXPORT_OK` (alphabetical order maintained
  alongside the existing constants).
- New POD section **`get_headers`** documents the `get_headers($name)`
  accessor on event objects.
- **Supported Event Sources** section promoted to a top-level POD
  heading and expanded to include the `aws:alb` entry.

#### `Amazon::Lambda::Runtime::Context`

- POD revised to document both AWS-style camelCase and snake_case
  getter variants explicitly (e.g. `get_awsRequestId` /
  `get_aws_request_id`), replacing the previous informal note.
- Synopsis corrected: `{ headers => }` → `{ headers => {...} }`.

#### `bin/plambda.pl`

- POD synopsis updated: now shows `LAMBDA_MODULE=My::Lambda
  plambda.pl` instead of a positional argument.
- Description rewritten to accurately describe the driver's role:
  loading the class named by `LAMBDA_MODULE`, setting `_HANDLER`, and
  entering the event loop.

---

## Documentation

- **`README.md`** regenerated from updated POD:
  - Execution lifecycle section rewritten to match the current
    `plambda.pl` behaviour.
  - Event framework description updated to include **ALB** as a
    supported event source.
  - SEE ALSO section expanded with direct links to all five event
    handler classes:
    - `Amazon::Lambda::Runtime::Event::ALB`
    - `Amazon::Lambda::Runtime::Event::EventBridge`
    - `Amazon::Lambda::Runtime::Event::S3`
    - `Amazon::Lambda::Runtime::Event::SNS`
    - `Amazon::Lambda::Runtime::Event::SQS`
  - Added a paragraph noting that `Amazon::Lambda::Runtime` is also
    the foundation used by `Amazon::Lambda::Runtime::Builder`.

---

## Dependencies

### `requires` / `cpanfile`

- **Removed `Log::Log4perl::Level`** — this package is bundled within
  `Log::Log4perl` itself; listing it separately was redundant.
- **Removed `Test::More`** from runtime dependencies — it is a core
  module and belongs only in test dependencies (where it has also been
  dropped from `test-requires` for the same reason).

### Updated `cpanfile`

```
requires "Class::Accessor::Fast", "0.51";
requires "Date::Format",          "2.24";
requires "HTTP::Tiny",            "0.088";
requires "JSON",                  "4.10";
requires "JSON::PP",              "4.16";
requires "Log::Log4perl",         "1.57";
requires "Readonly",              "2.05";
requires "URI::Escape",           "5.34";
```

---

## Build System

The following build-infrastructure files were updated by `CPAN::Maker::Bootstrapper`:

| File | Change |
|---|---|
| `.includes/bootstrap.mk` | Added (new managed file) |
| `.includes/publish.mk` | Added (new managed file) |
| `.includes/local.mk` | Dependency tracking via `local/.installed` sentinel; separate `cpanfile.runtime` and `test-requires.cpanfile` installs; `cpm` now installs test deps separately |
| `.includes/perl.mk` | Progress output (`echo -n "Checking SYNTAX/POD/TIDINESS/PERLCRITIC..."`) added to all lint gates; `LOCAL_PREREQ` updated to track `local/.installed` |
| `.includes/update.mk` | `MANAGED_MK_FILES` / `MANAGED_FILES` split; `MANIFEST` target added; `post-update` loop updated |
| `Makefile` | `PACKAGE_VERSION` exported; `cpanfile.runtime` target added; `DARKPAN_REQUIRES` support added; `find-files` macro extended to accept a fourth glob; `TESTS` now also matches `*.p[ml]`; `extra-files` / `extra-files.mk` split into separate targets with `git ls-files` verification; `PERL5LIB` injected into `cpan-maker` invocation; `provides` and `test-requires` dependency graph refined |
| `project.mk` | New `install` target: `cpanm -n -v -l $(HOME) <tarball>` |
| `.gitignore` | Extended with `**/*.bak`, `**/*.log`, `**/*.pod`, `**/*.tmp`, `**/.\#*`, `**/\#*`, `cpanfile.*`, `test-requires.cpanfile`, `test-requires.scan`; `cpanfile.darkpan` explicitly un-ignored |

---

## Upgrading

No API changes. Callers that import event-source constants should add
`$EVENT_ALB` to their import list if they handle ALB events directly
(it was already exported by `Amazon::Lambda::Runtime::Event`; it is
now also exported by `Amazon::Lambda::Runtime` itself).
