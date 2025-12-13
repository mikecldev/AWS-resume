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


## 🛡️ Security Features

### reCAPTCHA v3 Bot Protection

- Invisible bot detection (no challenges for users)
- Scores requests 0.0 (bot) to 1.0 (human)
- Blocks requests with score < 0.5

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

### Backend

- **Serverless** - No servers to manage
- **Auto-scaling** - Handles traffic spikes
- **Bot Protection** - reCAPTCHA v3 integration
- **Geolocation** - IP-based location tracking
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
| CloudFront | ~$1 |
| S3 | ~$0.03 |
| API Gateway | ~$0.35 |
| Lambda | ~$0 (Free Tier) |
| DynamoDB | ~$0.25 |
| Route 53 (optional) | ~$0.50 |
| reCAPTCHA | **FREE** |
| **Total** | **$1-2/month** |



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

```

### CloudWatch Metrics

- Lambda invocations
- API Gateway requests
- CloudFront cache hit rate
- DynamoDB read/write units
- Error rates and latency

```

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
  - [x] Comprehensive unit tests
  - [x] Complete documentation
  - [x] Modular Terraform structure
  - [x] Security best practices

---

