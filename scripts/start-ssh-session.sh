#!/bin/bash
BASTION_DETAILS=$(aws ec2 describe-instances --filters Name=tag:Name,Values=linux-host --query 'Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone}| [0] | [0]' --output json)
INSTANCEID=$(echo "$BASTION_DETAILS" | jq '.Instance' -r)
AZ=$(echo "$BASTION_DETAILS" | jq '.AZ' -r)
PUBLIC_KEY_PATH=~/.ssh/id_rsa.pub

aws ec2-instance-connect \
		send-ssh-public-key \
			--instance-id "$INSTANCEID" \
			--instance-os-user ssm-user \
			--ssh-public-key file://$PUBLIC_KEY_PATH \
			--availability-zone "$AZ"

# -o "LocalForward $(LOCAL_DB_TUNNEL_PORT) $(DB_HOST):$(DB_PORT)" \
ssh \
	-o "User ssm-user" \
	-o "ProxyCommand aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p" \
	-o "IdentityFile ~/.ssh/id_rsa" \
	"$INSTANCEID"