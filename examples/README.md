# Contract Testing Examples

This directory contains practical examples of contract testing workflows for the Product API.

## Examples

### 1. Basic Contract Testing Workflow

**Scenario**: Run tests and publish to PactFlow

```bash
# Step 1: Run Dredd tests
npm test

# Step 2: Publish contract to PactFlow
npm run publish

# Step 3: Check if safe to deploy
npm run can-i-deploy
```

### 2. Using the Verification Script

```bash
# Make the script executable (first time only)
chmod +x scripts/verify-contracts.sh

# Run complete workflow
./scripts/verify-contracts.sh full

# Run individual commands
./scripts/verify-contracts.sh test
./scripts/verify-contracts.sh publish
./scripts/verify-contracts.sh can-i-deploy
```

### 3. Testing Against Different Environments

```bash
# Test against local development
npm test

# Test against staging
ENDPOINT=https://staging.example.com npm run dredd

# Test against production (read-only)
ENDPOINT=https://api.example.com npm run dredd
```

### 4. Publishing with Custom Version

```bash
# Publish with specific version
VERSION=1.2.3 npm run publish

# Publish with custom branch
BRANCH=feature/new-endpoint npm run publish
```

### 5. Multi-Environment Deployment Check

```bash
# Check if can deploy to production
npm run can-i-deploy

# Check if can deploy to staging
ENVIRONMENT=staging ./scripts/verify-contracts.sh can-i-deploy

# Check if can deploy to development
ENVIRONMENT=development ./scripts/verify-contracts.sh can-i-deploy
```

### 6. Manual Contract Publishing

```bash
# Get current version
VERSION=$(npx -y absolute-version)
echo "Version: $VERSION"

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Branch: $BRANCH"

# Publish contract manually
pactflow publish-provider-contract oas/products.yml \
  --provider pactflow-example-bi-directional-provider-dredd \
  --provider-app-version $VERSION \
  --branch $BRANCH \
  --content-type application/yaml \
  --verification-exit-code=0 \
  --verification-results output/report.md \
  --verification-results-content-type "text/plain" \
  --verifier dredd
```

### 7. Viewing Contract Verification Matrix

```bash
# Using pact-broker CLI
pact-broker matrix \
  --pacticipant pactflow-example-bi-directional-provider-dredd

# Using web interface
echo "Visit: $PACT_BROKER_BASE_URL/pacts/provider/pactflow-example-bi-directional-provider-dredd"
```

### 8. Recording Deployment

```bash
# After successful deployment to production
pact-broker record-deployment \
  --pacticipant pactflow-example-bi-directional-provider-dredd \
  --version "$(npx -y absolute-version)" \
  --environment production

# Record to staging
pact-broker record-deployment \
  --pacticipant pactflow-example-bi-directional-provider-dredd \
  --version "$(npx -y absolute-version)" \
  --environment staging
```

### 9. Testing with Custom Dredd Configuration

Create a custom Dredd config file `dredd-custom.yml`:

```yaml
reporter: [markdown, html]
output: [./output/report.md, ./output/report.html]
loglevel: debug
```

Run with custom config:

```bash
dredd --config dredd-custom.yml
```

### 10. CI/CD Integration Examples

#### GitHub Actions
```yaml
- name: Run Contract Tests
  run: npm test

- name: Publish to PactFlow
  run: npm run publish
  env:
    PACT_BROKER_BASE_URL: ${{ secrets.PACT_BROKER_BASE_URL }}
    PACT_BROKER_TOKEN: ${{ secrets.PACT_BROKER_TOKEN }}

- name: Check Can Deploy
  run: npm run can-i-deploy
```

#### GitLab CI
```yaml
contract-test:
  script:
    - npm test
    - npm run publish
    - npm run can-i-deploy
  variables:
    PACT_BROKER_BASE_URL: $PACT_BROKER_BASE_URL
    PACT_BROKER_TOKEN: $PACT_BROKER_TOKEN
```

### 11. Debugging Failed Tests

```bash
# Run Dredd with verbose logging
dredd --loglevel debug

# Run with inline errors
dredd --inline-errors

# Save detailed report
dredd --reporter html --output ./output/report.html

# Test specific endpoint only
dredd --only 'Products > /products > Create a product > 200'
```

### 12. Contract Testing in Development

```bash
# Watch mode (requires nodemon)
npm install -g nodemon
nodemon --exec "npm test" --watch src --watch oas

# Quick iteration cycle
while true; do
  npm test
  read -p "Press enter to run again, Ctrl+C to exit"
done
```

### 13. Validating OpenAPI Specification

```bash
# Dry run (no actual requests)
npm run dredd -- --dry-run

# Using swagger-cli (install separately)
npm install -g @apidevtools/swagger-cli
swagger-cli validate oas/products.yml
```

### 14. Testing with Authentication

If your API requires authentication, modify `test/hooks.js`:

```javascript
hooks.beforeEach((transaction, done) => {
  transaction.request.headers['Authorization'] = 'Bearer test-token';
  done();
});
```

### 15. Provider States Example

For testing specific provider states, add to `test/hooks.js`:

```javascript
hooks.before('Products > /product/{id} > Find product by ID > 404', (transaction, done) => {
  // Ensure product doesn't exist
  // In real scenario, clean up database or mock
  done();
});

hooks.before('Products > /product/{id} > Find product by ID > 200', (transaction, done) => {
  // Ensure product exists
  // In real scenario, seed database or mock
  done();
});
```

## Environment Variables Reference

```bash
# Required for publishing
export PACT_BROKER_BASE_URL=https://smartbear.pactflow.io
export PACT_BROKER_TOKEN=your-token-here

# Optional
export ENVIRONMENT=production  # Target environment for can-i-deploy
export VERSION=1.0.0          # Override version
export BRANCH=main            # Override branch
```

## Common Workflows

### Feature Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/new-endpoint

# 2. Update OAS specification
vim oas/products.yml

# 3. Implement the feature
vim src/product/product.controller.js

# 4. Run tests locally
npm test

# 5. Publish contract to PactFlow
npm run publish

# 6. Check compatibility (should pass on feature branch)
npm run can-i-deploy || echo "Expected to fail - consumers not updated yet"

# 7. Commit and push
git add .
git commit -m "Add new endpoint"
git push origin feature/new-endpoint
```

### Pre-Deployment Workflow

```bash
# 1. Ensure on master/main branch
git checkout master
git pull

# 2. Run full test suite
npm test

# 3. Publish contract
npm run publish

# 4. Check deployment safety
npm run can-i-deploy

# 5. If safe, deploy
# ... deployment steps ...

# 6. Record deployment
npm run deploy
```

### Hotfix Workflow

```bash
# 1. Create hotfix branch
git checkout -b hotfix/critical-bug

# 2. Fix the bug
# ... make changes ...

# 3. Ensure tests still pass
npm test

# 4. Publish contract (should be compatible)
npm run publish

# 5. Verify compatibility
npm run can-i-deploy

# 6. Merge and deploy if safe
```

## Tips and Best Practices

1. **Always run tests before publishing**
   ```bash
   npm test && npm run publish
   ```

2. **Use the verification script for consistency**
   ```bash
   ./scripts/verify-contracts.sh full
   ```

3. **Check can-i-deploy before every deployment**
   ```bash
   npm run can-i-deploy || exit 1
   ```

4. **Version your OAS changes**
   - Commit OAS changes with implementation changes
   - Tag releases for easy tracking

5. **Monitor PactFlow dashboard**
   - Regular checks for compatibility issues
   - Review consumer feedback

6. **Communicate breaking changes**
   - Notify consumer teams before making breaking changes
   - Use semantic versioning

## Troubleshooting

See the main [Contract Testing Guide](../docs/CONTRACT_TESTING.md) for detailed troubleshooting steps.

## Additional Resources

- [Dredd Documentation](https://dredd.org/en/latest/)
- [PactFlow Bi-Directional Contracts](https://docs.pactflow.io/docs/bi-directional-contract-testing)
- [OpenAPI Specification](https://swagger.io/specification/)
