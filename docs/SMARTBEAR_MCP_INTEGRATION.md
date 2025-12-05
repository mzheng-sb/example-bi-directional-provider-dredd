# SmartBear MCP Integration Guide

This guide shows how to integrate contract testing with SmartBear MCP tools for enhanced workflow automation.

## Overview

SmartBear MCP (Model Context Protocol) tools provide programmatic access to:
- **Contract Testing** - PactFlow broker integration
- **BugSnag** - Error monitoring integration
- **SwaggerHub** - API management integration

## Prerequisites

- SmartBear MCP tools configured
- PactFlow broker access (PACT_BROKER_TOKEN)
- Repository cloned and dependencies installed

## Contract Testing with MCP Tools

### 1. Check Provider States

Before making changes, check what states consumers expect:

```bash
# Using SmartBear MCP tools programmatically
# This would typically be done through the MCP interface
```

**What it tells you:**
- Which provider states consumers depend on
- What data/scenarios you need to support
- Breaking change risks

### 2. View Contract Matrix

Check verification status across all consumers:

```bash
# View the contract verification matrix
# Shows which consumer versions work with which provider versions
```

**Information provided:**
- Consumer → Provider compatibility matrix
- Verification status (passed/failed)
- Latest versions for each participant
- Branch/tag information

### 3. Can-I-Deploy Check

Before deployment, verify compatibility:

```bash
npm run can-i-deploy

# Or via script
./scripts/verify-contracts.sh can-i-deploy
```

**Environment-specific checks:**

```bash
# Check production deployment
ENVIRONMENT=production ./scripts/verify-contracts.sh can-i-deploy

# Check staging deployment
ENVIRONMENT=staging ./scripts/verify-contracts.sh can-i-deploy
```

### 4. Recording Deployments

After successful deployment:

```bash
npm run deploy

# Or via script
./scripts/verify-contracts.sh deploy
```

This records:
- Which version is in which environment
- Deployment timestamp
- Application version

## Workflow Integration Examples

### Development Workflow

```bash
# 1. Check current state
./scripts/verify-contracts.sh matrix

# 2. Make changes to API
vim src/product/product.controller.js
vim oas/products.yml

# 3. Run tests
npm test

# 4. Publish contract
npm run publish

# 5. Check compatibility
npm run can-i-deploy
```

### Pre-Deployment Workflow

```bash
# 1. Verify tests pass
npm test

# 2. Publish contract
npm run publish

# 3. Check deployment safety
if npm run can-i-deploy; then
  echo "✅ Safe to deploy"
  # Proceed with deployment
else
  echo "❌ NOT safe to deploy"
  # Review PactFlow dashboard
  exit 1
fi

# 4. Deploy application
# ... deployment steps ...

# 5. Record deployment
npm run deploy
```

### CI/CD Integration

The repository includes a GitHub Actions workflow that:

1. **Test Stage** - Runs Dredd tests
2. **Publish Stage** - Publishes contract to PactFlow
3. **Can-I-Deploy Stage** - Checks compatibility
4. **Deploy Stage** - Records deployment (master only)

See `.github/workflows/build.yml` for implementation details.

## Error Monitoring with BugSnag

### Correlating Errors with Deployments

After deploying a new version:

1. **Monitor Error Rates**
   - Check for spike in errors
   - Compare to baseline

2. **Filter by Version**
   - View errors for specific release
   - Identify version-specific issues

3. **Review Network Traces**
   - Check API performance
   - Identify slow endpoints
   - Review failed requests

### Example Workflow

```bash
# After deployment
VERSION=$(npx -y absolute-version)

# Monitor errors for this version
# Would use BugSnag MCP tools to:
# - Get errors for specific release version
# - Check error trends
# - Review network spans
```

## API Management with SwaggerHub

### Publishing API Specifications

```bash
# 1. Validate OAS spec
npm run dredd -- --dry-run

# 2. Search for existing APIs in SwaggerHub
# Use MCP tools to search

# 3. Update API in SwaggerHub if needed
# Use MCP tools to publish
```

### Governance and Standardization

```bash
# Check API against organization governance rules
# This ensures consistency across all APIs
# Use SwaggerHub MCP tools to validate
```

## Advanced Workflows

### Multi-Environment Testing

```bash
# Test against different environments
# Development
ENDPOINT=http://localhost:3001 npm run dredd

# Staging
ENDPOINT=https://staging.api.example.com npm run dredd

# Production smoke test
ENDPOINT=https://api.example.com npm run dredd
```

### Branch-Based Workflow

```bash
# Feature branch
git checkout -b feature/new-endpoint

# Make changes
vim oas/products.yml
vim src/product/product.controller.js

# Test locally
npm test

# Publish with branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
npm run publish

# Check compatibility (may fail on feature branch)
npm run can-i-deploy || echo "Expected on feature branch"

# Merge to master
git checkout master
git merge feature/new-endpoint

# Re-test and publish
npm test && npm run publish

# Verify deployment safety
npm run can-i-deploy
```

### Hotfix Workflow

```bash
# Create hotfix branch
git checkout -b hotfix/critical-bug

# Fix the bug
vim src/product/product.controller.js

# Ensure tests still pass
npm test

# Publish contract (should be compatible)
npm run publish

# Verify no breaking changes
if npm run can-i-deploy; then
  echo "✅ Compatible - safe to deploy hotfix"
  git checkout master
  git merge hotfix/critical-bug
  # Deploy
  npm run deploy
else
  echo "❌ Breaking change detected - review required"
  exit 1
fi
```

## Monitoring and Observability

### Contract Verification Matrix

The verification matrix shows:
- All consumers of this provider
- Which versions are compatible
- Current deployment status
- Verification results

**Access via:**
- PactFlow dashboard
- `pact-broker matrix` CLI command
- SmartBear MCP tools

### Error Tracking

BugSnag integration provides:
- Real-time error monitoring
- Release-based error grouping
- Network performance traces
- Distributed tracing for API calls

### API Analytics

SwaggerHub provides:
- API usage analytics
- Documentation access metrics
- Governance compliance status

## Best Practices

### 1. Always Check Can-I-Deploy

Before every deployment:
```bash
npm run can-i-deploy || exit 1
```

### 2. Record All Deployments

After successful deployment:
```bash
npm run deploy
```

### 3. Monitor Post-Deployment

After deploying:
- Check BugSnag for error spikes
- Review API performance metrics
- Monitor consumer health

### 4. Coordinate Breaking Changes

For breaking changes:
1. Communicate with consumer teams
2. Plan coordinated deployment
3. Use feature flags if possible
4. Monitor closely after deployment

### 5. Maintain Documentation

Keep documentation current:
- Update OAS spec with implementation
- Document provider states
- Update examples
- Maintain changelog

## Troubleshooting with MCP Tools

### Can-I-Deploy Failures

**Problem:** Can-i-deploy check fails

**Solution:**
1. Review contract verification matrix
2. Identify which consumer is incompatible
3. Check what the consumer expects
4. Either:
   - Fix provider to be compatible
   - Work with consumer team to update their contract

### Verification Failures

**Problem:** Contract verification fails

**Solution:**
1. Review Dredd test output
2. Check OAS spec accuracy
3. Verify API implementation
4. Run tests locally to debug

### Deployment Issues

**Problem:** Errors spike after deployment

**Solution:**
1. Check BugSnag for error details
2. Review network traces
3. Compare to previous version
4. Consider rollback if severe

## Environment Variables

```bash
# Required for contract testing
export PACT_BROKER_BASE_URL=https://smartbear.pactflow.io
export PACT_BROKER_TOKEN=your-token

# Optional for specific environments
export ENVIRONMENT=production  # or staging, development
export VERSION=1.0.0          # override version
export BRANCH=main            # override branch
```

## Command Reference

```bash
# Contract Testing
npm test                    # Run Dredd tests
npm run publish             # Publish to PactFlow
npm run can-i-deploy        # Check compatibility
npm run deploy              # Record deployment

# Using Verification Script
./scripts/verify-contracts.sh test          # Run tests
./scripts/verify-contracts.sh publish       # Publish contract
./scripts/verify-contracts.sh can-i-deploy  # Check deployment
./scripts/verify-contracts.sh deploy        # Record deployment
./scripts/verify-contracts.sh full          # Complete workflow
./scripts/verify-contracts.sh matrix        # View matrix

# Makefile
make test                   # Run tests
make ci                     # Run CI workflow
make can_i_deploy           # Check deployment
make fake_ci                # Simulate CI locally
```

## Resources

- [PactFlow Documentation](https://docs.pactflow.io)
- [Contract Testing Guide](CONTRACT_TESTING.md)
- [Quick Start Guide](QUICKSTART.md)
- [Examples](../examples/README.md)

## Getting Help

- **Documentation**: See other guides in `docs/`
- **Examples**: See `examples/README.md`
- **GitHub Issues**: [Repository Issues](https://github.com/pactflow/example-bi-directional-provider-dredd/issues)
- **Pact Slack**: [slack.pact.io](https://slack.pact.io)
