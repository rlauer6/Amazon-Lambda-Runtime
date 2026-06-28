# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
  * [The Execution Lifecycle](#the-execution-lifecycle)
  * [Error Handling](#error-handling)
  * [Design Philosophy](#design-philosophy)
  * [Event Framework](#event-framework)
  * [Streaming Responses](#streaming-responses)
  * [AWS X-Ray](#aws-x-ray)
  * [Deploying](#deploying)
* [METHODS](#methods)
  * [new](#new)
  * [handler](#handler)
  * [register\_event\_handler](#register\event\handler)
  * [get\_logger](#get\logger)
  * [run](#run)
  * [send\_invocation\_error](#send\invocation\error)
  * [send\_init\_error](#send\init\error)
  * [next\_event](#next\event)
  * [send\_invocation\_response](#send\invocation\response)
  * [send\_streaming\_response](#send\streaming\response)
* [NOTES](#notes)
  * [Logging](#logging)
  * [AWS Reference Implementation](#aws-reference-implementation)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

Amazon::Lambda::Runtime - Perl runtime for AWS Lambda container images

# SYNOPSIS

    package MyLambda;

    use strict;
    use warnings;

    use parent qw(Amazon::Lambda::Runtime);
    use JSON qw(encode_json);

    sub handler {
      my ($self, $event, $context) = @_;
      return encode_json({ message => 'Hello!', input => $event });
    }

    1;

# DESCRIPTION

`Amazon::Lambda::Runtime` provides a clean, transparent implementation
of the AWS Lambda Custom Runtime API for Perl. Unlike runtimes that rely
on pre-built layers or specific Amazon Linux versions, this distribution
is designed for a **container-first deployment model**. You can use any
Linux base image such as `debian:trixie-slim` and manage your
dependencies via a standard `cpanfile`.

## The Execution Lifecycle

The runtime is invoked by the `bootstrap` script, which calls the
`plambda.pl` driver. The driver performs the following steps:

1. **Initialization** - locates your handler module via the `LAMBDA_MODULE`
environment variable and instantiates it.
2. **The Event Loop** - calls `run()`, which enters a `while` loop to poll
the Lambda Runtime API for new events.
3. **Persistence** - because the `run()` loop persists within the same
process between warm invocations, initialize expensive resources (database
handles, AWS SDK objects) in your module's `new()` constructor or as
package-level lexical variables so they are reused across invocations.

## Error Handling

The runtime wraps your handler in an `eval` block.

- If your handler **dies**, the runtime catches the exception and
automatically reports `$EVAL_ERROR` to the Lambda service as a function
error.
- For more controlled error reporting without crashing the process, use
`send_invocation_error($message, $type)`.

## Design Philosophy

`Amazon::Lambda::Runtime` is a Perl Lambda runtime you build using
standard Perl tooling. Every component is visible, documented, and
replaceable. Install it into your container image from CPAN like any
other module. Use `carton` or `cpanm` to install your dependencies.
Customize the Dockerfile to build your image. Nothing is hidden behind a
pre-built base image or a layer ARN maintained by someone else.

If you are evaluating Perl Lambda runtime options you may find other
implementations on CPAN. This one prioritizes transparency, compatibility
with standard Perl idioms, and integration with existing Perl AWS
infrastructure over convenience wrappers or pre-built images. If you can
read a Perl class and a Dockerfile, you understand everything this
distribution does.

## Event Framework

`Amazon::Lambda::Runtime` ships a structured event dispatch framework
covering the four most common Lambda event sources: SQS, SNS, S3, and
EventBridge. The base `handler` method detects the event source and
dispatches to the appropriate handler class via a registry.

Register event handler classes in your Lambda module:

    package MyLambda;

    use parent qw(Amazon::Lambda::Runtime);
    use Amazon::Lambda::Runtime::Event qw(:all);

    __PACKAGE__->register_event_handler($EVENT_SQS => 'MyLambda::SQS');
    __PACKAGE__->register_event_handler($EVENT_S3  => 'MyLambda::S3');

    1;

    package MyLambda::SQS;

    use parent qw(Amazon::Lambda::Runtime::Event::SQS);

    sub on_message {
      my ($self, $body, $record) = @_;
      $self->get_logger->info("received: $body");
    }

    1;

There are three levels of customization - TIMTOWTDI:

1. Override `handler` entirely and ignore the event framework.
2. Register event handler classes via `register_event_handler`. The base
`handler` routes automatically.
3. Subclass an event object and override a single stub method. Pure business
logic - no routing code required.

Available event source constants (exported via `:all`):

    $EVENT_SQS         # aws:sqs
    $EVENT_SNS         # aws:sns
    $EVENT_S3          # aws:s3
    $EVENT_EVENTBRIDGE # aws:events

For sample event payloads for all supported event sources see:
[https://github.com/tschoffelen/lambda-sample-events](https://github.com/tschoffelen/lambda-sample-events)

## Streaming Responses

Handlers can stream responses progressively by returning a coderef
instead of a string. The runtime detects the coderef and switches to
chunked HTTP transfer encoding via [Amazon::Lambda::Runtime::Writer](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3AWriter):

    sub handler {
      my ($self, $event, $context) = @_;

      return sub {
        my ($writer) = @_;
        $writer->write('{"chunk":1,"message":"Hello"}');
        $writer->write('{"chunk":2,"message":"World"}');
        $writer->close;
      };
    }

Streaming requires a Lambda Function URL configured with
`InvokeMode=RESPONSE_STREAM` or API Gateway HTTP API with streaming
enabled. Direct CLI invocations, SQS, SNS, S3, and EventBridge triggers
do not support streaming.

See [Amazon::Lambda::Runtime::Writer](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3AWriter) for the full writer API.

## AWS X-Ray

For distributed tracing add `AWS::XRay` to your `cpanfile`:

    requires 'AWS::XRay';

`AWS::XRay` communicates with the X-Ray daemon via UDP on
`localhost:2000` - no additional HTTP dependencies are required.

    use AWS::XRay qw(capture);

    sub handler {
      my ($self, $event, $context) = @_;
      capture 'myApp' => sub {
        # your code here
      };
    }

See [AWS::XRay](https://metacpan.org/pod/AWS%3A%3AXRay) on CPAN for full usage details.

## Deploying

Building, deploying, and configuring a Perl Lambda container image is
handled by the companion [Amazon::Lambda::Runtime::Builder](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3ABuilder) distribution.
Run `alr-builder install` to scaffold a new project directory, then
`alr-builder check` to verify that your tools and IAM permissions are in
place before your first build. See [Amazon::Lambda::Runtime::Builder](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3ABuilder) for
the complete workflow, Makefile variable reference, and IAM permission
requirements.

# METHODS

## new

    new(%options)

Constructor for the runtime object. You can override this but **must**
call `SUPER::new`.

- loglevel

    Sets the [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) level: `fatal`, `error`, `warn`, `info`,
    `debug`, `trace`. Defaults to `info` or the value of the `LOG_LEVEL`
    environment variable.

- timeout

    HTTP timeout in seconds for communicating with the Runtime API. Default: 10.

## handler

    handler($event, $context)

The entry point for your business logic. By default uses the event
framework to detect the source and dispatch to a registered class. If no
handler is registered, falls back to the appropriate default event class.

Override this method to bypass the event framework and handle the raw
event hashref directly.

Return values:

- 1. `die` - Lambda reports a function error.
- 2. `undef` - assumes the handler sent its own response.
- 3. A string - sent as the invocation response.
- 4. A coderef - triggers a streaming response via
[Amazon::Lambda::Runtime::Writer](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3AWriter).

## register\_event\_handler

    register_event_handler($source, $class)

Registers a handler class for a specific AWS event source.

- $source

    Use the exported constants from `Amazon::Lambda::Runtime::Event qw(:all)`
    \- e.g. `$EVENT_SQS`, `$EVENT_S3`.

- $class

    A class inheriting from the corresponding
    `Amazon::Lambda::Runtime::Event::*` base class.

## get\_logger

Returns the [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) logger instance, initialized to `STDERR`
which Lambda captures and sends to CloudWatch Logs.

Prefer the coderef form to avoid unnecessary computation when the log
level would suppress the message anyway:

    $self->get_logger->debug(sub { Dumper($event) });

## run

    run()

The main event loop. Polls for events and invokes the handler for each.

## send\_invocation\_error

    send_invocation_error($message, $type)

Sends a structured error to the Lambda service. Preferred over throwing
an exception when you want graceful error reporting without aborting the
process.

## send\_init\_error

    send_init_error($message, $type)

Reports an initialization error. Call from your `new()` override if
initialization fails and the function should not proceed to the event loop.

## next\_event

    next_event()

Internal. Polls the Lambda Runtime API for the next event.

## send\_invocation\_response

    send_invocation_response($response)

Internal. Sends a response string to the Lambda service.

## send\_streaming\_response

    send_streaming_response($coderef)

Internal. Called automatically when `handler` returns a coderef. Streams
chunks via [Amazon::Lambda::Runtime::Writer](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3AWriter).

# NOTES

## Logging

Output to `STDERR` is captured in the CloudWatch log stream. Log levels
from least to most verbose: `fatal`, `error`, `warn`, `info`,
`debug`, `trace`. Default is `info`.

Set `LOG_LEVEL` in your Lambda configuration to change the level at
runtime without redeploying:

    aws lambda update-function-configuration \
        --function-name my-function \
        --environment "Variables={LOG_LEVEL=debug}"

## AWS Reference Implementation

For reference, the equivalent AWS shell script custom runtime:

    #!/bin/sh
    set -euo pipefail
    source $LAMBDA_TASK_ROOT/"$(echo $_HANDLER | cut -d. -f1).sh"
    while true
    do
      HEADERS="$(mktemp)"
      EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET \
        "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
      REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" \
        | tr -d '[:space:]' | cut -d: -f2)
      RESPONSE=$($(echo "$_HANDLER" | cut -d. -f2) "$EVENT_DATA")
      curl -X POST \
        "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response" \
        -d "$RESPONSE"
    done

# SEE ALSO

[Amazon::Lambda::Runtime::Builder](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3ABuilder) - project scaffolding, build workflow,
and IAM permission checker

[Amazon::Lambda::Runtime::Writer](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3AWriter) - streaming response writer

[Amazon::Lambda::Runtime::Event](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3AEvent) - event dispatch framework

[Amazon::Lambda::Runtime::Context](https://metacpan.org/pod/Amazon%3A%3ALambda%3A%3ARuntime%3A%3AContext) - Lambda context object

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

# LICENSE

(c) Copyright 2019-2026 Robert C. Lauer. All rights reserved. This
module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
