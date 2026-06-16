# Amazon::Lambda::Runtime 2.1.3 Release Notes

## Overview

2.1.3 is a small patch release fixing a missing `sprintf` in a log statement
in `Runtime.pm` and refactoring the `do` block in `handler` to an explicit
`if` block for clarity. Also includes the 2.1.2 changes which were released
in the same cycle.

---

## Changes in 2.1.3

### Runtime.pm — handler refactor and log fix

The `do` block used to resolve the default handler class has been replaced
with an explicit `if` block, making the fallback logic easier to follow. An
auto-loading step was added: if the resolved handler class has not yet been
loaded (checked via `can('new')`), it is `require`'d at dispatch time.

The startup log statement was missing a `sprintf` call, causing the literal
format string to be logged rather than the interpolated version. Fixed and
promoted from `debug` to `info` level so it appears in standard CloudWatch
output:

```
Perl Lambda Runtime: v2.1.3, perl: 5.40.1
```

### .gitignore cleanup

Removed individual sentinel file entries (the `.cache/` pattern now covers
them all). Added `*.diffs` and `*.lst` to ignore release artifact files.

### release-notes.mk — LAST_TAG override

`make release-notes` now checks for a `LAST_TAG` environment variable before
falling back to the most recent git tag. Useful when generating release notes
against a specific prior tag rather than the automatic latest:

```bash
make release-notes LAST_TAG=2.1.1
```

Diff generation switched to `--staged` to capture uncommitted staged changes
rather than comparing tag-to-tag.

---

## Changes in 2.1.2

### plambda.pl — LAMBDA_MODULE path resolution

`LAMBDA_MODULE` is now converted to a proper file path before `require`:
`::` separators are replaced with `/` and a `.pm` suffix is appended if
absent. Previously the raw value was passed to `require`, which failed for
module-style names like `OrePAN2::S3::Monitor`. `_HANDLER` is now set with
`local` to avoid leaking into child processes. A startup message is printed
to STDERR showing the handler being invoked.

### SQS event handling

`process` now skips records where `_unwrap` returns an undefined body,
preventing `on_message` from being called with undefined content.

`_unwrap` now detects and silently ignores `s3:TestEvent` notifications —
the synthetic test message AWS sends automatically when an S3 bucket
notification configuration is saved. These have no `Records` key and are
not real object events. They are logged at `info` level and discarded.
