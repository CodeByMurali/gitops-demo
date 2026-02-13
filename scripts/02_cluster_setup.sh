#!/bin/bash

# Prompt the user for a number of spoke clusters to create
echo -n "How many spoke clusters are you creating: "
read number

echo -n "What name do you want to call your hub cluster: "
read hub_name

echo -n "In which region are you creating this cluster? [eg: us-east-1]: "
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

echo -n "Node type for clusters [default: t3.medium]: "
read node_type
node_type=${node_type:-t3.medium}

echo -n "Number of nodes per cluster [default: 1]: "
read node_count
node_count=${node_count:-1}

# Validate if input for number of cluster is a positive integer
if ! [[ "$number" =~ ^[0-9]+$ ]]; then
    echo "Please enter a valid positive number."
    exit 1
fi

if ! [[ "$node_count" =~ ^[0-9]+$ ]]; then
    echo "Please enter a valid positive number for node count."
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
echo "You are about to create the following:"
echo "  - $number spoke clusters"
echo "  - Hub cluster: $hub_name"
echo "  - AWS region: $region"
if [[ -n "$profile" ]]; then
    echo "  - AWS profile: $profile"
else
    echo "  - AWS authentication: SSO/Current session"
fi
echo "  - Node type: $node_type"
echo "  - Nodes per cluster: $node_count"
echo
read -p "Do you want to proceed? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Operation canceled."
    exit 0
fi

# Build eksctl command based on authentication method
if [[ -n "$profile" ]]; then
    EKSCTL_PROFILE_FLAG="--profile $profile"
else
    EKSCTL_PROFILE_FLAG=""
fi

# Create the hub cluster
echo "Creating hub cluster: $hub_name"
if eksctl create cluster --name "$hub_name" --region "$region" $EKSCTL_PROFILE_FLAG \
    --nodes "$node_count" --node-type "$node_type" --managed; then
    echo "Hub cluster $hub_name created successfully."
else
    echo "Failed to create hub cluster $hub_name."
    exit 1
fi

# Create the spoke clusters
for ((i = 1; i <= number; i++)); do
    cluster_name="spoke$i"
    echo "Creating spoke cluster: $cluster_name"
    if eksctl create cluster --name "$cluster_name" --region "$region" $EKSCTL_PROFILE_FLAG \
        --nodes "$node_count" --node-type "$node_type" --managed; then
        echo "Spoke cluster $cluster_name created successfully."
    else
        echo "Failed to create spoke cluster $cluster_name. Exiting."
        exit 1
    fi
done

echo ""
echo "All clusters created successfully!"
echo ""
echo "Next steps:"
echo "1. Switch to hub cluster context: kubectl config use-context <hub-cluster-context>"
echo "2. Run the ArgoCD installation script: ./scripts/03_argocd_installtion.sh"

