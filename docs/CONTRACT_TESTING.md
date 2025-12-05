# Contract Testing Guide

## Overview

This repository implements **Bi-Directional Contract Testing** using:
- **OpenAPI Specification (OAS)** as the provider contract
- **Dredd** for validating the API implementation against the OAS
- **PactFlow** as the contract broker for cross-contract validation
- **GitHub Actions** for CI/CD automation

## What is Bi-Directional Contract Testing?

Bi-directional contract testing allows providers and consumers to work independently while ensuring compatibility:

1. **Provider Side** (this repository):
   - Defines API contract using OpenAPI specification
   - Validates implementation against OAS using Dredd
   - Publishes OAS + verification results to PactFlow

2. **Consumer Side**:
   - Creates consumer contracts (Pacts) from their tests
   - Publishes Pacts to PactFlow

3. **Cross-Contract Validation**:
   - PactFlow automatically validates consumer Pacts against provider OAS
   - Ensures consumers only use endpoints/fields defined in provider contract

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Provider (This Repo)                 │
│                                                         │
│  ┌──────────────┐    ┌──────────┐    ┌──────────────┐ │
│  │ OAS Spec     │───▶│  Dredd   │───▶│ Verification │ │
│  │ products.yml │    │  Tests   │    │   Results    │ │
│  └──────────────┘    └──────────┘    └──────────────┘ │
│         │                                      │        │
│         └──────────────┬───────────────────────┘        │
│                        ▼                                │
│              ┌──────────────────┐                       │
│              │   Publish to     │                       │
│              │   PactFlow       │                       │
│              └──────────────────┘                       │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  PactFlow Broker                        │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │  Cross-Contract Validation                     │    │
│  │  (Consumer Pacts vs Provider OAS)              │    │
│  └────────────────────────────────────────────────┘    │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │  Can-I-Deploy Check                            │    │
│  │  (Verify compatibility before deployment)      │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```
.
├── oas/
│   └── products.yml              # OpenAPI 3.0 specification
├── src/
│   ├── product/
│   │   ├── product.controller.js # API request handlers
│   │   ├── product.repository.js # Data access layer
│   │   ├── product.routes.js     # Route definitions
│   │   └── product.js            # Product model
│   └── middleware/               # Express middleware
├── test/
│   └── hooks.js                  # Dredd test hooks
├── dredd.yml                     # Dredd configuration
├── server.js                     # Express server entry point
├── Makefile                      # Build/test/deploy automation
└── .github/workflows/
    └── build.yml                 # CI/CD pipeline
```

## API Endpoints

The Product API provides three endpoints:

### 1. List All Products
```http
GET /products
```

**Response (200)**:
```json
[
  {
    "id": "1234",
    "type": "food",
    "name": "pizza",
    "price": 42
  }
]
```

### 2. Create Product
```http
POST /products
Content-Type: application/json

{
  "id": "1234",
  "type": "food",
  "name": "pizza",
  "price": 42
}
```

**Response (200)**:
```json
{
  "id": "1234",
  "type": "food",
  "name": "pizza",
  "price": 42
}
```

### 3. Get Product by ID
```http
GET /product/{id}
```

**Response (200)**:
```json
{
  "id": "1234",
  "type": "food",
  "name": "pizza",
  "price": 42
}
```

## Running Contract Tests Locally

### Prerequisites

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Set environment variables**:
   ```bash
   export PACT_BROKER_BASE_URL=https://smartbear.pactflow.io
   export PACT_BROKER_TOKEN=<your-token>
   ```

### Running Tests

#### Quick Test (Dredd only)
```bash
npm test
```

This will:
1. Start the Express server on port 3001
2. Run Dredd tests against the running server
3. Generate verification results in `output/report.md`

#### Full CI Workflow (Local)
```bash
make fake_ci
```

This simulates the full CI pipeline:
1. Run Dredd tests
2. Publish provider contract to PactFlow
3. Check can-i-deploy
4. Deploy (if on master branch)

### Individual Steps

#### 1. Run Only Tests
```bash
make test
```

#### 2. Publish Provider Contract
```bash
make publish_provider_contract
```

This publishes:
- OpenAPI specification (`oas/products.yml`)
- Verification results (`output/report.md`)
- Metadata (version, branch, verification status)

#### 3. Check Deployment Readiness
```bash
make can_i_deploy
```

This queries PactFlow to determine if:
- All consumer contracts are compatible with this provider version
- It's safe to deploy to production

#### 4. Record Deployment
```bash
make deploy
```

Records the deployment in PactFlow for tracking.

## Understanding Dredd Tests

Dredd validates your API implementation against the OpenAPI spec:

### Configuration (`dredd.yml`)
```yaml
blueprint: ./oas/products.yml     # OAS specification
endpoint: 'http://127.0.0.1:3001' # API server URL
reporter: [markdown]              # Output format
output: [./output/report.md]      # Results location
hookfiles: ./test/hooks.js        # Test hooks
```

### Test Hooks (`test/hooks.js`)

Hooks allow you to:
- Set up test data before requests
- Validate responses
- Skip certain tests
- Modify requests/responses

Example hook structure:
```javascript
const hooks = require('hooks');

hooks.before('Products > Create a product', (transaction, done) => {
  // Setup before test
  done();
});

hooks.after('Products > Create a product', (transaction, done) => {
  // Cleanup after test
  done();
});
```

## PactFlow Integration

### Publishing Provider Contracts

When you run `npm run publish` or `make publish_provider_contract`, the following happens:

1. **Contract Package** includes:
   - OpenAPI specification (YAML)
   - Verification results (Markdown)
   - Metadata:
     - Provider name: `pactflow-example-bi-directional-provider-dredd`
     - Version: Generated via `absolute-version`
     - Branch: Current git branch
     - Verification exit code: 0 (pass) or 1 (fail)
     - Verifier: `dredd`

2. **Command**:
   ```bash
   pactflow publish-provider-contract oas/products.yml \
     --provider pactflow-example-bi-directional-provider-dredd \
     --provider-app-version $(npx -y absolute-version) \
     --branch $(git rev-parse --abbrev-ref HEAD) \
     --content-type application/yaml \
     --verification-exit-code=0 \
     --verification-results output/report.md \
     --verification-results-content-type "text/plain" \
     --verifier dredd
   ```

### Can-I-Deploy Checks

Before deploying, verify compatibility:

```bash
pact-broker can-i-deploy \
  --pacticipant pactflow-example-bi-directional-provider-dredd \
  --version="$(npx -y absolute-version)" \
  --to-environment production
```

This checks:
- ✅ All consumer Pacts are compatible with this provider version
- ✅ Cross-contract validation has passed
- ✅ No breaking changes for production consumers

### Recording Deployments

After successful deployment:

```bash
pact-broker record-deployment \
  --pacticipant pactflow-example-bi-directional-provider-dredd \
  --version "$(npx -y absolute-version)" \
  --environment production
```

This:
- Records which version is in each environment
- Enables can-i-deploy checks for consumers
- Tracks deployment history

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/build.yml`) implements:

### 1. Test Stage
```yaml
- name: Test
  run: GIT_BRANCH=${GITHUB_REF:11} make ci
```

Runs:
- Dredd tests
- Publishes provider contract to PactFlow

### 2. Can-I-Deploy Stage
```yaml
- name: Can I deploy?
  run: GIT_BRANCH=${GITHUB_REF:11} make can_i_deploy
```

Verifies deployment safety

### 3. Deploy Stage (master only)
```yaml
- name: Deploy
  run: GIT_BRANCH=${GITHUB_REF:11} make deploy
  if: github.ref == 'refs/heads/master'
```

Records production deployment

## Versioning Strategy

This project uses **absolute versioning**:

```bash
npx -y absolute-version
```

This generates a version string like:
```
0.0.1-<branch>-<commit-hash>
```

Benefits:
- Unique version per commit
- Traceable to git history
- Works with branch-based workflows

## Compatible Consumers

This provider is compatible with:
- [pactflow-example-bi-directional-consumer-nock](https://github.com/pactflow/example-bi-directional-consumer-nock)
- [pactflow-example-bi-directional-consumer-msw](https://github.com/pactflow/example-bi-directional-consumer-msw)
- [pactflow-example-bi-directional-consumer-wiremock](https://github.com/pactflow/example-bi-directional-consumer-wiremock)
- [pactflow-example-bi-directional-consumer-mountebank](https://github.com/pactflow/example-bi-directional-consumer-mountebank)

## Troubleshooting

### Dredd Tests Failing

1. **Check server is running**:
   ```bash
   curl http://localhost:3001/products
   ```

2. **Review Dredd output**:
   ```bash
   cat output/report.md
   ```

3. **Validate OAS spec**:
   - Ensure examples match implementation
   - Check response schemas are correct
   - Verify all required fields are present

### Can-I-Deploy Failing

1. **Check PactFlow for verification results**:
   - Log into PactFlow dashboard
   - Navigate to provider: `pactflow-example-bi-directional-provider-dredd`
   - Review contract verification matrix

2. **Common issues**:
   - Consumer expects a field you removed (breaking change)
   - Consumer Pact hasn't been verified against your latest OAS
   - Network issues connecting to PactFlow

### Publishing Failures

1. **Verify credentials**:
   ```bash
   echo $PACT_BROKER_BASE_URL
   echo $PACT_BROKER_TOKEN
   ```

2. **Check file paths**:
   - `oas/products.yml` exists
   - `output/report.md` exists (generated by Dredd)

3. **Validate OAS syntax**:
   ```bash
   npm run dredd -- --dry-run
   ```

## Best Practices

### 1. Keep OAS in Sync
- Update `oas/products.yml` whenever API changes
- Run Dredd tests to verify implementation matches spec
- Commit OAS changes with implementation changes

### 2. Version Control
- Use semantic versioning for releases
- Tag releases in git
- Use absolute-version for CI builds

### 3. Test Before Publishing
- Always run `npm test` locally before pushing
- Ensure all Dredd tests pass
- Review verification results

### 4. Monitor PactFlow
- Check verification status regularly
- Review consumer compatibility before breaking changes
- Communicate with consumer teams about changes

### 5. Branch Strategy
- Use feature branches for development
- Run can-i-deploy on all branches
- Only deploy from master/main branch

## Advanced Topics

### Provider States

Provider states allow consumers to test against specific scenarios:

```javascript
// In test/hooks.js
hooks.before('GET /product/{id}', (transaction) => {
  // Set up state: "product with ID 10 exists"
  // This would typically seed a test database
});
```

### Custom Verification Results

Enhance report.md with additional context:

```javascript
// Generate custom verification report
const report = `
# Dredd Tests - ${new Date().toISOString()}

## Coverage
- Total endpoints: 3
- Tested endpoints: 3
- Coverage: 100%

## Results
${dreddResults}
`;
```

### Multi-Environment Testing

Test against different environments:

```bash
# Development
ENDPOINT=http://localhost:3001 npm run dredd

# Staging
ENDPOINT=https://staging.example.com npm run dredd

# Production smoke test
ENDPOINT=https://api.example.com npm run dredd
```

## Resources

- [PactFlow Documentation](https://docs.pactflow.io)
- [Dredd Documentation](https://dredd.org/en/latest/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Bi-Directional Contract Testing Workshop](https://docs.pactflow.io/docs/workshops/bi-directional-contract-testing)

## Getting Help

- GitHub Issues: [pactflow/example-bi-directional-provider-dredd](https://github.com/pactflow/example-bi-directional-provider-dredd/issues)
- Pact Slack: [slack.pact.io](https://slack.pact.io)
- PactFlow Support: support@pactflow.io
