#!/bin/bash

# Contract Verification Script
# This script provides a comprehensive workflow for contract testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROVIDER_NAME="pactflow-example-bi-directional-provider-dredd"
OAS_FILE="oas/products.yml"
REPORT_FILE="output/report.md"
SERVER_PORT=3001
ENVIRONMENT="${ENVIRONMENT:-production}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install Node.js and npm."
        exit 1
    fi
    print_success "npm is installed"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_warning "node_modules not found. Running npm install..."
        npm install
    fi
    print_success "Dependencies are installed"
    
    # Check environment variables
    if [ -z "$PACT_BROKER_BASE_URL" ]; then
        print_error "PACT_BROKER_BASE_URL environment variable is not set"
        echo "Please set it with: export PACT_BROKER_BASE_URL=https://your-broker-url"
        exit 1
    fi
    print_success "PACT_BROKER_BASE_URL is set: $PACT_BROKER_BASE_URL"
    
    if [ -z "$PACT_BROKER_TOKEN" ]; then
        print_error "PACT_BROKER_TOKEN environment variable is not set"
        echo "Please set it with: export PACT_BROKER_TOKEN=your-token"
        exit 1
    fi
    print_success "PACT_BROKER_TOKEN is set"
    
    # Check if OAS file exists
    if [ ! -f "$OAS_FILE" ]; then
        print_error "OpenAPI specification not found at $OAS_FILE"
        exit 1
    fi
    print_success "OpenAPI specification found"
}

# Function to run Dredd tests
run_dredd_tests() {
    print_header "Running Dredd Tests"
    
    # Create output directory if it doesn't exist
    mkdir -p output
    
    # Run tests
    if npm test; then
        print_success "Dredd tests passed"
        VERIFICATION_EXIT_CODE=0
    else
        print_error "Dredd tests failed"
        VERIFICATION_EXIT_CODE=1
    fi
    
    # Display test results
    if [ -f "$REPORT_FILE" ]; then
        print_info "Test results:"
        cat "$REPORT_FILE"
    else
        print_warning "Report file not found at $REPORT_FILE"
    fi
    
    return $VERIFICATION_EXIT_CODE
}

# Function to publish provider contract
publish_contract() {
    print_header "Publishing Provider Contract to PactFlow"
    
    # Get version
    VERSION=$(npx -y absolute-version)
    print_info "Version: $VERSION"
    
    # Get branch
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    print_info "Branch: $BRANCH"
    
    # Check verification results
    if [ ! -f "$REPORT_FILE" ]; then
        print_error "Verification results not found. Please run tests first."
        exit 1
    fi
    
    # Publish contract
    print_info "Publishing to PactFlow..."
    pactflow publish-provider-contract "$OAS_FILE" \
        --provider "$PROVIDER_NAME" \
        --provider-app-version "$VERSION" \
        --branch "$BRANCH" \
        --content-type application/yaml \
        --verification-exit-code=$VERIFICATION_EXIT_CODE \
        --verification-results "$REPORT_FILE" \
        --verification-results-content-type "text/plain" \
        --verifier dredd
    
    print_success "Provider contract published successfully"
    print_info "View in PactFlow: $PACT_BROKER_BASE_URL"
}

# Function to check can-i-deploy
check_can_deploy() {
    print_header "Checking Deployment Compatibility"
    
    VERSION=$(npx -y absolute-version)
    print_info "Checking if version $VERSION can be deployed to $ENVIRONMENT"
    
    if pact-broker can-i-deploy \
        --pacticipant "$PROVIDER_NAME" \
        --version "$VERSION" \
        --to-environment "$ENVIRONMENT"; then
        print_success "✅ Safe to deploy to $ENVIRONMENT"
        return 0
    else
        print_error "❌ NOT safe to deploy to $ENVIRONMENT"
        print_warning "Review contract verification matrix in PactFlow"
        return 1
    fi
}

# Function to record deployment
record_deployment() {
    print_header "Recording Deployment"
    
    VERSION=$(npx -y absolute-version)
    print_info "Recording deployment of version $VERSION to $ENVIRONMENT"
    
    pact-broker record-deployment \
        --pacticipant "$PROVIDER_NAME" \
        --version "$VERSION" \
        --environment "$ENVIRONMENT"
    
    print_success "Deployment recorded successfully"
}

# Function to show contract matrix
show_matrix() {
    print_header "Contract Verification Matrix"
    
    print_info "Fetching verification matrix from PactFlow..."
    print_info "Visit: $PACT_BROKER_BASE_URL/pacts/provider/$PROVIDER_NAME"
    print_info ""
    print_info "You can also view the matrix using:"
    echo "  pact-broker matrix --pacticipant $PROVIDER_NAME"
}

# Function to validate OAS
validate_oas() {
    print_header "Validating OpenAPI Specification"
    
    print_info "Checking OAS syntax with Dredd dry-run..."
    if npm run dredd -- --dry-run 2>&1 | grep -q "^complete:"; then
        print_success "OAS specification is valid"
    else
        print_warning "OAS validation completed with warnings (check output above)"
    fi
}

# Function to show help
show_help() {
    echo "Contract Verification Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  test              Run Dredd tests only"
    echo "  publish           Publish provider contract to PactFlow"
    echo "  can-i-deploy      Check if safe to deploy"
    echo "  deploy            Record deployment (requires can-i-deploy to pass)"
    echo "  full              Run full workflow (test + publish + can-i-deploy)"
    echo "  matrix            Show contract verification matrix"
    echo "  validate          Validate OAS specification"
    echo "  help              Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PACT_BROKER_BASE_URL    PactFlow broker URL (required)"
    echo "  PACT_BROKER_TOKEN       PactFlow API token (required)"
    echo "  ENVIRONMENT             Target environment (default: production)"
    echo ""
    echo "Examples:"
    echo "  $0 test                          # Run Dredd tests"
    echo "  $0 full                          # Run complete workflow"
    echo "  ENVIRONMENT=staging $0 can-i-deploy  # Check staging deployment"
    echo ""
}

# Main script logic
main() {
    COMMAND="${1:-help}"
    
    case "$COMMAND" in
        test)
            check_prerequisites
            run_dredd_tests
            ;;
        publish)
            check_prerequisites
            if [ ! -f "$REPORT_FILE" ]; then
                print_warning "No test results found. Running tests first..."
                run_dredd_tests || true
            fi
            publish_contract
            ;;
        can-i-deploy)
            check_prerequisites
            check_can_deploy
            ;;
        deploy)
            check_prerequisites
            if check_can_deploy; then
                record_deployment
            else
                print_error "Cannot deploy - compatibility check failed"
                exit 1
            fi
            ;;
        full)
            check_prerequisites
            if run_dredd_tests; then
                publish_contract
                check_can_deploy
            else
                print_error "Tests failed. Not publishing contract."
                exit 1
            fi
            ;;
        matrix)
            check_prerequisites
            show_matrix
            ;;
        validate)
            check_prerequisites
            validate_oas
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
