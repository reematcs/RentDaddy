# CI/CD Pipeline Setup Guide

This guide explains how to set up and configure the CI/CD pipeline for the RentDaddy project.

## Overview

The CI/CD pipeline consists of several GitHub Actions workflows:

1. **CI Pipeline** (`ci.yml`) - Runs on every push and PR
2. **Deploy to Production** (`deploy-production.yml`) - Deploys to production on main branch
3. **Deploy to Staging** (`deploy-staging.yml`) - Deploys PRs to staging
4. **Rollback** (`rollback.yml`) - Manual rollback capability
5. **Scheduled Tasks** (`scheduled-tasks.yml`) - Cron jobs
6. **Security Scan** (`security-scan.yml`) - Regular security scans

## Prerequisites

### AWS Resources Required

1. **ECS Clusters**:
   - `rentdaddy-cluster` (production)
   - `rentdaddy-staging-cluster` (staging)

2. **ECR Repositories**:
   - `rentdaddy-backend`
   - `rentdaddy-frontend`
   - `rentdaddy-backend-staging`
   - `rentdaddy-frontend-staging`

3. **ECS Services**:
   - `rentdaddy-backend-service`
   - `rentdaddy-frontend-service`
   - `rentdaddy-backend-staging-service`
   - `rentdaddy-frontend-staging-service`

4. **ECS Task Definitions**:
   - `rentdaddy-backend-task`
   - `rentdaddy-frontend-task`
   - `rentdaddy-backend-staging-task`
   - `rentdaddy-frontend-staging-task`

5. **S3 Bucket** (optional):
   - `rentdaddy-certificates` (for Documenso certs)

### GitHub Secrets Required

Navigate to your repository settings → Secrets and variables → Actions, and add these secrets:

#### Production Environment Secrets

**AWS Credentials:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Database:**
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `PG_URL` (full connection string)

**Authentication:**
- `CLERK_SECRET_KEY`
- `CLERK_WEBHOOK`
- `VITE_CLERK_PUBLISHABLE_KEY`

**Email:**
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `SMTP_FROM`
- `SMTP_USE_TLS`

**Integrations:**
- `DOCUMENSO_API_KEY`
- `DOCUMENSO_WEBHOOK_SECRET`
- `DOCUMENSO_API_URL`
- `VITE_DOCUMENSO_PUBLIC_URL`
- `OPENAI_API_KEY`

**Application:**
- `CRON_SECRET_TOKEN`
- `DOMAIN_URL` (backend URL)
- `VITE_BACKEND_URL`
- `VITE_SERVER_URL`
- `APP_DOMAIN` (frontend domain)

**Notifications (optional):**
- `SLACK_WEBHOOK`

#### Staging Environment Secrets

Add the same secrets with `_STAGING` suffix, for example:
- `AWS_ACCESS_KEY_ID_STAGING`
- `AWS_SECRET_ACCESS_KEY_STAGING`
- `POSTGRES_HOST_STAGING`
- etc.

#### Test Environment Secrets (for CI)

- `CLERK_SECRET_KEY_TEST`
- `CLERK_WEBHOOK_TEST`
- `VITE_CLERK_PUBLISHABLE_KEY_TEST`

## Setting Up GitHub Environments

1. Go to Settings → Environments
2. Create `production` environment with:
   - Required reviewers (recommended)
   - Deployment branches: only `main`
   - Environment secrets (if needed)
3. Create `staging` environment with:
   - No restrictions
   - Environment-specific secrets

## Workflow Descriptions

### CI Pipeline

Runs automatically on:
- Push to `main` or `develop`
- Pull requests to `main`

Tests include:
- Backend linting (golangci-lint)
- Backend tests with PostgreSQL
- Frontend linting (ESLint)
- Frontend build test
- Security scanning (Trivy)
- Docker build test

### Production Deployment

Triggers on:
- Push to `main` branch
- Manual workflow dispatch

Process:
1. Runs all tests (unless skipped)
2. Builds Docker images
3. Pushes to ECR
4. Updates ECS task definitions
5. Deploys to ECS services
6. Runs database migrations
7. Verifies deployment health
8. Sends Slack notification

### Staging Deployment

Triggers on:
- Pull request events
- Manual workflow dispatch

Automatically deploys PR changes to staging environment and comments the staging URL on the PR.

### Rollback Workflow

Manual trigger with options:
- Environment: production or staging
- Service: backend, frontend, or both
- Image tag: specific version or previous

### Scheduled Tasks

Runs daily at midnight UTC:
- Expire leases
- Send expiration notifications
- Cleanup old CloudWatch logs

Can also be triggered manually for specific tasks.

### Security Scanning

Runs:
- Weekly on Mondays
- On dependency file changes
- Manual trigger

Includes:
- Dependency vulnerability scanning
- Container image scanning
- Secret scanning
- SAST with CodeQL
- Infrastructure scanning

## Initial Setup Steps

1. **Fork/Clone the repository**

2. **Create AWS resources** (if not existing):
   ```bash
   # Use the Terraform configuration in deployment/simplified_terraform
   cd deployment/simplified_terraform
   terraform init
   terraform apply
   ```

3. **Set up GitHub secrets**:
   - Add all required secrets to your repository
   - Use GitHub CLI for bulk addition:
   ```bash
   gh secret set AWS_ACCESS_KEY_ID -b "your-access-key"
   gh secret set AWS_SECRET_ACCESS_KEY -b "your-secret-key"
   # ... continue for all secrets
   ```

4. **Configure environments**:
   - Create production and staging environments
   - Set appropriate protection rules

5. **Update workflow files** (if needed):
   - Adjust AWS region
   - Update service/cluster names
   - Modify ECR repository names

6. **Test the pipeline**:
   - Create a test PR to verify staging deployment
   - Merge to main to test production deployment

## Monitoring and Troubleshooting

### Check Workflow Runs
- Go to Actions tab in GitHub
- Filter by workflow name
- Check logs for failures

### Common Issues

1. **AWS Authentication Failures**:
   - Verify AWS credentials are correct
   - Check IAM permissions

2. **ECS Deployment Failures**:
   - Ensure task definitions exist
   - Check service names match
   - Verify container health checks

3. **Build Failures**:
   - Check Dockerfile paths
   - Verify build context
   - Check for missing dependencies

4. **Migration Failures**:
   - Ensure database connectivity
   - Check migration files
   - Verify PG_URL format

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster rentdaddy-cluster --services rentdaddy-backend-service

# View recent deployments
aws ecs list-tasks --cluster rentdaddy-cluster --service-name rentdaddy-backend-service

# Check CloudWatch logs
aws logs tail /ecs/rentdaddy-backend --follow

# Manually trigger workflow
gh workflow run deploy-production.yml

# View workflow runs
gh run list --workflow=deploy-production.yml
```

## Best Practices

1. **Always test in staging first**
2. **Use pull requests for all changes**
3. **Keep secrets updated and rotated**
4. **Monitor deployment notifications**
5. **Review security scan results regularly**
6. **Tag releases for easy rollback**
7. **Document any custom modifications**

## Support

For issues or questions:
1. Check workflow logs first
2. Review this documentation
3. Check AWS service health
4. Contact the maintainers