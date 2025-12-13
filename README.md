Cloud Resume Challenge - AWS Edition (Extended)
A serverless cloud resume with visitor counter, geolocation tracking, and bot protection using AWS services and Infrastructure as Code.

Project Overview
This project implements the Cloud Resume Challenge (https://cloudresumechallenge.dev/) with additional features:

- ✅ Static website hosted on **AWS S3**
- ✅ HTTPS distribution via **CloudFront CDN**
- ✅ Visitor counter API with **API Gateway + Lambda**
- ✅ Data storage in **DynamoDB**
- ✅ **IP geolocation** with interactive map
- ✅ **reCAPTCHA v3** bot protection
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Comprehensive unit tests** 
- ✅ DNS management with **Route 53**

Solution Architecture
The solution utilizes a serverless design, bridging traditional networking with modern cloud engineering.

![Cloud Resume Challenge - Complete Serverless Architecture](resume_front_end/images/CRC-diagram.png)
 

Technologies Used
Frontend Layer:
•	Amazon S3: Static website hosting.
•	Amazon CloudFront: Global CDN for low latency worldwide.
•	ACM + Route 53: HTTPS/TLS encryption across all endpoints and custom domain routing.

Backend Layer:
•	API Gateway + Lambda (Python): Serverless REST API with Python
•	DynamoDB: Real-time visitor metrics and geolocation analytics storage

DevOps, Security & Monitoring:
•	Terraform: Complete Infrastructure as Code
•	GitHub Actions: Automated CI/CD pipeline, Pytest unit and integration testing, zero-downtime with CloudFront invalidation.
•	Security: AWS IAM with least-privilege policies + Google reCAPTCHA v3 bot protection.
•	Monitoring: CloudWatch (logs + metrics) and SNS (alerts).

Project Structure
├── frontend/
│   ├── index.html
│   ├── styles.css
│   ├── script.js
│
├── backend/
│   ├── lambda_function.py
│   ├── requirements.txt
│
├── terraform/
│   ├── main.tf
│   ├── s3.tf
│   ├── cloudfront.tf
│   ├── dynamodb.tf
│   ├── lambda.tf
│   ├── apigateway.tf
│   ├── outputs.tf
│   ├── variables.tf
│
├── .github/workflows/
│   ├── frontend-deploy.yml
│   ├── backend-deploy.yml
│   ├── terraform-deploy.yml
│
└── README.md

Phase 1 — Frontend Website (HTML/CSS)
The project begins with a static resume built from scratch using HTML and CSS.
This includes:
Clean profile section
Work experience
Skills
Projects
Visitor counter placeholder
The frontend retrieves the visitor counter using JavaScript that calls the API Gateway endpoint.

Phase 2 — Hosting on S3 + CloudFront (HTTPS)
The website is hosted in a private S3 bucket.
CloudFront serves as the CDN with:
Origin Access Control (OAC)
ACM HTTPS certificate
Caching optimization
Custom domain (Route 53)
CloudFront provides global performance and security.

Phase 3 — Visitor Counter (API, Lambda, DynamoDB)
How it works:
JavaScript → calls API Gateway
API Gateway → triggers Lambda
Lambda → reads/updates DynamoDB table
New visitor count returned to frontend

DynamoDB Structure
Partition Key: "homePageID"
Row Key:       "visitorCount"
count:         number

Lambda Responsibilities
Increment visits
Handle CORS
Return JSON response

Phase 4 — Infrastructure as Code (Terraform)
Terraform deploys:
S3 bucket
CloudFront distribution
ACM certificate
Route 53 records
DynamoDB table
Lambda + IAM roles
API Gateway REST API
Outputs (endpoints, ARNs, URLs)
One command deploys everything:
terraform init
terraform apply


Phase 5 — CI/CD (GitHub Actions)
Frontend CI/CD
Triggered on push to main:
Build website
Sync files to S3
Invalidate CloudFront cache
Backend CI/CD
Triggered when backend code changes:
Zip Python Lambda
Upload to S3 or update Lambda directly
Deploy updates
Terraform CI/CD
Triggered on infrastructure updates:
terraform fmt
terraform plan
terraform apply

Required GitHub Secrets
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
CLOUDFRONT_DISTRIBUTION_ID

Phase 6 — AWS Certification
Alongside the project, I am also studying for:
AWS Solutions Architect Associate
AWS Developer Associate
AWS Security Specialty
The hands-on work significantly strengthened the theory.
Key Learnings
Networking knowledge helps, but cloud engineering requires a new mindset
Serverless debugging teaches more than tutorials
CORS + IAM permissions = most real errors
CI/CD and IaC elevate a simple project into real production engineering
Cloud engineering is a combination of frontend, backend, DevOps, networking, and security

Future Improvements
AI Chatbot: Answers questions about my skills and projects (Lambda integration with an LLM provider)
Live Now Tracker: Shows how many visitors are online right now
Duplicate Visitor Detection: Ensures accurate metrics by filtering out repeat visits

Links
Live Website: (https://michailkakos-resume.com/)
GitHub Repository: (https://github.com/mikecldev/AWS-resume)

Skills Demonstrated
✅Cloud Architecture - Serverless design
✅Infrastructure as Code - Terraform
✅ Backend Development - Python, Lambda
✅ Frontend Development - HTML/CSS/JS
✅ DevOps - CI/CD, automation
✅ Security - Bot protection, IAM, HTTPS
✅ Testing - Unit tests, integration tests
✅ API Integration - Third-party services
✅ Documentation - Comprehensive guides
✅ Cost Optimization - Resource efficiency
