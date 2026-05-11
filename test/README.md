# Test Suite for Diagram Engine Content Pipeline

This directory contains comprehensive tests for the content validation and rescue flow functionality.

## Test Files

### `content_validation_test.dart`
Tests for the content validation system including:
- JSON Schema validation
- JEE question requirements
- Multiple choice requirements  
- Diagram question requirements
- Source metadata requirements
- Question ID format validation
- Expected time validation

### `rescue_flow_test.dart`
Integration tests for the rescue flow system including:
- Complete rescue flow UI testing
- Rescue system logic testing
- Content loader integration
- Mock exam mode behavior
- Rescue progress tracking
- Rescue question quality validation
- Error handling
- Performance testing

## Running Tests

### Prerequisites
Ensure Flutter and Dart are installed and available in your PATH.

### Running Individual Test Files
```bash
# Run content validation tests
flutter test test/content_validation_test.dart

# Run rescue flow tests  
flutter test test/rescue_flow_test.dart

# Run all tests
flutter test
```

### Running with Coverage
```bash
flutter test --coverage
```

## Test Coverage

### Content Validation Tests
- ✅ Schema validation with valid questions
- ✅ JEE question requirements (prerequisites, rescue questions, diagrams)
- ✅ Multiple choice requirements (why-wrong explanations)
- ✅ Diagram question requirements (diagram_id)
- ✅ Source metadata requirements for JEE questions
- ✅ Question ID format validation
- ✅ Expected time validation with warnings
- ✅ Rescue question loading
- ✅ Mock rescue question creation
- ✅ Pipeline completeness validation
- ✅ Integration workflow testing

### Rescue Flow Tests
- ✅ Complete rescue flow UI testing (foundation → bridge → original)
- ✅ Rescue system logic (question generation, concept gap analysis)
- ✅ Content loader integration (geometry rescue ladder)
- ✅ Mock exam mode (rescue disabled)
- ✅ Rescue progress tracking
- ✅ Rescue question quality validation
- ✅ Error handling (missing rescue questions)
- ✅ Performance testing with large question sets

## Test Data

Tests use mock data that follows the content schema without copying copyrighted material. All test questions are original creations that demonstrate the validation and rescue flow functionality.

## Continuous Integration

These tests are designed to run in CI environments and provide comprehensive coverage of the content pipeline functionality. They ensure that:

1. Content validation works correctly
2. Rescue flows function as expected
3. Integration between components is seamless
4. Error conditions are handled gracefully
5. Performance requirements are met

## Adding New Tests

When adding new content types or rescue flow features:

1. Add corresponding test cases to the appropriate test file
2. Update this README with new test coverage
3. Ensure tests follow the existing patterns and naming conventions
4. Run tests locally before committing

## Test Utilities

The test suite includes utilities for:
- Creating mock questions with valid schema
- Setting up test concept graphs
- Simulating rescue flow scenarios
- Testing edge cases and error conditions