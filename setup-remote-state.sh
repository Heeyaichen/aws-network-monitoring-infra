#!/bin/bash

# Script to set up Terraform Remote State Backend Infrastructure with S3 and DynamoDB
# This script creates an S3 bucket for state storage and a DynamoDB table for state locking

# Configuration variables
BUCKET_NAME="my-terraform-state-bucket-369369369"
TABLE_NAME="terraform-state-lock"
REGION="ap-south-1"

# Print colored output
function echo_green() {
  echo -e "\033[0;32m$1\033[0m"
}

function echo_red() {
  echo -e "\033[0;31m$1\033[0m"
}

# Error handling
function check_error() {
  if [ $? -ne 0 ]; then
    echo_red "Error: $1"
    exit 1
  else
    echo_green "Success: $1"
  fi
}

echo_green "Creating Terraform remote state infrastructure..."

# 1. Create S3 bucket
# Note: The bucket name must be globally unique across all AWS accounts and regions, so you may need to change the bucket name to something unique.
echo "Creating S3 bucket: $BUCKET_NAME"
# Check if the bucket already exists
if aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
  echo_green "Bucket already exists and is owned by you. Continuing..."
else
  # Bucket doesn't exist or isn't owned by you - try to create it
  CREATE_RESULT=$(aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION \
    --output json 2>&1)
  
  # Check if we got the specific "already owned by you" error
  if [[ "$CREATE_RESULT" == *"BucketAlreadyOwnedByYou"* ]]; then
    echo_green "Bucket already exists and is owned by you. Continuing..."
  elif [[ "$CREATE_RESULT" == *"BucketAlreadyExists"* ]]; then
    echo_red "Error: Bucket $BUCKET_NAME already exists and is taken by another AWS account. Please choose a different name."
    exit 1
  elif [ $? -ne 0 ]; then
    echo_red "Error creating bucket: $CREATE_RESULT"
    exit 1
  else
    echo_green "Success: Created S3 bucket"
  fi
fi

# 2. Enable versioning
echo "Enabling versioning on bucket: $BUCKET_NAME"
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled \
  --output json

check_error "Enable versioning"

# 3. Enable server-side encryption
echo "Enabling server-side encryption on bucket: $BUCKET_NAME"
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }' \
  --output json

check_error "Enable encryption"

# 4. Create DynamoDB table for locking
echo "Creating DynamoDB table: $TABLE_NAME"

# First check if the table already exists
TABLE_EXISTS=$(aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION --output json 2>&1 || echo "NotExists")

if [[ "$TABLE_EXISTS" == *"NotExists"* ]] || [[ "$TABLE_EXISTS" == *"ResourceNotFoundException"* ]]; then
  # Table doesn't exist, create it
  aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION \
    --output json
  
  check_error "Create DynamoDB table"
else
  echo_green "DynamoDB table already exists and is owned by you. Continuing..."
fi


echo_green "=========================================================="
echo_green "Terraform remote state infrastructure created successfully!"
echo_green "S3 Bucket: $BUCKET_NAME"
echo_green "DynamoDB Table: $TABLE_NAME"
echo_green "Region: $REGION"
echo_green "=========================================================="
echo_green "Add this to your Terraform configuration:"
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"$BUCKET_NAME\""
echo "    key            = \"terraform.tfstate\""
echo "    region         = \"$REGION\""
echo "    dynamodb_table = \"$TABLE_NAME\""
echo "    encrypt        = true"
echo "  }"
echo "}"