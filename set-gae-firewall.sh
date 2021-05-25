#!/bin/bash

declare -a rule_ip_ranges=()
declare -a rule_descriptions=()

# Check if the current user has access to the specified project
checkProjectAccess() {
  if [ -z "$PROJECT_ID" ];
  then
    echo "A project ID is required."
    exit 1
  fi
  if [ $(gcloud projects list --filter="id=$PROJECT_ID" | grep -oc $1 $PROJECT_ID) -eq 0 ];
  then
    echo "User does not have access to ${PROJECT_ID}. Log in using the command: gcloud auth login"
    exit 1
  fi
}

# Create a firewall rule.
# ARGS:
#   $1 - priority
#   $2 - action
#   $3 - project id
#   $4 - source-range
#   $5 - description
createFirewallRule() {
  gcloud app firewall-rules create $1 --action=$2 --project=$3 --source-range=$4 --description=$5
}

# Delete a firewall rule.
# ARGS:
#   $1 - priority
#   $2 - project id
deleteFirewallRule() {
  gcloud app firewall-rules delete $1 --project=$2
}

# Create/delete a firewall rule depending on default rule action.
# ARGS:
#   $1 - default rule action
#   $2 - index
#   $3 - project id
#   $4 - item
#   $5 - description
executeEnableDisable() {
  case $1 in
    allow)
      # Delete the firewall rule
      yes | deleteFirewallRule $2 $3
      ;;
    deny)
      # Create the firewall rule
      createFirewallRule $2 "allow" $3 $4 $5
      ;;
  esac
}

# Modify rules based on default rule action.
# ARGS:
#   $1 - default rule action
#   $2 - action description
#   $3 - project id
modifyRules() {
  echo "Modifying Firewall rules in ${3}"

  # Set the default firewall rule
  echo "Set default rule to ${1} all IPs..."
  gcloud app firewall-rules update 2147483647 --action=$1 --project=$3

  echo "$2 $((${#rule_ip_ranges[@]})) rules..."

  # Iterate through IPs
  for i in "${!rule_ip_ranges[@]}"
  do
    echo "$2 rule $(($i + 1)) for ${rule_ip_ranges[$i]}..."
    executeEnableDisable $1 $(($i + 1)) $3 ${rule_ip_ranges[$i]} ${rule_descriptions[$i]}
  done

  echo "Finished updating $((${#rule_ip_ranges[@]})) rules in ${3}"
}


# -- MAIN -- #

# Parse input arguments
# @see https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f

while (( "$#" )); do
  case "$1" in

    -a|--action)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        ACTION=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;

    -f|--file)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        INPUT_FILE=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;

    --project)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PROJECT_ID=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;

    -*|--*=) # Unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;

    *) # Skip positional arguments (not used by this script)
      shift
      ;;

  esac
done

# Ensure action is set
case $ACTION in
  enable)
    DEFAULT_ACTION=deny
    HELP_TEXT=Enabling
    ;;
  disable)
    DEFAULT_ACTION=allow
    HELP_TEXT=Disabling
    ;;
  *)
    echo "Invalid argument for --action, expected one of [enable, disable]"
    ;;
esac

if [ -z $DEFAULT_ACTION ];
then
  echo "The --enable or --disable flag is required"
  exit 1
fi

# Ensure file is set
if [ -z $INPUT_FILE ];
then
  echo "An input file must be specified using --file <file_name>"
  exit 1
fi

# Ensure file exists
if [ ! -f $INPUT_FILE ]; then
  echo "$INPUT_FILE does not exist"
  exit 1
fi


# Check project access
checkProjectAccess

# Read input file
while IFS= read -r line; do
  # Split each row by comma
  IFS=','
  read -a row <<< "$line"

  # Extract IP range and description per rule
  if [[ ${row[0]} != \#* ]] && [ ! -z ${row[0]} ]; then
    rule_ip_ranges+=(${row[0]})
    rule_descriptions+=(${row[1]})
  fi
done < $INPUT_FILE

# Modify rules
modifyRules $DEFAULT_ACTION $HELP_TEXT $PROJECT_ID
