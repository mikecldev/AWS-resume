# Cloud Resume - Terraform Infrastructure as Code

Complete Terraform configuration to deploy the entire Cloud Resume Challenge infrastructure on AWS.

## 🏗️ Infrastructure Components

This Terraform configuration deploys:

- **S3 Bucket** - Static website hosting with versioning and encryption
- **CloudFront** - Global CDN with HTTPS
- **API Gateway** - REST API endpoint for visitor counter
- **Lambda Function** - Python business logic with reCAPTCHA verification
- **DynamoDB Table** - NoSQL database for visitor data
- **Route 53** (Optional) - DNS management for custom domain
- **IAM Roles & Policies** - Least-privilege security
- **CloudWatch** - Logging and monitoring

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **reCAPTCHA v3 keys** from Google
5. **(Optional)** Custom domain and ACM certificate

### Install Terraform

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

### Configure AWS Credentials

```bash
aws configure
# Enter AWS Access Key ID
# Enter AWS Secret Access Key
# Default region: eu-west-2
# Default output format: json
```

## 🚀 Quick Start

### 1. Clone and Navigate

```bash
cd cloud-resume/terraform
```

### 2. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and fill in your values:

```hcl
aws_region           = "eu-west-2"
environment          = "prod"
project_name         = "cloud-resume"
recaptcha_secret_key = "YOUR_RECAPTCHA_SECRET_KEY"  # REQUIRED

# Optional: Custom domain
enable_custom_domain = false
domain_name          = ""
acm_certificate_arn  = ""
```

### 3. Initialize Terraform

```bash
terraform init
```

This downloads required providers and initializes the backend.

### 4. Review the Plan

```bash
terraform plan
```

Review the resources that will be created.

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` to confirm. Deployment takes ~5-10 minutes.

### 6. Save Outputs

```bash
terraform output > outputs.txt
```

Important outputs:
- `website_url` - Your CloudFront URL
- `api_gateway_url` - API endpoint
- `s3_bucket_name` - For uploading frontend files
- `cloudfront_distribution_id` - For cache invalidation

## 📁 Project Structure

```
terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars.example # Example variables file
├── terraform.tfvars        # Your actual variables (gitignored)
├── README.md               # This file
│
└── modules/
    ├── s3/                 # S3 static website module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── cloudfront/         # CloudFront CDN module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── dynamodb/           # DynamoDB table module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── lambda/             # Lambda function module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── api_gateway/        # API Gateway module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── route53/            # Route 53 DNS module (optional)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🔧 Configuration Options

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `recaptcha_secret_key` | Google reCAPTCHA v3 secret key | `6LcXXXXXXXX...` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `eu-west-2` | AWS region |
| `environment` | `prod` | Environment name |
| `enable_custom_domain` | `false` | Use custom domain |
| `lambda_memory_size` | `256` | Lambda memory in MB |
| `lambda_timeout` | `30` | Lambda timeout in seconds |
| `log_retention_days` | `7` | CloudWatch log retention |

See [variables.tf](variables.tf) for all options.

## 📝 Post-Deployment Steps

After `terraform apply` completes:

### 1. Update Frontend Configuration

Update `resume_front_end/app.js` with your API Gateway URL:

```javascript
const API_BASE_URL = 'https://YOUR_API_ID.execute-api.eu-west-2.amazonaws.com/prod';
```

Get the URL from:
```bash
terraform output api_gateway_url
```

### 2. Upload Frontend Files

```bash
# Get bucket name
BUCKET_NAME=$(terraform output -raw s3_bucket_name)

# Upload files
cd ../resume_front_end
aws s3 sync . s3://$BUCKET_NAME/ --exclude ".DS_Store"
```

### 3. Invalidate CloudFront Cache

```bash
# Get distribution ID
DIST_ID=$(terraform output -raw cloudfront_distribution_id)

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"
```

### 4. Access Your Website

```bash
terraform output website_url
```

Open the URL in your browser!

## 🔄 Updating Infrastructure

### Update Lambda Function

```bash
# After editing lambda_function.py
terraform apply
```

Terraform detects code changes and updates the Lambda function.

### Update Other Resources

```bash
# Edit variables in terraform.tfvars
terraform plan   # Review changes
terraform apply  # Apply changes
```

## 🗑️ Destroying Infrastructure

To remove all resources:

```bash
# Empty S3 bucket first
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
aws s3 rm s3://$BUCKET_NAME --recursive

# Destroy infrastructure
terraform destroy
```

Type `yes` to confirm.

## 🔐 Security Best Practices

### 1. Protect terraform.tfvars

```bash
# Add to .gitignore
echo "terraform.tfvars" >> .gitignore
echo "*.tfstate*" >> .gitignore
echo ".terraform/" >> .gitignore
```

### 2. Use Remote State (Recommended)

Create S3 bucket and DynamoDB table for state:

```bash
# Create state bucket
aws s3 mb s3://your-terraform-state-bucket

# Create lock table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Update `main.tf` backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "cloud-resume/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 3. Use AWS Secrets Manager (Advanced)

Store reCAPTCHA secret in AWS Secrets Manager instead of tfvars:

```bash
aws secretsmanager create-secret \
  --name cloud-resume/recaptcha-secret \
  --secret-string "YOUR_SECRET_KEY"
```

## 💰 Cost Estimation

Estimated monthly costs (with moderate traffic):

| Resource | Cost |
|----------|------|
| S3 | ~$0.03 |
| CloudFront | ~$1-5 |
| API Gateway | ~$0.35 |
| Lambda | ~$0 (Free Tier) |
| DynamoDB | ~$0.25 |
| Route 53 (optional) | ~$0.50 |
| **Total** | **~$2-6/month** |

*Free Tier: First 12 months includes 1M Lambda requests and 25GB DynamoDB storage*

## 📊 Monitoring

### View Lambda Logs

```bash
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
aws logs tail /aws/lambda/$FUNCTION_NAME --follow
```

### Check DynamoDB Item Count

```bash
TABLE_NAME=$(terraform output -raw dynamodb_table_name)
aws dynamodb scan --table-name $TABLE_NAME --select COUNT
```

### CloudFront Metrics

```bash
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront get-distribution-config --id $DIST_ID
```

## 🐛 Troubleshooting

### Issue: "Error acquiring state lock"

**Solution:** Another Terraform process is running or crashed. Wait or force unlock:
```bash
terraform force-unlock LOCK_ID
```

### Issue: "InvalidParameterException: Cannot update function code"

**Solution:** Lambda is being updated. Wait 30 seconds and retry:
```bash
sleep 30
terraform apply
```

### Issue: CloudFront distribution stuck "In Progress"

**Solution:** CloudFront deployments take 10-30 minutes. Check status:
```bash
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.Status'
```

### Issue: "403 Forbidden" when accessing website

**Solution:** Check CloudFront OAI permissions or S3 bucket policy:
```bash
terraform apply -replace=module.cloudfront.aws_cloudfront_origin_access_identity.oai
```

## 🚀 Advanced: Custom Domain Setup

### 1. Request ACM Certificate (in us-east-1)

```bash
aws acm request-certificate \
  --domain-name example.com \
  --subject-alternative-names www.example.com \
  --validation-method DNS \
  --region us-east-1
```

### 2. Validate Certificate

Follow DNS validation instructions in AWS Console.

### 3. Update terraform.tfvars

```hcl
enable_custom_domain = true
domain_name          = "example.com"
acm_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/..."
```

### 4. Apply Changes

```bash
terraform apply
```

### 5. Update Domain Name Servers

Point your domain to Route 53 name servers:

```bash
terraform output route53_name_servers
```

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Architecture Diagram](../ARCHITECTURE.md)
- [reCAPTCHA Setup Guide](../RECAPTCHA_SETUP.md)

## 🎯 Next Steps

1. ✅ Deploy infrastructure with Terraform
2. ✅ Upload frontend files to S3
3. ✅ Test visitor counter functionality
4. ✅ Set up GitHub Actions for CI/CD
5. ✅ Configure custom domain (optional)
6. ✅ Monitor costs in AWS Cost Explorer
7. ✅ Review CloudWatch logs and metrics

---

**Questions?** Check [ARCHITECTURE.md](../ARCHITECTURE.md) for the complete system diagram!
