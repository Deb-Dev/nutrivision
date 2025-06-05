# NutriVision App UX Flow (Logged-in User)

This document describes the user experience flow for logged-in users with saved preferences in the NutriVision app.

## Main Entry Point

After login, users with completed profiles are directed to the `MainTabNavigator`, which provides five main tabs:

1. **Home Tab**
2. **Log Meal Tab**
3. **Stats Tab**
4. **Goals Tab**
5. **Profile Tab**

## Home Screen Flow

The Home tab serves as the dashboard and main entry point:

- **Daily Summary**: Displays consumed calories, protein, carbs, fat for current day
- **Progress Cards**: Visual representations of daily nutritional goals progress
- **Recent Meals**: Shows recently logged meals with quick access to details
- **Quick Actions**: Buttons for logging meals, viewing suggestions
- **Navigation**: From Home, users can directly access:
  - AI Photo Meal Logging
  - Manual Meal Logging
  - Meal Suggestions
  - Meal History

## Meal Logging Flow

Users can log meals through two primary methods:

### AI Photo Recognition Flow:
1. **Log Tab** → **AI Photo Recognition** option
2. User takes photo of meal or selects from gallery
3. AI processes and identifies food items
4. **Confirmation Screen**: User adjusts portions, adds/removes items
5. Meal is saved to database and reflected in daily totals

### Manual Food Search Flow:
1. **Log Tab** → **Search Foods** option
2. User searches for foods in database
3. User adds foods to meal, adjusts portions
4. User saves meal, which updates daily totals

## Nutritional Analysis Flow

The Stats tab provides analytical insights:

1. **Main Analytics Screen**: Displays summary metrics
2. **Period Selection**: User can choose daily, weekly, monthly views
3. **Tab Navigation**:
   - **Overview**: General nutritional balance
   - **Nutrients**: Detailed breakdown of macro/micronutrients
   - **Trends**: Progress graphs and patterns
4. User can tap on any chart for more detailed information

## Goals Management Flow

The Goals tab allows users to set and monitor nutritional targets:

1. **Goals Overview**: Lists all active nutritional goals
2. **Add Goal**: User can create new nutritional targets
   - Set macronutrient targets
   - Define time periods
   - Establish calorie goals
3. **Edit Goal**: Modify existing goals
4. **Delete Goal**: Remove unwanted goals
5. **Goal Progress**: Visual indicators of progress toward each goal

## Profile & Settings Flow

The Profile tab manages user information and preferences:

1. **User Information**: Display name, photo, basic stats
2. **Dietary Preferences**: Access to modify dietary restrictions and preferences
3. **Account Settings**: Password, notification preferences
4. **Data Management**: Export data, delete history
5. **Sign Out**: Log out of the application

## Cross-Screen Interactions

Several interactions span multiple screens:

- **Meal History Access**: Available from Home screen and Profile
- **Quick Log**: Floating action button available throughout app
- **Goal Progress**: Visible on both Home and Goals screens
- **Favorites**: Meals can be favorited from any meal detail view and accessed from Log Meal tab

## Advanced Features Flow

- **Meal Favorites**: User can save favorite meals for quick logging
- **Meal History**: View, edit or delete previously logged meals
- **Weekly/Monthly Reports**: Generate nutrition reports over time periods
- **Meal Suggestions**: Get AI-powered meal recommendations based on goals and preferences

This UX flow document outlines the primary navigation paths for logged-in users with saved preferences in the NutriVision app.
