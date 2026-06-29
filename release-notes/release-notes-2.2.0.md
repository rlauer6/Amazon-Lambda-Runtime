# Amazon::Lambda::Runtime 2.2.0 Release Notes

## Summary

Adds a maintainer-only `alr-base` target that builds and pushes
`perl-lambda-base` — a minimal Debian Trixie Lambda runtime base image
containing the Perl runtime and all `Amazon::Lambda::Runtime`
dependencies. This image serves as the foundation for the three-layer
Lambda image architecture introduced in
`Amazon::Lambda::Runtime::Builder` 1.3.0.

---

## Changes

### `docker/Dockerfile` (new)

Multi-stage Debian Trixie image that builds `perl-lambda-base`:

- **Builder stage** — installs build tools, `cpm`, and all runtime
  dependencies from `cpanfile` into `/usr/src/app/local` using a
  Docker layer cache at `/cache/local-debian`
- **Runtime stage** — copies only the installed modules,
  `bootstrap`, and `plambda.pl` into a clean `debian:trixie-slim`
  image; no build tools, no source
- `RESOLVER` and `EXTRA_BUILD_PACKAGES` / `EXTRA_RUNTIME_PACKAGES`
  args are supported for DarkPAN and system package customization
- No `DIST_TARBALL` or `HANDLER_CLASS` — handler distributions are
  layered on top by `ALRB`'s stock `Dockerfile` via `PLATFORM_IMAGE`

The resulting image is tagged `perl-lambda-base:$(PERL_VERSION)-debian-$(DEBIAN_RELEASE)`
and `perl-lambda-base:latest`.

### `project.mk` (new)

Maintainer-only `make` targets included via `-include project.mk`:

**`$(PERL_VERSION_FILE)`** — detects the Perl version shipped by
`debian:$(DEBIAN_RELEASE)` by running a one-shot container. The result
is cached in `.debian-$(DEBIAN_RELEASE)-perl-version` and only
regenerated when `docker/Dockerfile` changes. Changing `DEBIAN_RELEASE`
(e.g. from `trixie` to `bookworm`) automatically produces a new
version file and image tag.

**`alr-base`** — builds `perl-lambda-base:$(ALR_BASE_TAG)` from
`docker/Dockerfile` using the project `cpanfile`, creates the ECR
repository if it does not exist, and pushes both the versioned tag and
`latest`. Requires `alr-helper` (`Amazon::Lambda::Runtime::Builder`)
to be installed; fails with a clear error if not found.

### `.gitignore`

`*.*perl-version` added to exclude the generated Perl version cache
files from version control.
