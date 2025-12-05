# Contract Testing Quick Start Guide

Get started with contract testing in under 5 minutes!

## Prerequisites

- Node.js 20.x or higher
- npm installed
- PactFlow account (or access to a Pact Broker)
- API token from PactFlow

## Step 1: Clone and Install

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/pactflow/example-bi-directional-provider-dredd
cd example-bi-directional-provider-dredd

# Install dependencies
npm install
```

## Step 2: Set Environment Variables

```bash
# Set your PactFlow credentials
export PACT_BROKER_BASE_URL=https://smartbear.pactflow.io
export PACT_BROKER_TOKEN=your-token-here

# Verify they're set
echo $PACT_BROKER_BASE_URL
echo $PACT_BROKER_TOKEN
```

**Getting your token:**
1. Log into PactFlow at https://smartbear.pactflow.io
2. Go to Settings → API Tokens
3. Generate a new token or copy existing one

## Step 3: Run Your First Contract Test

```bash
npm test
```

You should see output like:
```
Provider API listening on port 3001...
pass: POST (200) /products duration: 64ms
pass: GET (200) /products duration: 10ms
pass: GET (200) /product/10 duration: 8ms
complete: 3 passing, 0 failing, 0 errors, 0 skipped, 3 total
```

✅ **Success!** Your API is validated against the OpenAPI specification.

## Step 4: Publish Your Contract to PactFlow

```bash
npm run publish
```

You should see:
```
Publishing provider contract to PactFlow...
Successfully published contract
```

✅ **Success!** Your provider contract is now in PactFlow.

## Step 5: Check If You Can Deploy

```bash
npm run can-i-deploy
```

You should see:
```
Computer says yes \o/

CONSUMER       | C.VERSION | PROVIDER    | P.VERSION | SUCCESS?
---------------|-----------|-------------|-----------|----------
pactflow-ex... | 1.0.0     | pactflow-.. | 1.0.0     | true

All required verification results are published and successful
```

✅ **Success!** You're safe to deploy to production.

## Step 6: View Your Contract in PactFlow

1. Open your browser to your PactFlow URL
2. Navigate to the provider: `pactflow-example-bi-directional-provider-dredd`
3. View the verification matrix to see consumer compatibility

## What Just Happened?

### Contract Testing Workflow:

```
┌─────────────────┐
│  1. Run Tests   │ ──▶ Dredd validates API against OpenAPI spec
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ 2. Publish      │ ──▶ OpenAPI spec + test results → PactFlow
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ 3. Can-I-Deploy │ ──▶ PactFlow checks consumer compatibility
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ 4. Deploy ✅    │ ──▶ Safe to deploy to production
└─────────────────┘
```

### Files Involved:

- **`oas/products.yml`** - Your API contract (OpenAPI specification)
- **`server.js`** - Your API implementation
- **`dredd.yml`** - Test configuration
- **`test/hooks.js`** - Test hooks for setup/teardown
- **`output/report.md`** - Test results

## Next Steps

### 1. Explore the Verification Script

Use the helper script for a guided workflow:

```bash
# Make executable
chmod +x scripts/verify-contracts.sh

# Run full workflow with helpful output
./scripts/verify-contracts.sh full

# See all available commands
./scripts/verify-contracts.sh help
```

### 2. Try Making a Change

Let's add a field to the Product model:

```bash
# 1. Edit the OAS spec
vim oas/products.yml

# Add a new optional field like "description"

# 2. Edit the implementation
vim src/product/product.repository.js

# Add the description field to your product objects

# 3. Run tests
npm test

# 4. Publish updated contract
npm run publish

# 5. Check compatibility
npm run can-i-deploy
```

### 3. Understand the API

Test the API manually:

```bash
# Start the server
npm start

# In another terminal, test the endpoints:

# List all products
curl http://localhost:3001/products

# Create a product
curl -X POST http://localhost:3001/products \
  -H "Content-Type: application/json" \
  -d '{"id": "99", "type": "food", "name": "burger", "price": 15}'

# Get a specific product
curl http://localhost:3001/product/10
```

### 4. Learn More About Contract Testing

Read the comprehensive guide:

```bash
cat docs/CONTRACT_TESTING.md
```

Or view examples:

```bash
cat examples/README.md
```

## Common Commands Reference

```bash
# Testing
npm test                    # Run Dredd contract tests
npm start                   # Start the API server

# Publishing
npm run publish             # Publish contract to PactFlow

# Deployment Checks
npm run can-i-deploy        # Check if safe to deploy
npm run deploy              # Record deployment to production

# Using the Script
./scripts/verify-contracts.sh test          # Run tests only
./scripts/verify-contracts.sh publish       # Publish contract
./scripts/verify-contracts.sh can-i-deploy  # Check deployment
./scripts/verify-contracts.sh full          # Complete workflow

# Makefile Commands
make test                   # Run tests
make ci                     # Run CI workflow
make can_i_deploy           # Check deployment
make fake_ci                # Simulate full CI locally
```

## Troubleshooting

### Tests Failing?

```bash
# Check if server starts
npm start
# Open http://localhost:3001/products in browser

# Check OAS spec syntax
npm run dredd -- --dry-run

# View detailed test output
dredd --loglevel debug
```

### Can't Publish?

```bash
# Verify environment variables
echo $PACT_BROKER_BASE_URL
echo $PACT_BROKER_TOKEN

# Check network connectivity
curl -H "Authorization: Bearer $PACT_BROKER_TOKEN" \
  $PACT_BROKER_BASE_URL/

# Ensure test results exist
cat output/report.md
```

### Can-I-Deploy Failing?

This usually means:
1. A consumer expects something your provider doesn't offer (breaking change)
2. A consumer hasn't verified against your latest contract yet

**Solution:**
- Check the PactFlow dashboard for details
- Review the verification matrix
- Coordinate with consumer teams

## Environment Setup for Different Shells

### Bash/Zsh (Linux/Mac)
```bash
export PACT_BROKER_BASE_URL=https://smartbear.pactflow.io
export PACT_BROKER_TOKEN=your-token
```

### Fish Shell
```fish
set -x PACT_BROKER_BASE_URL https://smartbear.pactflow.io
set -x PACT_BROKER_TOKEN your-token
```

### Windows PowerShell
```powershell
$env:PACT_BROKER_BASE_URL="https://smartbear.pactflow.io"
$env:PACT_BROKER_TOKEN="your-token"
```

### Windows CMD
```cmd
set PACT_BROKER_BASE_URL=https://smartbear.pactflow.io
set PACT_BROKER_TOKEN=your-token
```

### Make Permanent (Linux/Mac)

Add to `~/.bashrc` or `~/.zshrc`:
```bash
echo 'export PACT_BROKER_BASE_URL=https://smartbear.pactflow.io' >> ~/.bashrc
echo 'export PACT_BROKER_TOKEN=your-token' >> ~/.bashrc
source ~/.bashrc
```

## What's Next?

### For Developers:
1. Read the full [Contract Testing Guide](../docs/CONTRACT_TESTING.md)
2. Explore [Examples](../examples/README.md)
3. Try modifying the API and running tests
4. Set up in your CI/CD pipeline

### For Teams:
1. Integrate into your deployment pipeline
2. Set up PactFlow webhooks for notifications
3. Establish contract testing governance
4. Train team members on contract testing

### Advanced Topics:
- Provider states for complex scenarios
- Multi-environment testing
- Custom verification results
- Breaking change management

## Getting Help

- **Documentation**: See `docs/CONTRACT_TESTING.md`
- **Examples**: See `examples/README.md`
- **GitHub Issues**: [Repository Issues](https://github.com/pactflow/example-bi-directional-provider-dredd/issues)
- **Pact Slack**: [slack.pact.io](https://slack.pact.io)
- **PactFlow Docs**: [docs.pactflow.io](https://docs.pactflow.io)

## Success Checklist

- ✅ Dependencies installed
- ✅ Environment variables set
- ✅ Tests passing locally
- ✅ Contract published to PactFlow
- ✅ Can-i-deploy check passing
- ✅ Understanding of workflow

**Congratulations!** You're now ready to use contract testing in your development workflow! 🎉
