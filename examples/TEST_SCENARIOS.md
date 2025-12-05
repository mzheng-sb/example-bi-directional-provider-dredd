# Contract Testing Test Scenarios

This document outlines various test scenarios and how to implement them with Dredd contract testing.

## Basic Scenarios

### Scenario 1: Testing All Endpoints

**Goal**: Verify all API endpoints match the OpenAPI specification

**Implementation**: Already configured in `dredd.yml`

```bash
npm test
```

**Expected Result**: All 3 endpoints pass
- ✅ POST /products - Create product
- ✅ GET /products - List all products  
- ✅ GET /product/{id} - Get product by ID

### Scenario 2: Testing with Custom Data

**Goal**: Test API with specific product data

**Implementation**: Modify `test/hooks.js`

```javascript
hooks.before('Products > /products > Create a product > 200', (transaction, done) => {
  // Customize request body
  const customProduct = {
    id: "custom-123",
    type: "electronics",
    name: "Laptop",
    price: 999.99
  };
  transaction.request.body = JSON.stringify(customProduct);
  done();
});
```

**Run**: `npm test`

### Scenario 3: Validating Response Structure

**Goal**: Ensure response contains all required fields

**Implementation**: Add validation in `test/hooks.js`

```javascript
hooks.after('Products > /products > List all products > 200', (transaction, done) => {
  const products = JSON.parse(transaction.real.body);
  
  // Validate each product has required fields
  products.forEach(product => {
    if (!product.id || !product.name || !product.price) {
      transaction.fail = 'Product missing required fields';
    }
  });
  
  done();
});
```

**Run**: `npm test`

## Advanced Scenarios

### Scenario 4: Testing Provider States

**Goal**: Test API in different states (empty database, with products, etc.)

**Implementation**: Use hooks to set up state

```javascript
// Empty state
hooks.before('Products > /products > List all products > 200', (transaction, done) => {
  // In a real scenario, clear database or use mocks
  console.log('Testing with empty product list');
  done();
});

// Populated state
hooks.before('Products > /product/{id} > Find product by ID > 200', (transaction, done) => {
  // In a real scenario, ensure product with ID exists
  console.log('Testing with existing product');
  done();
});
```

### Scenario 5: Testing Error Conditions

**Goal**: Verify 404 responses work correctly

**Note**: Currently not tested in OAS spec, but you can add:

```yaml
# In oas/products.yml
/product/{id}:
  get:
    responses:
      "404":
        description: Product not found
```

**Implementation**: Add hook to test

```javascript
hooks.before('Products > /product/{id} > 404', (transaction, done) => {
  // Request non-existent product
  transaction.request.uri = '/product/99999';
  done();
});
```

### Scenario 6: Testing Authentication

**Goal**: Test authenticated endpoints

**Implementation**: Add auth headers

```javascript
hooks.beforeEach((transaction, done) => {
  // Add JWT token
  transaction.request.headers['Authorization'] = 'Bearer test-token-123';
  done();
});
```

### Scenario 7: Testing Rate Limiting

**Goal**: Verify rate limiting works

**Implementation**: Make multiple requests

```javascript
hooks.before('Products > /products > List all products > 200', (transaction, done) => {
  // Make rapid requests to trigger rate limit
  // Note: This would require custom test logic
  done();
});
```

## Integration Scenarios

### Scenario 8: Testing with Real Database

**Goal**: Test against actual database

**Implementation**: Setup/teardown in hooks

```javascript
const db = require('../src/database'); // hypothetical

hooks.beforeAll((transactions, done) => {
  // Connect to test database
  db.connect('test-db')
    .then(() => done())
    .catch(err => done(err));
});

hooks.afterAll((transactions, done) => {
  // Cleanup and disconnect
  db.cleanup()
    .then(() => db.disconnect())
    .then(() => done());
});

hooks.beforeEach((transaction, done) => {
  // Clear database before each test
  db.clear().then(() => done());
});
```

### Scenario 9: Testing with External Services

**Goal**: Test API that calls external services

**Implementation**: Mock external calls

```javascript
const nock = require('nock'); // HTTP mocking library

hooks.before('Products > /products > Create a product > 200', (transaction, done) => {
  // Mock external inventory service
  nock('https://inventory-service.example.com')
    .post('/inventory')
    .reply(200, { success: true });
  
  done();
});
```

### Scenario 10: Testing Asynchronous Operations

**Goal**: Test async operations (webhooks, delayed responses)

**Implementation**: Use async hooks

```javascript
hooks.after('Products > /products > Create a product > 200', async (transaction) => {
  // Wait for async operation
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Verify webhook was called
  const webhookCalled = await checkWebhook();
  if (!webhookCalled) {
    transaction.fail = 'Webhook not triggered';
  }
});
```

## Contract Publishing Scenarios

### Scenario 11: Publishing After Successful Tests

**Goal**: Only publish contract if tests pass

**Implementation**: Use CI script

```bash
#!/bin/bash
if npm test; then
  echo "✅ Tests passed - publishing contract"
  npm run publish
else
  echo "❌ Tests failed - not publishing"
  exit 1
fi
```

### Scenario 12: Publishing with Feature Flags

**Goal**: Publish contract with feature flag metadata

**Implementation**: Add to publish command

```bash
pactflow publish-provider-contract oas/products.yml \
  --provider pactflow-example-bi-directional-provider-dredd \
  --provider-app-version $(npx -y absolute-version) \
  --branch $(git rev-parse --abbrev-ref HEAD) \
  --tag "feature-flag-enabled" \
  --content-type application/yaml \
  --verification-exit-code=0 \
  --verification-results output/report.md \
  --verification-results-content-type "text/plain" \
  --verifier dredd
```

## Deployment Scenarios

### Scenario 13: Blue-Green Deployment

**Goal**: Verify both blue and green versions are compatible

**Implementation**: Check both versions

```bash
# Check blue version
VERSION=blue-1.0.0 npm run can-i-deploy

# Check green version  
VERSION=green-1.0.0 npm run can-i-deploy

# Deploy if both pass
```

### Scenario 14: Canary Deployment

**Goal**: Deploy to subset of users first

**Implementation**: Record partial deployment

```bash
# Deploy canary
pact-broker record-deployment \
  --pacticipant pactflow-example-bi-directional-provider-dredd \
  --version $(npx -y absolute-version) \
  --environment canary

# Monitor errors/metrics

# Full deployment
pact-broker record-deployment \
  --pacticipant pactflow-example-bi-directional-provider-dredd \
  --version $(npx -y absolute-version) \
  --environment production
```

## Performance Scenarios

### Scenario 15: Load Testing

**Goal**: Verify API performance under load

**Implementation**: Run Dredd with load tool

```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:3001/products

# Then run contract tests
npm test
```

### Scenario 16: Response Time Validation

**Goal**: Ensure responses are fast enough

**Implementation**: Add timing validation

```javascript
hooks.after('Products > /products > List all products > 200', (transaction, done) => {
  const duration = transaction.duration;
  
  if (duration > 100) { // 100ms threshold
    transaction.fail = `Response too slow: ${duration}ms`;
  }
  
  done();
});
```

## Security Scenarios

### Scenario 17: Testing Input Validation

**Goal**: Ensure API validates input properly

**Implementation**: Send invalid data

```javascript
hooks.before('Products > /products > Create a product > 400', (transaction, done) => {
  // Send invalid product (negative price)
  const invalidProduct = {
    id: "123",
    type: "food",
    name: "pizza",
    price: -10 // Invalid!
  };
  transaction.request.body = JSON.stringify(invalidProduct);
  done();
});
```

### Scenario 18: Testing SQL Injection Protection

**Goal**: Verify SQL injection attempts fail safely

**Implementation**: Send malicious input

```javascript
hooks.before('Products > /product/{id} > Find product by ID > 200', (transaction, done) => {
  // Attempt SQL injection
  transaction.request.uri = "/product/1' OR '1'='1";
  transaction.expected.statusCode = 400; // Should return error
  done();
});
```

## Monitoring Scenarios

### Scenario 19: Tracking Test Metrics

**Goal**: Monitor test success rate over time

**Implementation**: Log results

```javascript
const fs = require('fs');

hooks.afterAll((transactions, done) => {
  const stats = {
    timestamp: new Date().toISOString(),
    total: transactions.length,
    passed: transactions.filter(t => t.results && t.results.length === 0).length,
    failed: transactions.filter(t => t.results && t.results.length > 0).length
  };
  
  fs.appendFileSync('test-metrics.json', JSON.stringify(stats) + '\n');
  done();
});
```

### Scenario 20: Alerting on Failures

**Goal**: Send alerts when tests fail

**Implementation**: Add notification

```javascript
hooks.afterAll((transactions, done) => {
  const failed = transactions.filter(t => t.results && t.results.length > 0);
  
  if (failed.length > 0) {
    // Send alert (email, Slack, etc.)
    sendAlert(`${failed.length} contract tests failed!`);
  }
  
  done();
});
```

## Real-World Workflow

### Complete Development Cycle

```bash
# 1. Create feature branch
git checkout -b feature/add-product-category

# 2. Update OAS spec
vim oas/products.yml
# Add 'category' field to Product schema

# 3. Update implementation
vim src/product/product.repository.js
# Add category field to products

# 4. Update tests if needed
vim test/hooks.js
# Add validation for category field

# 5. Run tests locally
npm test

# 6. Commit changes
git add .
git commit -m "Add product category field"

# 7. Push to GitHub
git push origin feature/add-product-category

# 8. CI runs automatically:
#    - npm test
#    - npm run publish
#    - npm run can-i-deploy

# 9. Review results in PactFlow

# 10. Merge to master if compatible

# 11. Deploy to production
#     - can-i-deploy check passes
#     - Deploy application
#     - Record deployment
```

## Summary

These scenarios cover:
- ✅ Basic API testing
- ✅ Advanced validation
- ✅ Provider states
- ✅ Error handling
- ✅ Authentication
- ✅ Database integration
- ✅ External services
- ✅ Async operations
- ✅ Contract publishing
- ✅ Deployment strategies
- ✅ Performance testing
- ✅ Security testing
- ✅ Monitoring

For more information:
- [Contract Testing Guide](../docs/CONTRACT_TESTING.md)
- [Quick Start Guide](../docs/QUICKSTART.md)
- [Examples](README.md)
