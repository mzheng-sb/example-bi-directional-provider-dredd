# Breaking Changes Analysis: Product ID Type Change from String to Integer

## Summary
This document analyzes the impact of changing the Product ID from `string` to `integer` in the Product API.

## Changes Made

### 1. OpenAPI Specification (oas/products.yml)
- **Product Schema**: Changed `id` property type from `string` to `integer`
- **Path Parameter**: Changed `/product/{id}` parameter type from `string` to `integer`
- **Examples**: Updated all example IDs from strings (e.g., `"1234"`) to integers (e.g., `1234`)

### 2. Implementation (src/)
- **product.repository.js**: Changed Map keys from strings (`"09"`, `"10"`, `"11"`) to integers (`9`, `10`, `11`)
- **product.controller.js**: 
  - Added `parseInt()` in `create()` method to convert incoming ID to integer
  - Added `parseInt()` in `getById()` method to convert path parameter to integer

## Breaking Changes for Consumers

### 1. GET /products Response
**Before:**
```json
[
  {
    "id": "09",
    "type": "CREDIT_CARD",
    "name": "Gem Visa",
    "version": "v1",
    "price": 99.99
  }
]
```

**After:**
```json
[
  {
    "id": 9,
    "type": "CREDIT_CARD",
    "name": "Gem Visa",
    "version": "v1",
    "price": 99.99
  }
]
```

**Impact**: Consumers parsing the response will receive a number instead of a string for the `id` field. This will break:
- Type assertions expecting string
- String operations on the ID (e.g., concatenation, string methods)
- Serialization/deserialization expecting string type

### 2. POST /products Request
**Before:**
```json
{
  "id": "1234",
  "type": "food",
  "price": 42
}
```

**After:**
```json
{
  "id": 1234,
  "type": "food",
  "price": 42
}
```

**Impact**: Consumers must send integer IDs instead of string IDs. The provider now converts to integer using `parseInt()`, but:
- Consumers sending strings will have them converted (may work but violates contract)
- Better to require consumers to update to send proper integers

### 3. GET /product/{id} Request
**Before:**
```
GET /product/10  (path parameter type: string)
```

**After:**
```
GET /product/10  (path parameter type: integer)
```

**Impact**: While the URL looks the same, the OpenAPI spec now declares this as an integer type. Consumers:
- May have client code generation that treats this differently
- Schema validation may fail if they validate requests against the old contract

## Consumer Compatibility Analysis

Based on the README, this provider is compatible with:
- `pactflow-example-bi-directional-consumer-nock`
- `pactflow-example-bi-directional-consumer-msw`
- `pactflow-example-bi-directional-consumer-wiremock`
- `pactflow-example-bi-directional-consumer-mountebank`

### Expected Impact on Each Consumer:

All consumers will be impacted because:

1. **Response Type Mismatch**: If consumers have Pact contracts that specify `id` as a string type with matchers like `type: string` or `regex`, the verification will fail when the provider returns an integer.

2. **Request Type Mismatch**: If consumers send POST requests with string IDs in their Pact contracts, this will technically still work due to our `parseInt()` conversion, but violates the contract specification.

3. **Generated Client Code**: Consumers using generated client code from the OpenAPI spec will have breaking changes in their codegen, changing from `string` to `number/int` types.

## Deployment Recommendation

⚠️ **WARNING: This change CANNOT be safely deployed to production without coordinating with all consumers.**

### Why This Change Breaks Consumers:

1. **Type incompatibility**: Consumers expecting string will receive integer
2. **Contract violations**: Consumer Pact contracts likely specify string type
3. **No backward compatibility**: There's no way to support both types simultaneously
4. **Runtime errors**: Consumer applications may crash or malfunction when receiving unexpected integer type

### Required Actions Before Deployment:

1. **Verify Impact with can-i-deploy**: 
   ```bash
   npm run can-i-deploy
   ```
   This will check if the updated provider contract is compatible with consumer contracts in production.

2. **Expected Result**: The can-i-deploy check will likely FAIL because:
   - Consumer contracts expect `id` as string
   - Provider now returns `id` as integer
   - This is a contract violation

3. **Coordinate with Consumers**: If can-i-deploy fails, all consumers must:
   - Update their code to handle integer IDs
   - Update their Pact contracts to expect integer IDs
   - Deploy their changes first (or simultaneously with coordinated release)

4. **Alternative Approach - Versioned API**:
   - Create a new API version (v2) with integer IDs
   - Maintain v1 with string IDs for backward compatibility
   - Gradually migrate consumers to v2
   - Deprecate and remove v1 after all consumers migrate

## Testing Results

### Local Dredd Tests: ✅ PASSING
All 3 Dredd tests pass with the new integer ID implementation:
- `POST (200) /products`
- `GET (200) /products`
- `GET (200) /product/10`

### Manual Testing: ✅ VERIFIED
Endpoints tested and working correctly:
- GET /products returns integer IDs
- GET /product/10 works with integer path parameter
- POST /products accepts and returns integer IDs

## Next Steps

1. ✅ Code changes completed and tested locally
2. ✅ Dredd verification passed
3. ⏳ Publish provider contract to PactFlow (requires PACT_BROKER_TOKEN)
4. ⏳ Run can-i-deploy to verify consumer compatibility
5. ⏳ Analyze can-i-deploy results
6. ⏳ Document consumer impact and coordinate deployment

## Conclusion

The code changes are technically sound and all tests pass. However, this is a **BREAKING CHANGE** that will impact all consumers. 

**DO NOT DEPLOY** until:
1. Consumer compatibility is verified via can-i-deploy
2. All breaking consumer issues are identified
3. Consumers are updated and ready for the change
4. A coordinated deployment plan is in place

If can-i-deploy fails (which is expected), this change should either:
- Be coordinated with consumer updates, OR
- Be implemented as a new API version to maintain backward compatibility
