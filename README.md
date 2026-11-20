# Serverless Security Workshop

[中文版](./README.cn.md)

A serverless security workshop demo application built on Huawei Cloud.

## Project Overview

This project is a **Serverless Security Workshop** that demonstrates how to build secure serverless applications on Huawei Cloud.

### Background Story

This project is based on a fictional **"Wild Rydes" unicorn rental platform**:
- Users can rent various magical unicorns
- Unicorns have different customization options (socks, horns, glasses, capes)
- Partners can provide additional accessories and services

### Learning Objectives

This workshop teaches the following security practices:

1. **Identity & Access Management (IAM)**
   - How to properly configure function permissions
   - Using IAM agencies to implement least privilege

2. **Infrastructure Security**
   - VPC private network configuration
   - Security group rules

3. **Data Security**
   - Data at rest encryption
   - Sensitive information protection

4. **Transport Security**
   - HTTPS enforcement
   - API signature authentication

5. **Monitoring & Logging**
   - Function logging configuration
   - Anomaly monitoring and alerting

### Core Features

This project implements a complete Serverless REST API with the following modules:

| Module | Function | Description |
|--------|----------|-------------|
| **Unicorn Parts** | Query unicorn accessories | List available magic socks, horns, glasses, capes |
| **Customization** | Manage customization options | Users can create, view, delete unicorn customizations |
| **Partners** | Partner management | Partner registration and management (simplified) |

## Architecture

```
                    ┌─────────────────────────────────────┐
                    │           APIG (API Gateway)       │
                    │   HTTPS access, unified entry      │
                    └──────────────┬──────────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Unicorn Parts   │  │ Customize       │  │ Partners        │
│ FunctionGraph   │  │ FunctionGraph   │  │ FunctionGraph   │
│ /socks         │  │ /customizations │  │ /partners       │
│ /horns         │  │                 │  │                 │
│ /glasses       │  │                 │  │                 │
│ /capes         │  │                 │  │                 │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  GeminiDB (Cluster) │
                    │  Cassandra │
                    │  Store parts/customers │
                    └─────────────────────┘
```

### Tech Stack

| Component | Huawei Cloud Service | Description |
|-----------|---------------------|-------------|
| API Gateway | APIG | Unified entry, HTTPS, traffic control |
| Backend | FunctionGraph | Node.js 18 runtime |
| Database | GeminiDB | Cassandra NoSQL |
| Network | VPC + Security Group | Private network isolation |

## Prerequisites

- Huawei Cloud account
- AK/SK credentials
- Terraform >= 1.5

## Quick Start

### 1. Clone the repository

```bash
git clone <repo-url>
cd serverless-security-workshop
```

### 2. Configure credentials

```bash
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
```

### 3. Deploy

```bash
cd infra
terraform init
terraform apply -var-file=tfvars.example
```

### 4. Verify

```bash
# Get API URL
APIG_URL=$(terraform output -raw apig_url)

# Test APIs
curl "$APIG_URL/socks"
curl "$APIG_URL/horns"
curl "$APIG_URL/glasses"
curl "$APIG_URL/capes"
curl "$APIG_URL/customizations"
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /socks | List magic socks |
| GET | /horns | List unicorn horns |
| GET | /glasses | List magic glasses |
| GET | /capes | List magic capes |
| GET | /customizations | List customizations |
| POST | /customizations | Create new customization |
| DELETE | /customizations/{id} | Delete customization |
| POST | /partners | Create partner |

## Security Features

This project demonstrates the following Huawei Cloud security best practices:

1. **IAM Agency**
   - FunctionGraph accesses other services through Agency
   - Follows least privilege principle

2. **Private Network**
   - All resources deployed within VPC
   - Only exposed through APIG

3. **Security Groups**
   - Strict inbound traffic control
   - Only necessary ports open

4. **HTTPS Enforcement**
   - APIG enforces HTTPS
   - Protects data in transit

## Cleanup

```bash
terraform destroy -var-file=tfvars.example
```

## License

MIT No Attribution - Copyright Huawei Cloud
