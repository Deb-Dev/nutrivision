# NutriVision Testing Documentation

## Overview

This document outlines the testing strategy, current test implementation, and testing procedures for the NutriVision application. It serves as a guide for maintaining quality assurance throughout the development lifecycle.

## Testing Philosophy

NutriVision follows a **pyramid testing approach**:
- **Unit Tests**: Test individual functions and classes in isolation
- **Widget Tests**: Test UI components and user interactions
- **Integration Tests**: Test complete user workflows and system interactions

## Current Test Coverage

### Epic 1: User Onboarding & Profile Management ✅
**Status**: Core functionality implemented, basic tests in place

**Tested Components**:
- Authentication flow (Firebase Auth integration)
- Profile setup forms and validation
- BMR/TDEE calculation logic
- Dashboard data aggregation

### Epic 2: Manual Meal Logging & Basic Tracking ✅  
**Status**: Fully implemented with comprehensive testing

**Tested Components**:
- Food database service (USDA API integration)
- Barcode scanning functionality
- Meal logging workflows
- Nutritional calculations
- Data persistence and retrieval

## Test Structure

```
test/
├── unit/
│   ├── services/
│   │   ├── food_database_service_test.dart     ✅ Implemented
│   │   └── meal_suggestions_service_test.dart  📝 Planned
│   ├── models/
│   │   ├── user_profile_test.dart              📝 Planned
│   │   └── logged_meal_test.dart               📝 Planned
│   └── utils/
│       └── nutrition_calculator_test.dart      📝 Planned
│
├── widget/
│   ├── screens/
│   │   ├── dashboard_screen_test.dart          📝 Planned
│   │   ├── meal_history_screen_test.dart       📝 Planned
│   │   └── enhanced_log_meal_screen_test.dart  📝 Planned
│   └── components/
│       └── meal_card_test.dart                 📝 Planned
│
├── integration/
│   ├── auth_flow_test.dart                     📝 Planned
│   ├── meal_logging_flow_test.dart             📝 Planned
│   └── full_user_journey_test.dart             📝 Planned
│
└── widget_test.dart                            ✅ Basic implementation
```

## Unit Tests

### 1. Food Database Service Tests (`food_database_service_test.dart`)

**Current Implementation**:
```dart
group('FoodDatabaseService', () {
  test('should search foods successfully', () async {
    // Test USDA API integration
    // Verify response parsing
    // Check error handling
  });
  
  test('should handle barcode lookup', () async {
    // Test barcode scanning integration
    // Verify UPC lookup functionality
    // Check fallback behavior
  });
});
```

**Test Coverage**:
- ✅ API connection and authentication
- ✅ Food search functionality
- ✅ Response parsing and error handling
- ✅ Barcode lookup integration
- ✅ Rate limiting and caching

### 2. Meal Suggestions Service Tests (Planned)

**Planned Test Cases**:
```dart
group('MealSuggestionsService', () {
  test('should return personalized suggestions based on user preferences');
  test('should filter suggestions by meal type');
  test('should handle Firebase Remote Config integration');
  test('should cache suggestions appropriately');
});
```

### 3. Nutrition Calculator Tests (Planned)

**Planned Test Cases**:
- BMR calculation accuracy (Mifflin-St Jeor equation)
- TDEE calculation with activity multipliers
- Macro distribution calculations
- Serving size conversions

## Widget Tests

### Current Implementation Status
- **Basic Widget Test**: ✅ Implemented in `widget_test.dart`
- **Screen-Specific Tests**: 📝 Planned for next development cycle

### Planned Widget Test Coverage

#### 1. Dashboard Screen Tests
```dart
group('DashboardScreen Widget Tests', () {
  testWidgets('should display daily nutritional summary');
  testWidgets('should navigate to meal logging');
  testWidgets('should show meal suggestions button');
  testWidgets('should handle date navigation');
});
```

#### 2. Enhanced Log Meal Screen Tests
```dart
group('EnhancedLogMealScreen Widget Tests', () {
  testWidgets('should display all three tabs');
  testWidgets('should handle food search input');
  testWidgets('should trigger barcode scanner');
  testWidgets('should validate manual entry form');
});
```

#### 3. Meal History Screen Tests
```dart
group('MealHistoryScreen Widget Tests', () {
  testWidgets('should group meals by type');
  testWidgets('should display nutritional totals');
  testWidgets('should handle meal editing');
  testWidgets('should show meal details on tap');
});
```

## Integration Tests

### Planned Integration Test Scenarios

#### 1. Complete User Onboarding Flow
```dart
testWidgets('Complete user onboarding flow', (tester) async {
  // 1. Sign up with email/password
  // 2. Complete profile setup
  // 3. Set dietary preferences
  // 4. Arrive at dashboard
  // 5. Verify data persistence
});
```

#### 2. Full Meal Logging Workflow
```dart
testWidgets('End-to-end meal logging', (tester) async {
  // 1. Navigate to meal logging
  // 2. Search for food item
  // 3. Select and configure meal
  // 4. Save meal
  // 5. Verify dashboard update
  // 6. Check meal history
});
```

#### 3. Barcode Scanning Integration
```dart
testWidgets('Barcode scanning workflow', (tester) async {
  // 1. Open barcode scanner
  // 2. Mock barcode detection
  // 3. Verify food lookup
  // 4. Complete meal logging
  // 5. Verify data accuracy
});
```

## Test Data Management

### Mock Data Strategy

#### 1. User Profiles
```dart
class MockUserProfiles {
  static UserProfile basicUser = UserProfile(
    userId: 'test_user_1',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    age: 30,
    heightCm: 175,
    weightKg: 70,
    // ... other fields
  );
}
```

#### 2. Food Items
```dart
class MockFoodItems {
  static List<FoodItem> sampleFoods = [
    FoodItem(
      fdcId: '123456',
      description: 'Banana, raw',
      nutrients: [/* mock nutrients */],
      servingSizes: [/* mock serving sizes */],
    ),
    // ... more items
  ];
}
```

#### 3. API Responses
```dart
class MockApiResponses {
  static String usdaSearchResponse = '''
  {
    "foods": [
      {
        "fdcId": 123456,
        "description": "Banana, raw",
        "foodNutrients": [...]
      }
    ]
  }
  ''';
}
```

## Testing Utilities

### 1. Test Helpers
```dart
class TestHelpers {
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  static Future<void> enterText(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await pumpAndSettle(tester);
  }
}
```

### 2. Firebase Test Setup
```dart
class FirebaseTestSetup {
  static Future<void> setupFirebaseForTesting() async {
    // Initialize Firebase emulators
    // Setup test data
    // Configure authentication
  }
}
```

### 3. Network Mocking
```dart
class NetworkMocking {
  static MockClient createMockHttpClient() {
    return MockClient((request) async {
      // Return mock responses based on request
      if (request.url.contains('api.nal.usda.gov')) {
        return Response(MockApiResponses.usdaSearchResponse, 200);
      }
      return Response('Not Found', 404);
    });
  }
}
```

## Performance Testing

### 1. Load Testing Scenarios
- **Concurrent Users**: Test with 100+ simultaneous users
- **Data Volume**: Test with large meal history datasets
- **API Rate Limits**: Verify graceful handling of rate limiting

### 2. Memory Testing
- **Memory Leaks**: Monitor memory usage during extended sessions
- **Image Caching**: Test image memory management
- **Database Queries**: Monitor query performance

### 3. Network Testing
- **Offline Scenarios**: Test offline functionality and sync
- **Poor Connectivity**: Test with slow/unstable connections
- **API Failures**: Test graceful degradation

## Accessibility Testing

### 1. Screen Reader Support
```dart
testWidgets('should support screen readers', (tester) async {
  // Verify semantic labels
  // Test navigation with TalkBack/VoiceOver
  // Check contrast ratios
});
```

### 2. Keyboard Navigation
```dart
testWidgets('should support keyboard navigation', (tester) async {
  // Test tab order
  // Verify focus management
  // Check keyboard shortcuts
});
```

## Test Execution Strategy

### 1. Continuous Integration
```yaml
# .github/workflows/test.yml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter test integration_test/
```

### 2. Local Development Testing
```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/unit/services/food_database_service_test.dart

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 3. Device Testing Matrix
- **iOS**: iPhone 12, iPhone 14, iPad
- **Android**: Pixel 6, Samsung Galaxy S21, OnePlus 9
- **Flutter Versions**: 3.32.0+
- **OS Versions**: iOS 14+, Android API 21+

## Quality Gates

### 1. Code Coverage Requirements
- **Unit Tests**: Minimum 80% coverage
- **Critical Paths**: 100% coverage for authentication and payment flows
- **New Features**: 90% coverage required for new functionality

### 2. Performance Benchmarks
- **App Startup**: < 3 seconds on mid-range devices
- **Search Response**: < 2 seconds for food database queries
- **Image Loading**: < 1 second for cached images

### 3. Accessibility Standards
- **WCAG 2.1 AA**: Compliance required
- **Platform Guidelines**: Follow iOS Human Interface Guidelines and Material Design
- **Screen Reader**: 100% compatibility with platform screen readers

## Test Reporting

### 1. Automated Reports
- **Coverage Reports**: Generated on each CI run
- **Performance Reports**: Generated for release candidates
- **Accessibility Reports**: Generated weekly

### 2. Manual Test Reports
- **Feature Testing**: Document test results for each epic
- **Device Testing**: Results from physical device testing
- **User Acceptance**: Feedback from beta testing

## Testing Best Practices

### 1. Test Organization
- **Descriptive Names**: Use clear, descriptive test names
- **Group Related Tests**: Use `group()` to organize related test cases
- **Setup/Teardown**: Use `setUp()` and `tearDown()` for test initialization

### 2. Test Data
- **Isolated Tests**: Each test should be independent
- **Clean State**: Reset state between tests
- **Realistic Data**: Use realistic test data that matches production scenarios

### 3. Assertions
- **Specific Assertions**: Use specific matchers for better error messages
- **Multiple Assertions**: Test multiple aspects in a single test where appropriate
- **Error Cases**: Test both success and failure scenarios

## Future Testing Enhancements

### 1. Visual Regression Testing
- **Screenshot Comparison**: Automated UI screenshot comparison
- **Cross-Platform Consistency**: Ensure UI consistency across platforms
- **Design System Compliance**: Verify adherence to design system

### 2. AI-Powered Testing
- **Image Recognition Testing**: Test photo meal logging accuracy
- **Natural Language Testing**: Test meal suggestion relevance
- **User Behavior Simulation**: AI-driven user interaction testing

### 3. Security Testing
- **Authentication Security**: Test for common security vulnerabilities
- **Data Encryption**: Verify data encryption at rest and in transit
- **API Security**: Test API endpoints for security vulnerabilities

---

*This testing documentation is maintained alongside the codebase and should be updated with each major feature addition or testing strategy change.*
