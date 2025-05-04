### First Configure with AWS Credentials to use Terraform and AWS CLI
--- STEPS: 

1. Create the S3 Bucket for State Storage
First, you need to create an S3 bucket to store your Terraform state files:
```bash
aws s3api create-bucket \
  --bucket my-terraform-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
```
Enable versioning on the bucket:
```bash
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```
Enable server-side encryption:
```bash
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```
2. Create the DynamoDB Table for State Locking
Next, create a DynamoDB table for state locking:
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

or run the bash script: ./setup-remote-state.sh

If You Already Have Local State Files
If you've already been using Terraform with a local state file, use:
terraform init -migrate-state

This will:
Initialize your configuration
Detect the new S3 backend
Prompt you to confirm migrating your existing local state to the S3 bucket
Copy your local state file to the S3 bucket and configure Terraform to use it

If This is a New Project (No Existing State)
If you haven't applied any Terraform configurations yet and don't have local state, use:
terraform init
This will initialize Terraform to use your S3 backend for future operations without attempting to migrate any state.

