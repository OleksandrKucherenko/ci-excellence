# CI Excellence Framework - Integration Examples

This directory contains practical integration examples for different project types and scenarios. Each example demonstrates how to integrate the CI Excellence Framework with your specific technology stack and workflows.

## 📁 Available Examples

### [nodejs-express/](./nodejs-express/)
- **Type**: Node.js REST API with Express
- **Features**: Docker containerization, MongoDB integration, JWT authentication
- **Shows**:
  - Multi-stage builds
  - Database migrations
  - Environment-specific configurations
  - Health checks and monitoring

### [python-fastapi/](./python-fastapi/)
- **Type**: Python FastAPI web service
- **Features**: PostgreSQL database, Redis caching, async operations
- **Shows**:
  - Python project structure
  - Dependency management with Poetry
  - API testing with pytest
  - Database seeding and migrations

### [go-microservice/](./go-microservice/)
- **Type**: Go microservice with gRPC
- **Features**: Docker, Prometheus metrics, structured logging
- **Shows**:
  - Go modules and builds
  - gRPC service definitions
  - Integration testing
  - Performance monitoring

### [react-frontend/](./react-frontend/)
- **Type**: React single-page application
- **Features**: TypeScript, Vite, Jest testing, Storybook
- **Shows**:
  - Frontend build optimization
  - Bundle analysis
  - E2E testing with Cypress
  - Static asset deployment

### [terraform-infrastructure/](./terraform-infrastructure/)
- **Type**: Infrastructure as Code
- **Features**: AWS resources, multi-environment, Terraform Cloud
- **Shows**:
  - Terraform validation and planning
  - Infrastructure testing
  - Multi-region deployments
  - Cost optimization

### [monorepo-nx/](./monorepo-nx/)
- **Type**: Nx monorepo with multiple applications
- **Features**: React apps, NestJS APIs, shared libraries
- **Shows**:
  - Monorepo build strategies
  - Affected projects detection
  - Dependency graphs
  - Incremental builds

## 🚀 Quick Start with Examples

Each example includes:

1. **Complete setup instructions**
2. **Pre-configured environment files**
3. **Custom scripts and workflows**
4. **Testing configurations**
5. **Deployment manifests**

### Using an Example:

```bash
# Choose an example and copy it to your project
cp -r examples/nodejs-express/ /path/to/your/project/
cd /path/to/your/project

# Customize environment configurations
vim environments/staging/config.yml
vim environments/production/config.yml

# Set up secrets
mise run generate-age-key
mise run edit-secrets

# Test the integration
CI_TEST_MODE=dry_run ./scripts/deployment/10-ci-deploy-staging.sh validate
```

## 🎯 Choosing the Right Example

### For Web Applications:
- **Node.js**: `nodejs-express/` - REST APIs, real-time applications
- **Python**: `python-fastapi/` - High-performance APIs, async operations
- **Go**: `go-microservice/` - Microservices, high-concurrency systems

### For Frontend Applications:
- **React**: `react-frontend/` - SPAs, static sites, PWAs

### For Infrastructure:
- **DevOps**: `terraform-infrastructure/` - Cloud infrastructure, multi-environment

### For Complex Projects:
- **Enterprise**: `monorepo-nx/` - Large codebases, multiple teams

## 🛠️ Customization Guidelines

Each example can be customized for your specific needs:

### 1. Environment Configuration
```yaml
# environments/staging/config.yml
project:
  type: "nodejs"  # Match your project type
  build_command: "npm run build"  # Your build command
  test_command: "npm test"  # Your test command

environment_variables:
  YOUR_API_URL: "https://staging-api.example.com"
  YOUR_DATABASE_URL: "postgresql://user:pass@staging-db:5432/yourdb"
```

### 2. Deployment Strategy
```yaml
# environments/production/config.yml
deployment:
  strategy: "blue_green"  # or "rolling", "canary"
  health_check:
    path: "/health"
    timeout: 30
  rollback:
    auto_rollback: true
    health_check_threshold: 3
```

### 3. Security Configuration
```yaml
# environments/production/config.yml
security:
  scan_severity: "high"
  include_dependencies: true
  exclude_patterns:
    - "node_modules/**"
    - "coverage/**"
```

## 🔄 Migration from Examples

### Starting from an Example:

1. **Copy the example structure**
2. **Replace with your code**
3. **Update configurations**
4. **Migrate existing secrets**
5. **Test thoroughly**

### For Existing Projects:

1. **Choose the closest matching example**
2. **Copy relevant configuration files**
3. **Adapt environment variables**
4. **Update build and test commands**
5. **Integrate gradually**

## 📋 Integration Checklist

For any integration example, ensure:

- [ ] Environment configurations match your setup
- [ ] Build commands are correct for your project
- [ ] Test commands run successfully
- [ ] Secrets are properly configured
- [ ] Deployments work in dry-run mode
- [ ] Security scans pass
- [ ] Team workflows are documented

## 🧪 Testing Examples

Each example includes test configurations:

```bash
# Run tests for the example
cd examples/nodejs-express/

# Validate setup
mise run verify-tools
mise run validate-config

# Test deployment (dry run)
CI_TEST_MODE=dry_run ./scripts/deployment/10-ci-deploy-staging.sh validate

# Run security scan
CI_TEST_MODE=dry_run ./scripts/build/30-ci-security-scan.sh staging medium basic
```

## 🌟 Contributing Examples

To contribute a new example:

1. **Create a new directory** under `examples/`
2. **Include complete setup** with README.md
3. **Add environment configurations** for staging/production
4. **Provide test cases** and validation
5. **Document prerequisites** and dependencies
6. **Follow the established structure** from other examples

## 📞 Support

For help with specific examples:

1. Check the example's README.md
2. Review the [Troubleshooting Guide](../docs/troubleshooting.md)
3. Create an issue with the example name in the title
4. Include your project structure and error details

## 🎉 Success Stories

See how teams have successfully integrated the framework:

- **E-commerce Platform**: Migrated from Jenkins CI → `nodejs-express/` example
- **FinTech API**: Adopted `python-fastapi/` for regulatory compliance
- **SaaS Product**: Used `monorepo-nx/` for 50+ developer team
- **IoT Backend**: Implemented `go-microservice/` for high-throughput system

Find your success story with the CI Excellence Framework! 🚀