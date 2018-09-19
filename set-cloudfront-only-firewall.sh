#!/bin/bash

# Cloudfront IP addresses retrieved from here:
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/LocationsOfEdgeServers.html

declare -a global_ips=(
"52.124.128.0/17"
"54.230.0.0/16"
"54.239.128.0/18"
"99.84.0.0/16"
"205.251.192.0/19"
"54.239.192.0/19"
"70.132.0.0/18"
"13.32.0.0/15"
"13.35.0.0/16"
"204.246.172.0/23"
"204.246.164.0/22"
"204.246.168.0/22"
"71.152.0.0/17"
"216.137.32.0/19"
"205.251.249.0/24"
"99.86.0.0/16"
"52.46.0.0/18"
"52.84.0.0/15"
"64.252.64.0/18"
"204.246.174.0/23"
"205.251.254.0/24"
"143.204.0.0/16"
"205.251.252.0/23"
"204.246.176.0/20"
"13.249.0.0/16"
"54.240.128.0/18"
"205.251.250.0/23"
"52.222.128.0/17"
"54.182.0.0/16"
"54.192.0.0/16"
)

declare -a regional_edge_ips=(
"13.124.199.0/24"
"34.226.14.0/24"
"52.15.127.128/26"
"35.158.136.0/24"
"52.57.254.0/24"
"18.216.170.128/25"
"13.54.63.128/26"
"13.59.250.0/26"
"13.210.67.128/26"
"35.167.191.128/26"
"52.47.139.0/24"
"52.199.127.192/26"
"52.212.248.0/26"
"52.66.194.128/26"
"13.113.203.0/24"
"34.195.252.0/24"
"35.162.63.192/26"
"52.56.127.0/25"
"13.228.69.0/24"
"34.216.51.0/25"
"54.233.255.128/26"
"52.52.191.128/26"
"52.78.247.128/26"
"52.220.191.0/26"
"34.232.163.208/29"
)

# Create a firewall rule.
# ARGS:
#   $1 - priority
#   $2 - action
#   $3 - source-range
#   $4 - description
createFirewallRule() {
  gcloud app firewall-rules create $1 --action=$2 --source-range=$3 --description=$4
}

# Delete a firewall rule.
# ARGS:
#   $1 - priority
deleteFirewallRule() {
  gcloud app firewall-rules delete $1
}

# Create/delete a firewall rule depending on default rule action.
# ARGS:
#   $1 - default rule action
#   $2 - index
#   $3 - item
#   $4 - description
executeEnableDisable() {
  case $1 in
    allow)
      # Delete the firewall rule
      yes | deleteFirewallRule $2
      ;;
    deny)
      # Create the firewall rule
      createFirewallRule $2 "allow" $3 $4
      ;;
  esac
}

# Modify rules based on default rule action.
# ARGS:
#   $1 - default rule action
#   $2 - Action description
#   $3 - action description
modifyRules() {
  # Set the default firewall rule
  echo "Set default rule to ${1} all IPs..."
  gcloud app firewall-rules update 2147483647 --action=$1

  echo "$1 $((${#regional_edge_ips[@]} + ${#global_ips[@]})) rules..."

  # Iterate through global IPs
  for i in "${!global_ips[@]}"
  do
    echo "$2 rule $(($i + 1)) for ${global_ips[$i]}..."
    executeEnableDisable $1 $(($i + 1)) ${global_ips[$i]} "CLOUDFRONT_GLOBAL_IP"
  done

  # Iterate through regional edge IPs
  for i in "${!regional_edge_ips[@]}"
  do
    echo "$2 rule $(($i + ${#global_ips[@]} + 1)) for ${regional_edge_ips[$i]}..."
    executeEnableDisable $1 $(($i + ${#global_ips[@]} + 1)) ${regional_edge_ips[$i]} "CLOUDFRONT_REGIONAL_EDGE_IP"
  done

  echo "Finished $3 $((${#regional_edge_ips[@]} + ${#global_ips[@]})) rules."
}

# Parse input arguments
if [ $# -eq 1 ]
then
  case $1 in
    -enable)
      modifyRules "deny" "Enabling" "enabling"
      ;;

    -disable)
      modifyRules "allow" "Disabling" "disabling"
      ;;
    *)
      echo "Invalid argument ${1}, expected one of [-enable, -disable]"
      ;;
  esac

else
  echo "Expected 1 argument [-enable, -disable]"
fi
