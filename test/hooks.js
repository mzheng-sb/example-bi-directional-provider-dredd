/**
 * Dredd Test Hooks
 * 
 * These hooks allow you to modify requests and responses during Dredd tests.
 * Useful for:
 * - Setting up test data
 * - Cleaning up after tests
 * - Modifying request/response data
 * - Skipping certain tests
 * - Adding custom validations
 */

const hooks = require('hooks');

// State management for test data
let testProductId = null;

/**
 * Before All Hook
 * Runs once before all tests start
 */
hooks.beforeAll((transactions, done) => {
  console.log('🚀 Starting Dredd contract tests...');
  done();
});

/**
 * After All Hook
 * Runs once after all tests complete
 */
hooks.afterAll((transactions, done) => {
  console.log('✅ All Dredd contract tests completed');
  done();
});

/**
 * Before Each Hook
 * Runs before each individual test
 */
hooks.beforeEach((transaction, done) => {
  // Log the test being executed
  console.log(`Running: ${transaction.name}`);
  done();
});

/**
 * After Each Hook
 * Runs after each individual test
 */
hooks.afterEach((transaction, done) => {
  // Could add cleanup logic here if needed
  done();
});

/**
 * POST /products - Create Product
 * This test creates a product and stores the ID for use in subsequent tests
 */
hooks.before('Products > /products > Create a product > 200 > application/json; charset=utf-8', (transaction, done) => {
  console.log('📝 Preparing to create product...');
  done();
});

hooks.after('Products > /products > Create a product > 200 > application/json; charset=utf-8', (transaction, done) => {
  // Parse the response to get the created product ID
  try {
    const response = JSON.parse(transaction.real.body);
    testProductId = response.id;
    console.log(`✅ Product created with ID: ${testProductId}`);
  } catch (error) {
    console.error('❌ Failed to parse product creation response:', error);
  }
  done();
});

/**
 * GET /products - List All Products
 * This test retrieves all products
 */
hooks.before('Products > /products > List all products > 200 > application/json; charset=utf-8', (transaction, done) => {
  console.log('📋 Preparing to list all products...');
  done();
});

hooks.after('Products > /products > List all products > 200 > application/json; charset=utf-8', (transaction, done) => {
  // Validate response is an array
  try {
    const response = JSON.parse(transaction.real.body);
    if (!Array.isArray(response)) {
      console.error('❌ Response is not an array');
    } else {
      console.log(`✅ Retrieved ${response.length} product(s)`);
    }
  } catch (error) {
    console.error('❌ Failed to parse products list response:', error);
  }
  done();
});

/**
 * GET /product/{id} - Get Product by ID
 * This test retrieves a specific product by ID
 */
hooks.before('Products > /product/{id} > Find product by ID > 200 > application/json; charset=utf-8', (transaction, done) => {
  console.log('🔍 Preparing to get product by ID...');
  // The test uses ID "10" from the OAS example
  done();
});

hooks.after('Products > /product/{id} > Find product by ID > 200 > application/json; charset=utf-8', (transaction, done) => {
  // Validate product structure
  try {
    const response = JSON.parse(transaction.real.body);
    console.log(`✅ Retrieved product: ${JSON.stringify(response)}`);
  } catch (error) {
    console.error('❌ Failed to parse product response:', error);
  }
  done();
});

/**
 * Example: How to skip a test
 * Uncomment to skip specific tests
 */
// hooks.before('Products > /products > Create a product > 200', (transaction, done) => {
//   transaction.skip = true;
//   console.log('⏭️  Skipping product creation test');
//   done();
// });

/**
 * Example: How to modify a request
 * Uncomment to modify request data
 */
// hooks.before('Products > /products > Create a product > 200', (transaction, done) => {
//   const requestBody = JSON.parse(transaction.request.body);
//   requestBody.name = 'Modified Product Name';
//   transaction.request.body = JSON.stringify(requestBody);
//   done();
// });

/**
 * Example: How to add custom headers
 * Uncomment to add authorization or other headers
 */
// hooks.beforeEach((transaction, done) => {
//   transaction.request.headers['Authorization'] = 'Bearer test-token';
//   done();
// });

/**
 * Example: How to add custom validation
 * Uncomment to add additional response validations
 */
// hooks.after('Products > /products > List all products > 200', (transaction, done) => {
//   const response = JSON.parse(transaction.real.body);
//   
//   // Custom validation: check all products have required fields
//   response.forEach(product => {
//     if (!product.id || !product.name || !product.price) {
//       transaction.fail = 'Product missing required fields';
//     }
//   });
//   
//   done();
// });

/**
 * Example: Provider State Setup
 * In a real scenario, you might set up database state here
 */
// hooks.before('Products > /product/{id} > Find product by ID > 200', (transaction, done) => {
//   // Example: Ensure product with ID exists in database
//   // db.createProduct({ id: '10', name: 'test', price: 100 });
//   done();
// });

console.log('📚 Dredd hooks loaded successfully');
