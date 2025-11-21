# Node.js Express API - CI Excellence Framework Integration

This example demonstrates how to integrate the CI Excellence Framework with a Node.js Express REST API application. It includes Docker containerization, MongoDB integration, JWT authentication, and comprehensive testing.

## 🏗️ Project Structure

```
nodejs-express/
├── src/
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── middleware/
│   ├── services/
│   └── app.js
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── environments/
│   ├── staging/
│   │   ├── config.yml
│   │   └── regions/us-east/config.yml
│   └── production/
│       ├── config.yml
│       └── regions/us-east/config.yml
├── scripts/                   # CI Excellence Framework scripts
├── docker/
│   ├── Dockerfile
│   ├── Dockerfile.prod
│   └── docker-compose.yml
├── package.json
├── jest.config.js
└── README.md
```

## 🚀 Features

- **Express.js** REST API framework
- **MongoDB** database with Mongoose ODM
- **JWT** authentication and authorization
- **Docker** containerization
- **Jest** testing framework
- **ESLint** and **Prettier** code quality
- **Helmet.js** security headers
- **Winston** logging
- **Rate limiting** and request validation
- **Health checks** and monitoring

## 📋 Prerequisites

- Node.js 18+
- MongoDB 5.0+
- Docker & Docker Compose
- MISE (for framework management)

## 🛠️ Setup Instructions

### 1. Clone and Setup

```bash
# Copy this example to your project
cp -r examples/nodejs-express/ /path/to/your-project/
cd /path/to/your-project

# Install dependencies
npm install

# Set up MISE and framework
mise run dev-setup
```

### 2. Environment Configuration

The framework environments are pre-configured for this Node.js project:

```yaml
# environments/staging/config.yml
project:
  type: "nodejs"
  build_command: "npm run build"
  test_command: "npm test"
  lint_command: "npm run lint"
  start_command: "npm start"

deployment:
  type: "staging"
  container_registry: "docker.io"
  image_name: "your-org/express-api"
  health_check:
    path: "/health"
    port: 3000
    timeout: 30

environment_variables:
  NODE_ENV: "staging"
  PORT: "3000"
  MONGODB_URI: "mongodb://staging-mongo:27017/express-api-staging"
  JWT_SECRET: "${JWT_SECRET}"
  LOG_LEVEL: "info"
```

```yaml
# environments/production/config.yml
project:
  type: "nodejs"
  build_command: "npm run build"
  test_command: "npm run test:ci"
  lint_command: "npm run lint"
  start_command: "npm start"

deployment:
  type: "production"
  strategy: "blue_green"
  container_registry: "docker.io"
  image_name: "your-org/express-api"
  health_check:
    path: "/health"
    port: 3000
    timeout: 30
  rollback:
    auto_rollback: true
    health_check_threshold: 3

security:
  scan_severity: "high"
  include_dependencies: true

environment_variables:
  NODE_ENV: "production"
  PORT: "3000"
  MONGODB_URI: "${MONGODB_URI}"
  JWT_SECRET: "${JWT_SECRET}"
  LOG_LEVEL: "warn"
```

### 3. Database Setup

```bash
# Start local MongoDB for development
docker-compose up -d mongodb

# Run database migrations
npm run migrate

# Seed database (optional)
npm run seed
```

### 4. Secrets Configuration

```bash
# Generate encryption key
mise run generate-age-key

# Configure secrets
mise run edit-secrets
```

Add these secrets to your encrypted configuration:

```json
{
  "JWT_SECRET": "your-super-secret-jwt-key-here",
  "MONGODB_URI": "mongodb://username:password@host:port/database",
  "REDIS_URL": "redis://username:password@host:port"
}
```

## 🧪 Testing

The framework integrates with the existing test structure:

### Unit Tests
```bash
# Run unit tests with coverage
npm run test:unit

# Run specific test file
npm test -- --testPathPattern=user.service.test.js
```

### Integration Tests
```bash
# Run integration tests with test database
npm run test:integration

# Run API endpoint tests
npm run test:api
```

### E2E Tests
```bash
# Run end-to-end tests
npm run test:e2e

# Run with test environment
NODE_ENV=test npm run test:e2e
```

### Framework Testing
```bash
# Test framework integration
CI_TEST_MODE=dry_run ./scripts/test/10-ci-unit-tests.sh
CI_TEST_MODE=dry_run ./scripts/test/20-ci-integration-tests.sh
```

## 🚢 Deployment

### Local Development
```bash
# Start development server
npm run dev

# Or with Docker
docker-compose up -d
```

### Staging Deployment
```bash
# Test staging deployment (dry run)
CI_TEST_MODE=dry_run ./scripts/deployment/10-ci-deploy-staging.sh validate

# Deploy to staging
./scripts/deployment/10-ci-deploy-staging.sh deploy us-east

# Check deployment status
./scripts/deployment/10-ci-deploy-staging.sh status us-east
```

### Production Deployment
```bash
# Validate production deployment
./scripts/deployment/20-ci-deploy-production.sh validate

# Deploy to production (requires approval)
PRODUCTION_APPROVED=true ./scripts/deployment/20-ci-deploy-production.sh deploy us-east
```

### Docker Deployment
```bash
# Build Docker image
npm run build:docker

# Push to registry
npm run push:docker

# Deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 Configuration Options

### Package.json Scripts
```json
{
  "scripts": {
    "dev": "nodemon src/app.js",
    "start": "node src/app.js",
    "build": "echo 'No build step required for Node.js'",
    "build:docker": "docker build -t express-api .",
    "test": "jest",
    "test:unit": "jest --testPathPattern=tests/unit",
    "test:integration": "jest --testPathPattern=tests/integration",
    "test:e2e": "jest --testPathPattern=tests/e2e",
    "test:ci": "jest --coverage --watchAll=false",
    "lint": "eslint src/**/*.js",
    "lint:fix": "eslint src/**/*.js --fix",
    "format": "prettier --write src/**/*.js",
    "migrate": "node scripts/migrate.js",
    "seed": "node scripts/seed.js"
  }
}
```

### Jest Configuration
```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/app.js',
    '!**/node_modules/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js']
};
```

### Environment Variables
The application supports these environment variables:

```bash
# Application
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# Database
MONGODB_URI=mongodb://localhost:27017/express-api
REDIS_URL=redis://localhost:6379

# Security
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d
BCRYPT_ROUNDS=12

# Features
ENABLE_CORS=true
ENABLE_RATE_LIMIT=true
ENABLE_COMPRESSION=true
```

## 🔒 Security Features

This example includes comprehensive security:

1. **Input Validation**: Express-validator middleware
2. **SQL Injection Prevention**: Mongoose sanitization
3. **XSS Protection**: Helmet.js security headers
4. **Rate Limiting**: Express-rate-limit middleware
5. **JWT Authentication**: Secure token-based auth
6. **Password Security**: bcrypt hashing
7. **CORS**: Configured for production
8. **Security Scanning**: Integrated with framework

## 📊 Monitoring and Logging

### Application Logging
```javascript
// Winston logger configuration
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});
```

### Health Checks
```javascript
// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const dbStatus = await mongoose.connection.db.admin().ping();
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: dbStatus ? 'connected' : 'disconnected',
      memory: process.memoryUsage(),
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});
```

## 🔄 CI/CD Workflow Integration

### Pre-commit Hooks
The framework automatically sets up hooks for:
- ESLint validation
- Prettier formatting
- Secret detection
- Test execution

### GitHub Actions
The framework provides workflows for:
- **Pre-release**: Code quality, security scanning, testing
- **Release**: Build, test, deploy to staging
- **Post-release**: Production deployment, health checks
- **Maintenance**: Cleanup, monitoring, security audits

## 🚨 Rollback Procedures

### Automatic Rollback
The framework includes automatic rollback on health check failures:

```yaml
# environments/production/config.yml
deployment:
  rollback:
    auto_rollback: true
    health_check_threshold: 3
    rollback_strategy: "previous_tag"
```

### Manual Rollback
```bash
# Manual rollback to previous version
./scripts/deployment/30-ci-rollback.sh production deploy-123 previous_tag

# Rollback via GitHub Actions
# Use "Rollback Deployment" workflow in GitHub Actions tab
```

## 📈 Performance Optimization

### Application Performance
- **Database indexing**: Optimized queries
- **Caching**: Redis integration
- **Compression**: Gzip middleware
- **Cluster mode**: Multiple CPU cores

### CI/CD Performance
- **Parallel testing**: Unit and integration tests run in parallel
- **Dependency caching**: npm packages cached between runs
- **Docker layer caching**: Optimized Docker builds
- **Incremental deployments**: Only deploy changed components

## 🛠️ Troubleshooting

### Common Issues

1. **MongoDB Connection Failed**
   ```bash
   # Check MongoDB status
   docker-compose ps mongodb

   # Check connection string
   echo $MONGODB_URI
   ```

2. **JWT Token Issues**
   ```bash
   # Verify JWT secret is set
   mise run decrypt-staging
   grep JWT_SECRET .env.secrets.json
   ```

3. **Test Failures**
   ```bash
   # Run tests with verbose output
   npm test -- --verbose

   # Check test database
   NODE_ENV=test npm run test:integration
   ```

4. **Deployment Issues**
   ```bash
   # Check deployment logs
   ./scripts/deployment/10-ci-deploy-staging.sh logs

   # Validate configuration
   ./scripts/deployment/10-ci-deploy-staging.sh validate
   ```

## 📚 Additional Resources

- [Express.js Documentation](https://expressjs.com/)
- [Mongoose Documentation](https://mongoosejs.com/)
- [Jest Testing Framework](https://jestjs.io/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [CI Excellence Framework Docs](../docs/developer-guide.md)

## 🎉 Next Steps

1. **Customize the API** for your specific use case
2. **Add authentication** for your user system
3. **Integrate monitoring** with Prometheus/Grafana
4. **Set up CI/CD** with your repository
5. **Configure production** infrastructure
6. **Add documentation** with Swagger/OpenAPI

Successfully integrate your Node.js Express API with the CI Excellence Framework! 🚀