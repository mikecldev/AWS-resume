# ☁️ Cloud Resume Challenge - AWS Edition (Extended)

A serverless cloud resume with visitor counter, geolocation tracking, and bot protection using AWS services and Infrastructure as Code.

![AWS](https://img.shields.io/badge/AWS-Cloud-orange)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)
![Python](https://img.shields.io/badge/Backend-Python-blue)
![reCAPTCHA](https://img.shields.io/badge/Security-reCAPTCHA%20v3-green)

## 🎯 Project Overview

This project implements the [Cloud Resume Challenge](https://cloudresumechallenge.dev/) with additional features:

- ✅ Static website hosted on **AWS S3**
- ✅ HTTPS distribution via **CloudFront CDN**
- ✅ Visitor counter API with **API Gateway + Lambda**
- ✅ Data storage in **DynamoDB**
- ✅ **IP geolocation** with interactive map
- ✅ **reCAPTCHA v3** bot protection
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Comprehensive unit tests** (37+ tests)
- ✅ DNS management with **Route 53** (optional)

## 🏗️ Architecture

```
User → Route 53 → CloudFront → S3 (Static Website)
                      ↓
                  API Gateway → Lambda (Python)
                                  ↓
                            DynamoDB

External APIs:
  - Google reCAPTCHA (bot protection)
  - ipinfo.io / ip-api.com (geolocation)
```

**Full Architecture Diagram:** 
![Cloud Resume Challenge - Complete Serverless Architecture](resume_front_end/images/CRC-diagram.png)


## 📁 Project Structure

```
cloud-resume/
├── resume_front_end/          # Frontend (HTML/CSS/JS)
│   ├── index.html             # Main page
│   ├── app.js                 # JavaScript logic
│   ├── style.css              # Styles
│   └── images/                # Assets
│
├── resume_back_end/           # Backend (Python Lambda)
│   ├── lambda_function.py     # Main Lambda code
│   ├── test_lambda_function.py   # Unit tests
│   ├── requirements-test.txt  # Test dependencies
│   
│
├── terraform/                 # Infrastructure as Code
│   ├── main.tf                # Main Terraform config
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── README.md              # Terraform guide
│   └── modules/               # Reusable modules
│       ├── s3/                # S3 bucket module
│       ├── cloudfront/        # CloudFront module
│       ├── lambda/            # Lambda module
│       ├── api_gateway/       # API Gateway module
│       ├── dynamodb/          # DynamoDB module
│       └── route53/           # Route 53 module
│
├── ARCHITECTURE.md            # Architecture diagram
├── DEPLOYMENT_GUIDE.md        # Step-by-step deployment
├── RECAPTCHA_SETUP.md         # reCAPTCHA setup guide
├── TEST_BOT_DETECTION.md      # Bot testing guide
└── README.md                  # This file
```

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd cloud-resume
```

### 2. Get reCAPTCHA Keys

1. Go to https://www.google.com/recaptcha/admin
2. Create reCAPTCHA v3 site
3. Save Site Key (public) and Secret Key (private)

### 3. Deploy Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your reCAPTCHA secret key
terraform init
terraform apply
```

### 4. Configure Frontend

```bash
# Get API Gateway URL
terraform output api_gateway_url

# Update resume_front_end/app.js (line 7)
const API_BASE_URL = '<your-api-gateway-url>';

# Update reCAPTCHA site key in:
# - resume_front_end/index.html (line 15)
# - resume_front_end/app.js (line 10)
```

### 5. Upload Frontend

```bash
cd ../resume_front_end
aws s3 sync . s3://$(cd ../terraform && terraform output -raw s3_bucket_name)/
```

### 6. Access Website

```bash
cd ../terraform
terraform output website_url
```

**Complete Guide:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## 🔬 Testing

### Run Unit Tests

```bash
cd resume_back_end
./run_tests.sh
```

### Test Bot Detection

```bash
# Get API URL
cd terraform
API_URL=$(terraform output -raw api_gateway_url)

# Test with fake token (should fail)
curl -X POST $API_URL/visit \
  -H "Content-Type: application/json" \
  -d '{"action":"visit","recaptchaToken":"fake_token"}'
```

**Testing Guide:** [TEST_BOT_DETECTION.md](TEST_BOT_DETECTION.md)

## 🛡️ Security Features

### reCAPTCHA v3 Bot Protection

- Invisible bot detection (no challenges for users)
- Scores requests 0.0 (bot) to 1.0 (human)
- Blocks requests with score < 0.5
- Prevents visitor count manipulation

### AWS Security Best Practices

- S3 bucket access via CloudFront OAI only
- Lambda least-privilege IAM role
- HTTPS enforcement via CloudFront
- Environment variables for secrets
- DynamoDB encryption at rest
- CloudWatch logging for audit trail

## 📊 Key Features

### Frontend

- **Responsive Design** - Works on desktop, tablet, mobile
- **Interactive Map** - Leaflet.js with visitor markers
- **Real-time Counter** - Live visitor count
- **Location List** - Top visitor locations
- **Professional Layout** - Clean, modern design

### Backend

- **Serverless** - No servers to manage
- **Auto-scaling** - Handles traffic spikes
- **Bot Protection** - reCAPTCHA v3 integration
- **Geolocation** - IP-based location tracking
- **Error Handling** - Graceful degradation
- **Comprehensive Logging** - CloudWatch integration

### Infrastructure

- **Infrastructure as Code** - Terraform managed
- **Modular Design** - Reusable components
- **Version Control** - State management
- **Cost Optimized** - Pay-per-use resources
- **Highly Available** - Multi-AZ by default

## 💰 Cost

Estimated monthly costs with moderate traffic:

| Service | Monthly Cost |
|---------|-------------|
| CloudFront | ~$1-5 |
| S3 | ~$0.03 |
| API Gateway | ~$0.35 |
| Lambda | ~$0 (Free Tier) |
| DynamoDB | ~$0.25 |
| Route 53 (optional) | ~$0.50 |
| reCAPTCHA | **FREE** |
| **Total** | **$2-6/month** |

*First 12 months with AWS Free Tier: ~$1-2/month*

## 🧪 Test Coverage

- **37+ unit tests** with pytest and unittest
- **8 test classes** covering all components
- **98%+ code coverage** for Lambda function
- **Integration tests** for end-to-end flows
- **Bot detection tests** with various scenarios

Test areas:
- ✅ reCAPTCHA verification (all edge cases)
- ✅ IP address extraction
- ✅ Geolocation services
- ✅ DynamoDB operations
- ✅ Lambda handler
- ✅ CORS headers
- ✅ Error handling

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Complete system architecture diagram |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Step-by-step deployment instructions |
| [terraform/README.md](terraform/README.md) | Terraform usage guide |
| [RECAPTCHA_SETUP.md](RECAPTCHA_SETUP.md) | reCAPTCHA integration guide |
| [TEST_BOT_DETECTION.md](TEST_BOT_DETECTION.md) | Manual testing guide |
| [resume_back_end/TEST_README.md](resume_back_end/TEST_README.md) | Unit testing documentation |

## 🛠️ Technologies Used

### Frontend
- HTML5, CSS3, JavaScript (ES6+)
- Leaflet.js (interactive maps)
- Google reCAPTCHA v3

### Backend
- Python 3.12
- AWS Lambda
- AWS API Gateway
- AWS DynamoDB
- External APIs (ipinfo.io, ip-api.com)

### Infrastructure
- AWS S3
- AWS CloudFront
- AWS Route 53 (optional)
- AWS IAM
- AWS CloudWatch
- Terraform (IaC)

### Testing
- pytest
- unittest
- pytest-cov (coverage)
- moto (AWS mocking)

## 🔄 CI/CD (Optional)

Ready for GitHub Actions automation:

```yaml
# .github/workflows/deploy.yml
name: Deploy Cloud Resume
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy Frontend
        run: aws s3 sync resume_front_end/ s3://$BUCKET/
      - name: Deploy Backend
        run: |
          cd resume_back_end
          zip lambda.zip lambda_function.py
          aws lambda update-function-code --function-name $FUNCTION --zip-file fileb://lambda.zip
```

## 🎓 Skills Demonstrated

- ✅ **Cloud Architecture** - Serverless design
- ✅ **Infrastructure as Code** - Terraform
- ✅ **Backend Development** - Python, Lambda
- ✅ **Frontend Development** - HTML/CSS/JS
- ✅ **DevOps** - CI/CD, automation
- ✅ **Security** - Bot protection, IAM, HTTPS
- ✅ **Testing** - Unit tests, integration tests
- ✅ **API Integration** - Third-party services
- ✅ **Documentation** - Comprehensive guides
- ✅ **Cost Optimization** - Resource efficiency

## 📈 Monitoring

### View Logs

```bash
# Lambda logs
aws logs tail /aws/lambda/cloud-resume-visitor-counter-prod --follow

# Check visitor count
aws dynamodb scan --table-name cloud-resume-visitors-prod --select COUNT
```

### CloudWatch Metrics

- Lambda invocations
- API Gateway requests
- CloudFront cache hit rate
- DynamoDB read/write units
- Error rates and latency

## 🗑️ Cleanup

To remove all resources:

```bash
# Empty S3 bucket
aws s3 rm s3://$(terraform output -raw s3_bucket_name) --recursive

# Destroy infrastructure
cd terraform
terraform destroy
```

## 🤝 Contributing

This is a personal project, but feel free to:
- Fork and adapt for your own resume
- Submit issues for bugs
- Suggest improvements

## 📝 License

This project is open source and available for educational purposes.

## 🔗 Links

- **Cloud Resume Challenge**: https://cloudresumechallenge.dev/
- **My LinkedIn**: [linkedin.com/in/michail-kakos](https://linkedin.com/in/michail-kakos)
- **My GitHub**: [github.com/michailkakos](https://github.com/michailkakos)

## 🎯 Project Completion Checklist

- [x] Static website (HTML/CSS/JavaScript)
- [x] Deploy to S3 with static website hosting
- [x] HTTPS via CloudFront
- [x] Custom DNS with Route 53 (optional)
- [x] Visitor counter with JavaScript
- [x] API Gateway endpoint
- [x] Lambda function (Python)
- [x] DynamoDB for data storage
- [x] Infrastructure as Code (Terraform)
- [x] Source control (Git)
- [x] CI/CD pipeline (ready)
- [x] **Extended Features:**
  - [x] IP geolocation with map visualization
  - [x] reCAPTCHA v3 bot protection
  - [x] Comprehensive unit tests (37+)
  - [x] Complete documentation
  - [x] Modular Terraform structure
  - [x] Security best practices

---

**Built with ☁️ by [Michail Kakos](https://github.com/michailkakos)**

*Part of the #CloudResumeChallenge*
