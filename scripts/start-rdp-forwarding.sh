#!/bin/bash
INSTANCEID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=windows-host" --output text --query 'Reservations[].Instances[].InstanceId | [0]')
aws ssm start-session \
    --target "$INSTANCEID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["3389"], "localPortNumber":["55555"]}'
