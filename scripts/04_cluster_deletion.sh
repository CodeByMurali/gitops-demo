#!/bin/bash

# Prompt the user for a number of spoke clusters created
echo -n "How many spoke clusters did you create: "
read number

echo -n "What name is your hub cluster: "
read hub_name

echo -n "In which region are your resources in? [eg: us-east-1]: "
read region

echo -n "Are you using AWS SSO? (yes/no) [default: no]: "
read use_sso
use_sso=${use_sso:-no}

if [[ "$use_sso" == "yes" ]]; then
    profile=""
    echo "Using current AWS SSO session credentials"
else
    echo -n "What is the name of the AWS profile [enter profile name]: "
    read profile
fi

# Validate if input for number of cluster is a positive integer
if ! [[ "$number" =~ ^[0-9]+$ ]]; then
    echo "Please enter a valid positive number."
    exit 1
fi

# Verify AWS credentials
echo ""
echo "Verifying AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS credentials not configured or expired."
    echo "Please run 'aws configure' or 'aws sso login' and try again."
    exit 1
fi

# Confirm the details before proceeding
echo
echo "=========================================="
echo "WARNING: DESTRUCTIVE OPERATION"
echo "=========================================="
echo "You are about to DELETE the following:"
echo "  - $number spoke clusters"
echo "  - Hub cluster: $hub_name"
echo "  - AWS region: $region"
if [[ -n "$profile" ]]; then
    echo "  - AWS profile: $profile"
else
    echo "  - AWS authentication: SSO/Current session"
fi
echo ""
echo "This action cannot be undone!"
echo ""

read -p "Type 'DELETE' to confirm deletion: " confirm
if [[ "$confirm" != "DELETE" ]]; then
    echo "Operation canceled."
    exit 0
fi

# Build eksctl command based on authentication method
if [[ -n "$profile" ]]; then
    EKSCTL_PROFILE_FLAG="--profile $profile"
else
    EKSCTL_PROFILE_FLAG=""
fi

echo ""
echo "Starting cluster deletion..."
echo ""

# Delete the spoke clusters first
for ((i = 1; i <= number; i++)); do
    cluster_name="spoke$i"
    echo "Deleting spoke cluster: $cluster_name"
    if eksctl delete cluster --name "$cluster_name" --region "$region" $EKSCTL_PROFILE_FLAG; then
        echo "Spoke cluster $cluster_name deleted successfully."
    else
        echo "Failed to delete spoke cluster $cluster_name."
        echo "Continuing with remaining clusters..."
    fi
    echo ""
done

# Delete the hub cluster last
echo "Deleting hub cluster: $hub_name"
if eksctl delete cluster --name "$hub_name" --region "$region" $EKSCTL_PROFILE_FLAG; then
    echo "Hub cluster $hub_name deleted successfully."
else
    echo "Failed to delete hub cluster $hub_name."
    exit 1
fi

echo ""
echo "=========================================="
echo "All clusters deleted successfully!"
echo "=========================================="

