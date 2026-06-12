## Amazon::Lambda::Runtime 2.1.2 Release Notes

**Bug Fixes**
- **`plambda.pl`**: `LAMBDA_MODULE` is now correctly converted to a
  proper file path (handles both `::`-separated module names and bare
  names) before `require`, instead of passing the raw value
  directly. Also added a startup message printing the handler being
  invoked, and `_HANDLER` is now set with `local`.
- **`Runtime.pm`**: The resolved handler class is now explicitly
  `require`'d if not already loaded (`can('new')` check), fixing
  failures when the handler class hadn't been loaded yet.
- **SQS event handling**:
  - `process` now skips records where `_unwrap` returns no body,
    avoiding calls to `on_message` with undefined content.
  - `_unwrap` now detects and ignores S3 `s3:TestEvent` notifications
    (sent automatically when a bucket notification configuration is
    saved), logging and returning nothing instead of treating them as
    real object events.
