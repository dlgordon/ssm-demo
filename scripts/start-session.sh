#!/bin/bash
INSTANCEID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=linux-host" --output text --query 'Reservations[].Instances[].InstanceId | [0]')
aws ssm start-session --target $INSTANCEID