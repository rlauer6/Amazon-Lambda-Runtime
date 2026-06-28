# Amazon::Lambda::Runtime 2.1.5 Release Notes

## Summary

Build system migration to `CPAN::Maker::Bootstrapper`, with minor
correctness fixes in `Event::ALB` and metadata cleanup in
`buildspec.yml`. No API changes.

---

## Changes

### Build system

The project `Makefile` has been rewritten using `CPAN::Maker::Bootstrapper`
managed includes. The following `.includes/` files are now bootstrapper-managed:

- `git.mk` - `git` target for initializing a repository with recommended artifacts
- `help.mk` - `help` target listing all documented targets
- `perl.mk` - pattern rules for `.pm.in` → `.pm` and `.pl.in` → `.pl`
  generation, `perltidy` and `perlcritic` sentinel rules, `tidy`,
  `critic`, and `lint` targets
- `release-notes.mk` - `release-notes` target generating `.diffs`,
  `.lst`, and `.tar.gz` artifacts for release note generation
- `update.mk` - `update` and `post-update` targets for syncing managed
  files from the installed bootstrapper
- `upgrade.mk` - `check-upgrade` and `upgrade` targets for upgrading
  the bootstrapper via MetaCPAN
- `version.mk` - `release`, `minor`, `major` targets for semantic
  version bumping

New `Makefile` features include automatic dependency scanning via
`scandeps-static.pl`, `cpanfile` generation from `requires` and
`test-requires`, `build-ci` target for Docker-based CI builds, and
`workflow` target for installing the GitHub Actions build pipeline.

### `cpanfile`

Generated from `requires` and `test-requires`. Added as a new file.

### `t/00-amazon-lambda-runtime.t`

New smoke test - `use_ok('Amazon::Lambda::Runtime')`.

### `lib/Amazon/Lambda/Runtime/Event/ALB.pm.in`

- `use CLI::Simple::Constants` removed - constants (`$TRUE`, `$FALSE`,
  `$EMPTY`) are now declared locally with `Readonly`
- `on_request` stub response now includes a `message` field alongside
  `error` for consistency with the 500 response format
- `_alb_response` 500 error body uses `_status_description(500)` for
  the `error` field rather than a hardcoded string
- Minor style fixes: `sprintf` for error logging, `q{/}` for path
  default, blank line after `next if`

### `requires`

- `CLI::Simple` removed - no longer a runtime dependency

### `buildspec.yml`

- Repository URLs updated from `Amazon-Lambda-Runtime2` to
  `Amazon-Lambda-Runtime`
- `mailto` updated to `rclauer@gmail.com`
- `---` YAML document marker added
