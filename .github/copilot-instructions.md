# GitHub Copilot Agent Instructions

This is a bi-directional contract testing provider example using PactFlow, Dredd, and OpenAPI specifications.

## Project Overview

- **Project Type**: Node.js Express API Provider
- **Application Name**: `pactflow-example-bi-directional-provider-dredd`
- **Purpose**: Product API demonstrating bi-directional contract testing
- **API Specification**: `oas/products.yml` (OpenAPI 3.0)
- **Testing Tool**: Dredd (validates API against OAS spec)

## SmartBear MCP Server Configuration

Please follow the guidelines below when working with the SmartBear MCP server for this project. how to get started is here: https://developer.smartbear.com/smartbear-mcp/docs/getting-started which includes setting up your local environment and connecting to the MCP server.

An alertnative installation through docker is here: https://hub.docker.com/mcp/server/smartbear/overview

The SmartBear MCP server is already configured with the following tools available:

some of the environment variables you may need are:
PACT_BROKER_BASE_URL: https://smartbear.pactflow.io
PACT_BROKER_TOKEN: ZVWY_jrj-Uyrc8LJp-FqmA
SWAGGER_API_KEY: d917a6d5-e242-4b21-af83-ffae28593362
PACT_PROVIDER: pactflow-example-bi-directional-provider-dredd

### PactFlow / Contract Testing

**Broker Configuration:**
- **Base URL**: https://smartbear.pactflow.io
- **Pacticipant Name**: `pactflow-example-bi-directional-provider-dredd`
- **Role**: Provider in bi-directional contract testing

**Key Workflows:**

1. **Before Making Changes**
   - Check the contract matrix to see current verification status
   - Use `mcp_smartbear_contract-testing_get_provider_states` to understand expected provider states
   - Review existing contracts with consumers

2. **Publishing Provider Contracts**
   - Provider contract = OAS spec (`oas/products.yml`) + verification results
   - Always include: provider name, version, branch, verification results
   - Command reference: `npm run publish` publishes the OAS with Dredd test results

3. **Before Deployment**
   - Always run can-i-deploy check: `npm run can-i-deploy`
   - Use `mcp_smartbear_contract-testing_can_i_deploy` to verify compatibility with consumers in production
   - Target environment: `production`

4. **After Deployment**
   - Record deployment to production environment
   - Command: `npm run deploy`

**Default Parameters:**
- Provider: `pactflow-example-bi-directional-provider-dredd`
- Environment for deployment checks: `production`
- Branch: Use current git branch (usually `master`)

### BugSnag (Error Monitoring)

**When Investigating Issues:**
- Check errors from the last 24-48 hours after deployments
- Look for error spikes correlated with new releases
- Examine network traces for API performance issues
- Use `mcp_smartbear_bugsnag_get_trace` for distributed tracing
- Group errors by release version to identify problematic deployments

**Error Management:**
- Mark errors as fixed after resolving issues
- Use `mcp_smartbear_bugsnag_update_error` to update error status
- Ignore false positives or known issues

### SwaggerHub / API Hub

**API Management:**
- Organization: Check MCP configuration for org name
- Primary API: Product API at `oas/products.yml`
- Search for existing APIs: Use `mcp_smartbear_swagger_search_apis_and_domains`
- List organizations: Use `mcp_smartbear_swagger_list_organizations`

**When Modifying API Specs:**
1. Update `oas/products.yml`
2. Run Dredd tests to validate: `npm test`
3. Search for related APIs in SwaggerHub
4. Publish updated contract to PactFlow

### Reflect (Test Automation)

**If Available:**
- Execute test suites after significant API changes
- Monitor test execution status
- Check for breaking changes in API behavior

## Development Workflow

### Making API Changes

1. **Update OpenAPI Spec** (`oas/products.yml`)
   - Ensure schema definitions are accurate
   - Update examples to match implementation

2. **Update Implementation**
   - Server code: `server.js`
   - Product logic: `src/product/` directory
   - Routes: `src/product/product.routes.js`
   - Repository: `src/product/product.repository.js`

3. **Run Tests**
   ```bash
   npm test  # Runs Dredd to validate API against OAS
   ```

4. **Publish Contract**
   ```bash
   npm run publish  # Publishes OAS + verification results to PactFlow
   ```

5. **Check Compatibility**
   ```bash
   npm run can-i-deploy  # Verify compatibility with consumers
   ```

### Pre-Deployment Checklist

When preparing for deployment:

1. **Verify Contract Compatibility**
   - Use can-i-deploy to check production compatibility
   - Review contract verification matrix
   - Ensure all consumer contracts are satisfied

2. **Check Error Rates**
   - Review BugSnag for current error baseline
   - Note any existing issues before deployment

3. **API Validation**
   - All Dredd tests must pass
   - OAS spec accurately represents implementation

4. **Post-Deployment**
   - Record deployment in PactFlow
   - Monitor BugSnag for new errors
   - Verify API endpoints are functioning

## API Endpoints

The Product API has 3 endpoints:

1. **GET /products** - List all products
2. **POST /products** - Create a product
3. **GET /product/{id}** - Get product by ID

**Example cURL commands:**
```bash
# List all products
curl http://localhost:8080/products

# Create a product
curl -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"id": "1234", "type": "food", "name": "pizza", "price": 42}'

# Get product by ID
curl http://localhost:8080/product/10
```

## Important Conventions

- **Version Format**: Use `absolute-version` for consistent versioning
- **Branch Naming**: Current branch from git (typically `master`)
- **Environment**: Production environment is the deployment target
- **Verification Tool**: Always use `dredd` as the verifier name
- **Contract Format**: OpenAPI YAML file with verification results in Markdown

## When Using SmartBear MCP Tools

### Contract Testing Priorities
1. Always check can-i-deploy before suggesting deployment
2. Verify contract matrix shows passing verifications
3. Use provider name: `pactflow-example-bi-directional-provider-dredd`
4. Target environment: `production`

### Error Investigation
1. Start with recent errors (last 24-48 hours)
2. Check for patterns by release version
3. Examine network spans for API calls
4. Look for trace information on distributed operations

### API Changes
1. Validate changes against OAS spec
2. Run Dredd tests to ensure compliance
3. Check SwaggerHub for related APIs or governance rules
4. Publish updated contract to PactFlow

## Key Files

- `oas/products.yml` - OpenAPI specification (source of truth for API contract)
- `server.js` - Main Express server
- `src/product/` - Product domain logic
- `dredd.yml` - Dredd configuration
- `package.json` - Scripts for testing, publishing, deployment

## SmartBear Tool Usage Tips

- **Contract Matrix**: Check verification status across all consumer/provider pairs
- **Provider States**: Review states that consumers expect providers to support
- **Can I Deploy**: Always verify before deploying to production
- **Error Monitoring**: Correlate errors with releases using version tags
- **Network Grouping**: Use path templates like `/product/{id}` to group similar endpoints
