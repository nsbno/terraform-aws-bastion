#!/bin/bash

set -euo pipefail

profile=$AWS_PROFILE
name=${1:-""}
localPort=${2:-""}
remotePort=${3:-""}

# Validate AWS_PROFILE is set
if [ -z "$profile" ]; then
  echo "Error: 'AWS_PROFILE' must be set as an environment variable."
  exit 1
fi

if [ -z "$name" ]; then
  echo "Error: 'name' is required."
  exit 1
fi

echo "Connecting to AWS Environment: $AWS_PROFILE..."
echo "3.."
sleep 0.5
echo "2.."
sleep 0.5
echo "1.."
sleep 0.5


# Define endpoints
declare -A db_endpoints=( # The suffix of all databases in a region are the same
  ["vy-ctrl-prod"]="********.eu-west-1.rds.amazonaws.com"

  ["vy-comp-prod"]=""]="********..eu-west-1.rds.amazonaws.com"
)

declare -A redis_endpoints=( # The suffix of all databases in a region are the same
  ["profile-name"]="****.0001.euw1.cache.amazonaws.com"
)

# Define configuration
# Format is config["your-preferred-shorthand"]="db-name":type:bastion-instance-name"]
# Supported types are "cluster" (Aurora-clusters), "rds" or "redis".
declare -A config
config["ats"]="affected-trains:cluster:bastion"
config["opinfo"]="operationalinformation:rds:bastion"

echo "Current Profile: $profile"

if [[ -z "${config[$name]:-}" ]]; then
  echo "Error: Invalid name '${name}'. It is not defined in the configuration."
  exit 1
fi

# Parse configuration
IFS=":" read -r dbName dbType bastionName <<<"${config[$name]}"
if [ -z "$dbName" ]; then
  echo "Error: Invalid name provided."
  exit 1
fi

if [ "$dbType" == "cluster" ]; then
  clusterPrefix="cluster-"
  connectionUrl="$dbName.${clusterPrefix}${db_endpoints[$profile]}"
  remotePort=${remotePort:-"5432"}
  localPort=${localPort:-"5432"}
elif [ "$dbType" == "rds" ]; then
  connectionUrl="$dbName.${db_endpoints[$profile]}"
  remotePort=${remotePort:-"5432"}
  localPort=${localPort:-"5432"}
elif [ "$dbType" == "redis" ]; then
  connectionUrl="$dbName.${redis_endpoints[$profile]}"
  remotePort=${remotePort:-"6379"}
  localPort=${localPort:-"6379"}
else
  echo "Error: Invalid type '${dbType}'. It is not defined in the configuration."
  exit 1
fi

function get_bastion_details() {
  local bastionName=$1

  local output
  output=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${bastionName}" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone}" \
    --output json)

  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve EC2 instance information."
    exit 1
  fi

  echo "$output"
}

function tunnel_with_shared_vpc() {
  echo "Using the shared VPC bastion"
  echo "Connecting to ${connectionUrl} on remotePort ${remotePort} and localPort ${localPort}"
  aws ssm start-session \
    --target "$instance" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"${connectionUrl}\"],\"portNumber\":[\"${remotePort}\"],\"localPortNumber\":[\"${localPort}\"]}"
}

function tunnel_with_old_vpc() {
  echo "Connecting using Traffic Control VPC"
  aws ec2-instance-connect send-ssh-public-key \
    --ssh-public-key file://~/.ssh/id_ed25519.pub \
    --instance-id "$instance" \
    --instance-os-user ec2-user \
    --availability-zone "$az" > /dev/null

  echo "Opening tunnel on ${localPort}:${connectionUrl}:${remotePort}"
  ssh -N -L "${localPort}:${connectionUrl}:${remotePort}" "ec2-user@${instance}"
}

bastionDetails=$(get_bastion_details "$bastionName")

instance=$(echo "$bastionDetails" | jq -r '.[0][0].Instance')
az=$(echo "$bastionDetails" | jq -r '.[0][0].AZ')

if [ "$bastionName" == "bastion" ]; then
  tunnel_with_shared_vpc
elif [ "$bastionName" == "bastionhost" ]; then
  tunnel_with_old_vpc
else
  echo "Error: Invalid bastion provided. Allowed values are 'bastion' or 'bastionhost'."
  exit 1
fi
