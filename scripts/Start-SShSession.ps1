aws sso login --profile ssm-test

$BASTION_DETAILS = $(aws ec2 describe-instances --filters Name=tag:Name,Values=linux-host --query 'Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone}| [0] | [0]' --output json --profile ssm-test) | ConvertFrom-JSON
$PUBLIC_KEY_PATH = "$((gi env:\USERPROFILE).Value)\.ssh\id_rsa.pub"

aws ec2-instance-connect `
		send-ssh-public-key `
			--instance-id "$($BASTION_DETAILS.Instance)" `
			--instance-os-user ssm-user `
			--ssh-public-key file://$PUBLIC_KEY_PATH `
			--availability-zone "$($BASTION_DETAILS.AZ)" `
            --profile ssm-test

