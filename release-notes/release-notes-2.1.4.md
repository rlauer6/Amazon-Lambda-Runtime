# Amazon::Lambda::Runtime 2.1.4 Release Notes

## Summary

Adds ALB (Application Load Balancer) as a supported Lambda trigger type
via a new `Amazon::Lambda::Runtime::Event::ALB` class and corresponding
updates to the event factory and dependency list.

---

## Changes

### `Amazon::Lambda::Runtime::Event::ALB` (new)

New event class for ALB-triggered Lambda functions. ALB events have no
`Records` array and are identified by the presence of
`requestContext.elb` in the event payload.

Key methods:

- `process` - parses the ALB event, extracts `httpMethod` and `path`,
  decodes the urlencoded request body, calls `on_request`, and returns
  a correctly structured ALB Lambda response. Exceptions from
  `on_request` are caught and returned as a 500 response.
- `on_request($method, $path, $params, $event)` - stub method to
  override in subclasses. `$params` is a hashref of urlencoded body
  parameters, with Base64 decoding applied when `isBase64Encoded` is
  set.
- `_alb_response($status, $body)` - builds a valid ALB Lambda response
  hashref. `$body` may be a hashref (JSON-encoded automatically) or a
  plain string. `isBase64Encoded` is always `JSON::PP::false`.

### `Amazon::Lambda::Runtime::Event.pm.in`

- `use Amazon::Lambda::Runtime::Event::ALB` added
- `$EVENT_ALB` constant (`'aws:alb'`) added and exported via
  `@EXPORT_OK` and `%EXPORT_TAGS`
- `%DEFAULTS` maps `$EVENT_ALB` to `Amazon::Lambda::Runtime::Event::ALB`
- `detect_source` - new detection clause: returns `'aws:alb'` when
  `$event->{requestContext}{elb}` is present

### `requires`

- `CLI::Simple 2.0.6` added
- `HTTP::Tiny 0.088` added
- `JSON::PP 4.16` added
- `Log::Log4perl::Level` added
- `URI::Escape 5.34` added
- Version pins added to existing deps (`Class::Accessor::Fast`,
  `Date::Format`, `JSON`, `Log::Log4perl`, `Readonly`)
