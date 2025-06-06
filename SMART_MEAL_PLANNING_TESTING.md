# Smart Meal Planning Feature - Testing Guide

## Overview
This guide provides comprehensive testing instructions for the Smart Meal Planning feature in NutriVision. The feature includes meal planning, meal suggestions, and grocery list generation.

## Prerequisites
1. **Firebase Setup**: Ensure Firebase is configured with valid API keys
2. **User Authentication**: You need to be logged in to test the features
3. **Clean Build**: Run `flutter clean && flutter pub get` if you encounter issues

## 🚀 Quick Start Testing

### 1. Start the Application
```bash
# Run the app in debug mode
flutter run
```

### 2. Access Smart Meal Planning
1. **Login** to the app with your credentials
2. Navigate to the **Home** screen (default after login)
3. Scroll down to the **"More Actions"** section
4. Look for the **"Meal Planning"** button (calendar icon 🗓️)
5. Tap to access the Smart Meal Planning feature

## 🧪 Feature Testing Scenarios

### A. Meal Planning Screen (Calendar View)
**Location**: Home → "More Actions" → "Meal Planning" button

**Test Cases**:
1. **Calendar Navigation**:
   - ✅ Swipe between weeks
   - ✅ Tap different dates
   - ✅ Change calendar view (week/month)

2. **Meal Slot Interaction**:
   - ✅ Tap on breakfast, lunch, dinner, or snack slots
   - ✅ Verify meal suggestion screen opens
   - ✅ Add meals to specific time slots

3. **Meal Plan Management**:
   - ✅ Create a new meal plan
   - ✅ View existing meal plans
   - ✅ Switch between different meal plans

**Expected Behavior**:
- Calendar displays current week by default
- Empty meal slots show "+" or "Add meal" prompts
- Tapping a slot opens meal suggestions for that meal type
- Selected meals appear in their respective time slots

### B. Meal Suggestions Screen
**Location**: Meal Planning → Tap any meal slot

**Test Cases**:
1. **Suggestion Loading**:
   - ✅ Verify suggestions load for the selected meal type
   - ✅ Check loading states display properly
   - ✅ Handle empty/error states gracefully

2. **Suggestion Interaction**:
   - ✅ Browse different meal suggestions
   - ✅ View nutritional information
   - ✅ Select a suggestion to add to meal plan

3. **Search and Filter**:
   - ✅ Use search bar to find specific meals
   - ✅ Apply dietary filters (if implemented)
   - ✅ Sort by different criteria

**Expected Behavior**:
- Suggestions relevant to meal type (breakfast suggestions for breakfast slot)
- Each suggestion shows basic nutritional info
- Selecting a suggestion adds it to the meal plan and returns to calendar

### C. Grocery List Screen
**Location**: Meal Planning → Generate grocery list (if button available)

**Test Cases**:
1. **List Generation**:
   - ✅ Generate grocery list from current meal plan
   - ✅ Verify all ingredients are included
   - ✅ Check proper quantity calculations

2. **List Management**:
   - ✅ Check off completed items
   - ✅ Add custom items to the list
   - ✅ Edit quantities or remove items

3. **Organization**:
   - ✅ Verify items are grouped by category
   - ✅ Check alphabetical or logical ordering
   - ✅ Expand/collapse categories

**Expected Behavior**:
- Grocery list includes all ingredients from planned meals
- Items are organized by category (produce, dairy, etc.)
- Users can interact with list items (check off, edit, delete)

## 🔧 Technical Testing

### Provider State Testing
Test the Riverpod providers to ensure proper state management:

1. **Meal Plan Provider**:
   ```dart
   // In Flutter Inspector, check if providers are updating correctly
   // Look for: mealPlanProvider, activeMealPlanProvider
   ```

2. **Meal Suggestions Provider**:
   ```dart
   // Check: mealSuggestionsProvider
   // Verify it responds to meal type changes
   ```

3. **Grocery List Provider**:
   ```dart
   // Check: groceryListProvider
   // Verify it updates when meal plans change
   ```

### Error Handling Testing
1. **Network Issues**:
   - ✅ Test with poor internet connection
   - ✅ Verify error messages are user-friendly
   - ✅ Check retry mechanisms work

2. **Firebase Issues**:
   - ✅ Test with invalid user credentials
   - ✅ Verify Firestore read/write permissions
   - ✅ Check offline capability

## 🐛 Common Issues & Solutions

### Issue 1: "Provider not found" Error
**Solution**: Ensure dependency injection is properly initialized
```bash
# Restart the app completely
flutter clean
flutter pub get
flutter run
```

### Issue 2: Empty Meal Suggestions
**Possible Causes**:
- Firebase security rules blocking reads
- AI service not properly configured
- Network connectivity issues

**Solution**: Check Firebase console for security rules and API quotas

### Issue 3: Calendar Not Loading
**Solution**: Verify table_calendar dependency is properly installed
```bash
flutter pub deps | grep table_calendar
```

### Issue 4: Navigation Issues
**Solution**: Check if routes are properly defined and user is authenticated

## 📊 Performance Testing

### Memory Usage
- Monitor memory usage during long browsing sessions
- Check for memory leaks when navigating between screens

### Load Times
- Measure time to load meal suggestions
- Test grocery list generation performance
- Monitor calendar rendering speed

### Offline Capability
- Test feature behavior without internet
- Verify cached data is accessible
- Check sync behavior when connection returns

## 🎯 Test Data Setup

### Sample Meal Plans
To test effectively, you'll need some sample data:

1. **Create Test Meal Plans**:
   - Add meals for different dates
   - Include various meal types (breakfast, lunch, dinner, snacks)
   - Test with different dietary preferences

2. **Test User Scenarios**:
   - New user (no meal plans)
   - Existing user (with meal history)
   - User with dietary restrictions

## 🔍 Debug Information

### Logging
Check console logs for:
- Provider state changes
- API call responses
- Error messages
- Navigation events

### Flutter Inspector
Use Flutter Inspector to:
- Monitor widget tree
- Check provider values
- Verify state management flow

## ✅ Success Criteria

The feature is working correctly if:
- ✅ Users can navigate through the calendar
- ✅ Meal suggestions load and display properly
- ✅ Users can add meals to their meal plan
- ✅ Grocery lists generate correctly from meal plans
- ✅ All navigation flows work smoothly
- ✅ Error states are handled gracefully
- ✅ Data persists between app sessions

## 🚨 Critical Test Points

Before declaring the feature ready:
1. **End-to-End Flow**: Complete a full meal planning cycle
2. **Data Persistence**: Verify meal plans save correctly
3. **Multi-User**: Test with different user accounts
4. **Edge Cases**: Test with empty states, network failures
5. **Performance**: Ensure smooth performance on target devices

## 📞 Getting Help

If you encounter issues during testing:
1. Check the console logs for error messages
2. Verify Firebase configuration
3. Ensure all dependencies are properly installed
4. Check network connectivity and API limits
5. Review the code for any missing implementations

## Next Steps After Testing
1. **Bug Fixes**: Address any issues found during testing
2. **Performance Optimization**: Improve any slow operations
3. **UI/UX Polish**: Enhance user experience based on testing feedback
4. **Unit Tests**: Add automated tests for critical functionality
5. **Integration Tests**: Create end-to-end automated test scenarios
