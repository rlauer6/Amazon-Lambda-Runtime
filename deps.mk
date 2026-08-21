# ./lib/Amazon/Lambda/Runtime.pm.in
./lib/Amazon/Lambda/Runtime.pm: \
    ./lib/Amazon/Lambda/Runtime/Context.pm \
    ./lib/Amazon/Lambda/Runtime/Event.pm \
    ./lib/Amazon/Lambda/Runtime/Writer.pm

# ./lib/Amazon/Lambda/Runtime/Event.pm.in
./lib/Amazon/Lambda/Runtime/Event.pm: \
    ./lib/Amazon/Lambda/Runtime/Event/ALB.pm \
    ./lib/Amazon/Lambda/Runtime/Event/Base.pm \
    ./lib/Amazon/Lambda/Runtime/Event/EventBridge.pm \
    ./lib/Amazon/Lambda/Runtime/Event/S3.pm \
    ./lib/Amazon/Lambda/Runtime/Event/SNS.pm \
    ./lib/Amazon/Lambda/Runtime/Event/SQS.pm

# ./lib/Amazon/Lambda/Runtime/Event/ALB.pm.in
./lib/Amazon/Lambda/Runtime/Event/ALB.pm: \
    ./lib/Amazon/Lambda/Runtime/Event/Base.pm

# ./lib/Amazon/Lambda/Runtime/Event/EventBridge.pm.in
./lib/Amazon/Lambda/Runtime/Event/EventBridge.pm: \
    ./lib/Amazon/Lambda/Runtime/Event/Base.pm

# ./lib/Amazon/Lambda/Runtime/Event/S3.pm.in
./lib/Amazon/Lambda/Runtime/Event/S3.pm: \
    ./lib/Amazon/Lambda/Runtime/Event/Base.pm

# ./lib/Amazon/Lambda/Runtime/Event/SNS.pm.in
./lib/Amazon/Lambda/Runtime/Event/SNS.pm: \
    ./lib/Amazon/Lambda/Runtime/Event/Base.pm

# ./lib/Amazon/Lambda/Runtime/Event/SQS.pm.in
./lib/Amazon/Lambda/Runtime/Event/SQS.pm: \
    ./lib/Amazon/Lambda/Runtime/Event/Base.pm

