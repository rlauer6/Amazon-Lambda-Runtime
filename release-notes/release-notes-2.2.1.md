# Release Notes — Amazon::Lambda::Runtime v2.2.1

**Released:** 2026-07-01

---

## Bug Fixes

### `Amazon::Lambda::Runtime::Event::ALB` — Force `statusCode` to be numeric

The `_alb_response` method now coerces `statusCode` to a numeric value
(`$status + 0`) before including it in the ALB response
payload. Previously, `statusCode` could be serialised as a JSON string
rather than an integer, which could cause ALB to reject or mishandle
the Lambda response.

```perl
# Before
statusCode => $status,

# After
statusCode => $status + 0,
```

---

## Build / Infrastructure

### `project.mk` — Add `Amazon::Lambda::Runtime` to the Docker `cpanfile`

When building the `alr-base` Lambda runtime Docker image,
`Amazon::Lambda::Runtime` is now explicitly appended to the `cpanfile`
copied into the Docker build context. This ensures the module itself
is installed in the base image via cpm during the Docker build
step.

The `docker build` invocation also now respects the `$(NOCACHE)`
variable, allowing cache-busting builds when required.

---

## Repository / Housekeeping

- **`.gitignore`** — Added `**/*.crit` and `**/*.tdy` to exclude
  Perl::Critic and Perl::Tidy output files from version control.

---

## Upgrade Notes

This is a patch release. No API changes have been made. Upgrading from
v2.2.0 is safe and recommended for anyone using ALB event handling, as
the `statusCode` type fix may resolve integration issues with strict
ALB response validation.
