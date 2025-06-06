# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Smart Meal Planning**: Major progress in Epic 5 implementation
  - Created domain entities for meal plans, meal suggestions, grocery lists, and diet plans
  - Implemented repository interfaces for core meal planning operations
  - Added initial use cases for meal suggestions, meal plan creation, and grocery list generation
  - Established core data structures for AI-powered meal planning
  - Implemented data models with Firestore serialization for all core entities
  - Created repository implementations for meal plan, meal suggestion, and grocery list operations
  - Added presentation layer with Riverpod state management providers
  - Implemented UI screens for meal suggestions, meal planning, and grocery lists
  - Added navigation and dependency injection setup
  - Successfully ran code generation for all freezed entities
  - Added table_calendar dependency for meal planning calendar interface
  - Enhanced providers with data loading capabilities for meal plans and grocery lists

### Optimized
- **Resource Management**: Critical cost optimization for AI API usage (June 6, 2025)
  - **MAJOR FIX**: Reduced Gemini API calls from 5 per request to 1 per request (80% cost reduction)
  - Implemented direct fallback meal generation to avoid unnecessary AI service calls
  - Added resource-conscious meal suggestion logic: 1 AI + 4 fallback suggestions per request
  - Enhanced meal suggestion service to respect 'requestType' parameter for cost control
  - Added comprehensive fallback meal databases for breakfast, lunch, dinner with variety
  - Updated Copilot instructions to emphasize resource-conscious AI usage guidelines
  - Fixed enum usage error (SuggestionSource.manual → SuggestionSource.personalized)

### Fixed
- **Code Generation**: Resolved freezed entity compilation issues
  - Fixed missing generated files by running build_runner
  - Addressed Either/Future return type issues in repository implementations
  - Resolved compile errors in domain entities and data models
  - Fixed provider method signatures and dependency injection setup
- **Smart Meal Planning**: Resolved all remaining compile and type errors
  - Fixed NutritionalSummary type mismatches across domain and data layers
  - Added missing `order` field to GroceryCategory entity and model
  - Corrected repository implementation return types to match interfaces
  - Fixed dependency injection configuration in GetIt and Riverpod providers
  - Resolved method signature mismatches in meal suggestion repository
  - Cleaned up unused imports and variables throughout the module
  - Fixed duplicate class definitions in authentication wrapper
  - **Result**: Smart Meal Planning feature now compiles cleanly with only minor lint warnings
- **Smart Meal Planning**: Fixed critical meal suggestion issues (June 6, 2025)
  - Fixed type error in fallback meal generation causing crash: `_Map<String, num>` vs `Map<String, double>`
  - Added proper type conversion for nutritional values in meal suggestions
  - Enhanced caching with local in-memory cache to reduce redundant API calls
  - Fixed duplicate API requests for the same meal type in meal planning screen
  - Improved error handling in meal suggestion generation with better fallback handling
  - Reduced API costs by optimizing request flows and preventing duplicate calls
  - Added better logging for AI-generated meal suggestions

## [2.2.2] - 2025-06-05

### Changed
- **Epic Transition**: Completed transition from Epic 4 to Epic 5
  - Updated all project documentation to reflect Epic 4 completion
  - Finalized Epic 5 planning documents and technical specifications
  - Updated roadmap and implementation timelines for Smart Meal Planning
  - Prepared codebase for Epic 5 feature development

### Added
- **Technical Documentation**: Created comprehensive planning documents for Epic 5
  - Added detailed technical specification for meal planning features
  - Created lessons learned document from Epic 4 implementation
  - Defined data models and architecture for meal planning system
  - Established metrics for tracking Epic 5 success

### Fixed
- **Documentation Consistency**: Ensured all documentation reflects current project status
  - Synchronized status information across all documentation files
  - Corrected status indicators in all project files
  - Updated priority matrices for new development focus
  - Fixed progress indicators in implementation roadmap

## [2.2.1] - 2025-06-05

### Added
- **Interactive Summary Widgets**: Added dynamic nutrition visualization to the dashboard
  - Implemented interactive charts using FL Chart library
  - Added detailed nutrient breakdown with tap interaction
  - Created weekly nutrition tracking visualization
  - Added ability to toggle between daily and weekly views
  - Enhanced macronutrient display with percentage indicators

- **Dashboard Enhancements**: Added quick access to favorites from the dashboard
  - Added "Favorites" card in the More Actions section
  - Integrated with the existing FavoriteMealsScreen for seamless navigation
  - Used consistent styling with other quick action cards

### Fixed
- **UI Layout Issues**: Fixed overflow and compactness problems in the interactive summary section
  - Optimized toggle controls for better space usage with segmented buttons
  - Made all chart components more compact with reduced padding and spacing
  - Improved responsive layout for nutrient indicators to prevent overflow
  - Adjusted text sizes and visual elements for better fit on various screen sizes
  - Fixed Nutrition Breakdown view to better utilize limited screen space
  - Redesigned view toggle system with three distinct view buttons for better UX
  - Improved weekly chart view with clearer day selection controls
  - Fixed blue dotted line appearance in weekly view for better aesthetics

- **Nutritional Goal Tracking**: Fixed issue where consumed nutrients weren't being reflected in goal progress
  - Implemented proper data fetching from meal logs to calculate daily nutrition totals
  - Updated repository interface and implementation to track real-time consumption
  - Added daily meal summary retrieval for accurate progress tracking

- **Meal Favorites System**: Completed the "Add Favorite Meal" functionality
  - Implemented `AddFavoriteMealSheet` widget for creating custom favorite meals
  - Added "Add to Favorites" button to meal detail screen to save logged meals as favorites
  - Fixed loading dialog issue that caused the app to freeze when adding to favorites
  - Added UI feedback showing if a meal is already a favorite
  - Connected interface to backend repository for persistent storage
  - Added nutrition input controls for accurate tracking
  - Fixed "LOG THIS MEAL" button to properly add favorite meals to meal history
  - Added loading indicator while logging meals and navigation to meal history
  - Fixed data structure inconsistencies that caused favorite meals to appear with wrong names and zero nutrition values in meal history
  - Improved meal name handling to ensure favorite meals are consistently named when logged to meal history

## [2.2.0] - 2025-06-04

### Added
- **Centralized Typography System**: Complete overhaul of typography management with Material 3 compliance
  - Implemented `AppTypography` class with 10 Google Fonts: Roboto, Open Sans, Lato, Nunito, Poppins, Inter, Source Serif 4, Playfair Display, Montserrat, and Raleway
  - Added comprehensive text style definitions following Material 3 design guidelines
  - Integrated semantic text hierarchy (display, headline, title, body, label styles)
  
- **Font Experimentation System**: Interactive font selection and preview functionality
  - Created `FontSettingsScreen` for simple font selection with persistence
  - Added `FontDemoScreen` for comprehensive typography showcase and live font previewing
  - Implemented Riverpod-based font state management with SharedPreferences persistence
  - Added dropdown font selector with real-time preview across entire app

- **Global Theme Integration**: Font selection now applies app-wide
  - Updated main app theme to use selected font family for both light and dark modes
  - All screens now consistently use theme-based text styles instead of hardcoded TextStyles
  - Font changes apply immediately across all screens without app restart

### Changed
- **Typography Standardization**: Refactored all screens to use centralized typography
  - Updated 12+ major screens to use `Theme.of(context).textTheme.*` styles
  - Replaced hardcoded font sizes, weights, and colors with semantic theme-based styles
  - Improved accessibility and maintainability through consistent text styling
  
- **Profile Screen**: Added font customization options
  - Added "Font Settings" option for simple font selection
  - Added "Font Demo & Experimentation" option for comprehensive font preview
  - Integrated navigation to new font management screens

### Technical Improvements
- **Theme Providers**: Created reactive theme system with font integration
  - Implemented `appThemeProvider` and `appDarkThemeProvider` for font-aware themes
  - Added `fontFamilyProvider` for persistent font state management
  - Ensured proper theme updates when font selection changes

- **Code Organization**: Enhanced feature-based architecture
  - Created `features/settings/` module for font management
  - Added proper import structure and dependency management
  - Maintained clean architecture principles throughout implementation

## [Unreleased]

### UI/UX Improvements
- **Recent Meals Section**: Completely redesigned Recent Meals cards for better readability and visual appeal
  - Enhanced meal name generation from food items to show actual food names instead of "Unnamed Meal"
  - Implemented robust meal name generation with multiple fallback strategies for both manual and AI meals
  - Added intelligent food name extraction from different data structures (foods, confirmedItems, etc.)
  - Improved meal naming patterns: single items, "A & B" for pairs, "A, B, C" for triplets, "A, B + N more" for larger meals
  - Redesigned card layout with proper spacing, colored meal type chips, and nutrition badges
  - Added visual indicators for AI vs manual meals with proper color coding
  - Improved typography with better contrast and font weights
  - Added meal type colors (orange for breakfast, green for lunch, purple for dinner, blue for snacks)
  - Enhanced calorie and food count display with colored badges
- **Meal Name Consistency**: Unified meal name display throughout the entire app
  - Created shared `MealNameGenerator` utility for consistent meal naming logic
  - Updated home screen, meal history, and meal detail screens to use the unified utility
  - Eliminated generic fallbacks like "Logged Meal", "AI Recognized Meal", and "Unnamed Meal"
  - Ensured all meal displays show meaningful food-based names with proper fallback strategies
  - Added debug logging to help troubleshoot meal name generation issues
- **Nutrition Analytics Screen**: Improved chart spacing and layout for better visual presentation
  - Fixed pie chart spacing issues by restructuring chart containers from flexible Expanded widgets to fixed SizedBox heights
  - Added proper vertical padding above pie charts (24px top padding) to prevent them from being too close to card edges
  - Increased spacing between pie charts and their legends with dedicated SizedBox spacing (16px)
  - Applied consistent spacing improvements to both mobile (160px chart height) and larger screen layouts (200px chart height)
  - Enhanced readability of both Meal Type Distribution and Macronutrient Distribution charts
  - Improved overall visual balance and eliminated cramped appearance by using fixed heights instead of flex layouts
  - Charts now have proper breathing room within their 250px card containers
- **Nutrition Analytics Screen Refactoring**: Successfully refactored large monolithic screen into modular components
  - Split 1100+ line nutrition analytics screen into logical, maintainable components
  - Created separate tab widgets: `OverviewTab`, `TrendsTab`, and `DistributionTab`
  - Extracted shared widgets and utilities into `NutritionAnalyticsWidgets`
  - Improved code organization with feature-based modular structure
  - Maintained all existing functionality while significantly improving maintainability
  - Reduced main screen file from 1100+ lines to ~120 lines focused on coordination
  - Each tab component is now self-contained with its own chart builders and logic
  - Enhanced code reusability with shared period selector and legend components

### Bug Fixes
- **AI Meal Confirmation**: Fixed Total Nutrition card text color consistency - nutrition values now display with proper colors (red for calories, blue for protein, orange for carbs, green for fat) matching other nutrition displays throughout the app
- **Home Screen**: Added missing `_getMealTypeColor` helper method to prevent errors in Recent Meals section
- **Nutrition Analytics Screen UI**: Fixed chart and graph overflow issues throughout the analytics interface
  - Wrapped all charts (line charts and pie charts) in proper Card containers for consistent styling
  - Added responsive layout using LayoutBuilder for both trend charts and distribution pie charts
  - Implemented flexible layout for smaller screens: charts stack vertically with legend below
  - Added proper width/height constraints to prevent charts from overflowing screen boundaries
  - Reduced pie chart radius for better fit on mobile screens (60px vs 80px)
  - Created `_buildWrappedLegendItem` helper for compact legend display on small screens
  - Enhanced Distribution tab with Card containers and increased chart height for better visibility
  - Improved legend layout with Wrap widgets for better text flow and responsiveness
  - Fixed macro distribution chart to use consistent responsive patterns
  - All analytics charts now properly scale and fit within device screen constraints

### Data Consistency Fixes  
- **Meal History Repository**: Fixed critical data loading issue where manual meals were not appearing in meal history screen
  - Corrected manual meal queries to use `timestamp` field instead of `loggedAt` for date filtering
  - Updated `MealHistoryEntry.fromManualMeal` factory to handle both `timestamp` and `loggedAt` fields for maximum compatibility
  - Verified that home screen correctly uses appropriate fields for each meal type (`timestamp` for manual, `loggedAt` for AI)
  - Added comprehensive logging to track meal data loading and processing
- **Meal History Filtering**: Implemented missing sources filter functionality in meal history repository
  - Added logic to conditionally fetch AI meals and/or manual meals based on sources filter selection
  - Fixed filter dialog integration to properly exclude meal types when user selects specific sources
  - Ensured proper null safety handling for filter options
- **Data Model Consistency**: Enhanced meal entry data mapping to handle various field name variations across different meal types
  - Manual meals now consistently use `foods` field for food items and `timestamp` for date
  - AI meals consistently use `confirmedItems` field for food items and `loggedAt` for date  
  - Both meal types properly handle optional fields like `editedAt`, `editCount`, and nutrition data

## [2.1.7] - 2025-05-27

### Bug Fixes
- **AuthFlow**: Fixed issue with profile setup and dietary preference screens showing repeatedly on app launch
- **UserProfile**: Improved UserProfile loading to correctly check profileCompleted flag

### Feature - Modern Home Screen & UI Refinement
- **HomeScreen**: Created modern Material 3 design for home dashboard with card-based layout
- **Daily Progress**: Implemented enhanced visualization for daily nutrition data
- **Recent Meals**: Added quick access to recently logged meals with meal type and time
- **Quick Actions**: Implemented convenient action buttons for meal logging
- **Personalization**: Added time-based greeting messages
- **Visual Enhancements**: Updated progress indicators and macro nutrient displays

### Feature - Modern Tab Bar Navigation
- **MainTabNavigator**: Implemented new tab-based navigation with 5 main sections
- **LogMealHubScreen**: Created central hub for all meal logging methods
- **ProfileScreen**: New unified profile and settings screen
- **TabProvider**: Added centralized state management for tabs
- **Localizations**: Updated with tab-related strings

### Bug Fixes
- **Navigation Flow**: Fixed auth wrapper to properly use tab-based navigation
- **Import Resolution**: Resolved conflicting AuthWrapper imports
- **Localization**: Added missing summaryForDate localization string

### Technical Improvements
- **Navigation Structure**: Moved from card-based navigation to modern tab bar
- **State Management**: Used Riverpod for sharing state between tabs
- **UX Refininement**: Improved overall navigation flow and user experience
- **Documentation**: Updated project docs to reflect UI/UX refinement initiative
- **Code Organization**: Restructured files to follow feature-based modules pattern

### Notes
- Epic 4.5 (Dashboard UX Refinement) now 40% complete
- Next steps include interactive summary widgets and theme switching

## [2.1.6] - 2025-05-26

### Refactor - Firebase Provider Centralization

### Refactor - Firebase Provider Centralization
- **Dashboard Providers**: Updated to use Riverpod Firebase providers instead of direct Firebase instances
- **Authentication Screens**: Converted `signup_screen.dart`, `signin_screen.dart`, `forgot_password_screen.dart` to use Riverpod providers
- **User Profile Screens**: Updated `profile_setup_screen.dart`, `dietary_preferences_screen.dart` to use centralized Firebase providers
- **Meal Logging**: Converted `log_meal_screen.dart`, `enhanced_log_meal_screen.dart`, `ai_meal_confirmation_screen.dart` to ConsumerStatefulWidget
- **Dashboard Screen**: Refactored both old root `dashboard_screen.dart` and feature-based dashboard to use Riverpod providers
- **Auth Wrapper**: Fixed import path to use correct `authStateStreamProvider`
- **Import Consolidation**: Added missing Firebase SDK imports where needed for type definitions while using Riverpod providers for instances

### Technical Improvements
- **State Management**: Converted all affected widgets from StatefulWidget to ConsumerStatefulWidget
- **Dependency Injection**: Replaced `FirebaseAuth.instance` and `FirebaseFirestore.instance` calls with `ref.read(firebaseAuthProvider)` and `ref.read(firebaseFirestoreProvider)`
- **Code Comments**: Added notes about future refactoring needs for static service classes

### Notes
- Epic 4 (Advanced Meal Management) entities still need to be completed - current analysis errors are expected for incomplete feature
- Service classes like `MealSuggestionsService` marked for future refactoring to use dependency injection

## [2.1.5] - 2025-05-28

### Refactor
- **Centralized Core Models**: Moved `MealHistoryEntry`, `FoodItem`, `NutritionalSummary`, `MealSource`, and `MealType` from `lib/features/advanced_meal_mgmt/domain/entities/meal_history.dart` to a new central location at `lib/core/models/meal_models.dart`.
- **Updated Imports**: Modified all relevant files across the `advanced_meal_mgmt` feature and `dashboard_screen.dart` to use the new import path for these core models.
- **Code Generation**: Ran `flutter pub run build_runner build --delete-conflicting-outputs` to update Freezed generated files for the moved models.
- **Lint Fixes**: Resolved lint errors in `meal_history_screen.dart` related to `MealHistoryFilter` import and an unnecessary cast.
- **Enum Consolidation**: Ensured `GoalType` enum remains in `lib/features/advanced_meal_mgmt/domain/entities/meal_history.dart` and removed an accidental duplicate from `lib/core/models/meal_models.dart`.

### Chore
- Deleted the old `lib/meal_history_screen.dart` and its associated `LoggedMeal` model as part of model consolidation.

## [2.1.4] - 2025-05-27

### 🔧 Epic 4 Critical Architecture Fix - Firestore Collection Consistency
- **Fixed Firestore Collection Paths**: Resolved composite index error by standardizing AI meal log collection structure
- **Collection Architecture**: Updated advanced meal management to use `users/{userId}/ai_meal_logs` subcollections instead of top-level `ai_meal_logs`
- **Consistency Alignment**: Aligned Epic 4 with Epic 3 architecture patterns for data isolation and security
- **Performance Optimization**: Eliminated need for composite Firestore indexes by using subcollections

### 🛠️ Technical Improvements
- **Provider Centralization**: Created centralized `currentUserIdProvider` using auth state management
- **Import Cleanup**: Removed duplicate provider definitions across Epic 4 components
- **Query Optimization**: Updated meal history, nutrition analytics, and nutrition goals repositories for efficient subcollection queries
- **JsonKey Annotation Fix**: Corrected JsonKey placement in nutrition analytics entities

### 🚀 Dashboard Integration
- **Advanced Meal Management UI**: Added navigation cards for Epic 4 features in main dashboard
- **Feature Access**: Integrated Nutrition Analytics, Goals & Tracking, Favorite Meals, and Meal Management screens
- **User Experience**: Improved dashboard layout with structured feature sections

### 📊 Epic 4 Status Update
- **Architecture**: ✅ Complete - Clean Architecture with proper collection structure
- **Data Layer**: ✅ Complete - Repository implementations with Firestore subcollections
- **Domain Layer**: ✅ Complete - All entities and use cases implemented
- **Presentation Layer**: ✅ Complete - All screens and providers functional
- **Navigation**: ✅ Complete - Integrated into main dashboard

### 🎯 Ready for Beta Testing
Epic 4 Advanced Meal Management is now architecturally sound and ready for functional testing.

## [2.1.4] - 2025-05-27

### 🏗️ Epic 4 Advanced Meal Management - Major Progress
- **Fixed Firestore Collection Architecture**: Resolved composite index error by fixing collection paths
  - Changed from top-level `ai_meal_logs` collection to proper subcollections `users/{userId}/ai_meal_logs`
  - Eliminated need for composite index by using implicit userId filtering in subcollections
  - Maintained data isolation and improved performance
- **Dashboard Integration**: Successfully integrated Epic 4 features into main dashboard
  - Added "Advanced Meal Management" section with 4 feature cards
  - Added navigation to Nutrition Analytics, Goals & Tracking, Favorite Meals, and Meal Management screens
  - Improved dashboard layout with organized feature sections
- **Provider Integration**: Fixed all `currentUserIdProvider` references across Epic 4 features
  - Centralized user ID provider using auth system
  - Removed duplicate provider definitions
  - Integrated with existing auth architecture
- **UI Components**: All Epic 4 screens are implemented and functional
  - Meal History Screen with filtering and editing capabilities
  - Nutrition Analytics Screen with charts and insights
  - Nutritional Goals Screen with goal setting and tracking
  - Favorite Meals Screen with quick-log functionality

### 🐛 Bug Fixes
- **JsonKey Annotations**: Fixed invalid JsonKey placement in nutrition analytics entities
- **Collection Path Consistency**: Aligned all repositories to use proper Firestore subcollection structure
- **Code Generation**: Regenerated Freezed and JSON serialization code after entity fixes

### 📊 Epic 4 Status Update
- **Implementation**: ~90% Complete
- **Core Features**: All implemented and functional
- **Architecture**: Clean Architecture fully applied
- **Testing**: Ready for functional testing
- **Remaining**: Minor UI polish and edge case handling

## [2.1.3] - 2025-05-27

### ✨ Epic 4 Advanced Meal Management - Implementation Complete
- **Fixed All Compilation Errors**: Resolved all remaining compilation issues in Epic 4 advanced meal management feature
- **Meal Edit Screen**: Fixed repository access pattern to use provider method instead of direct repository access
- **Failure Handling**: Corrected null-aware operator usage with non-nullable Failure.message property
- **Provider Method Signatures**: Updated all provider calls to match repository interface signatures
- **Code Cleanup**: Removed unused imports and orphaned generated files

### 🐛 Bug Fixs  
- **Method Signatures**: Fixed updateMeal method call in meal edit screen to use correct positional parameters
- **Type Safety**: Removed nullable check on non-nullable Failure.message property
- **Import Optimization**: Cleaned up unused nutrition analytics repository import

### 📋 Status Update
- **Epic 4 Progress**: Advanced Meal Management feature now compiles successfully (100% compilation complete)
- **Ready for Testing**: All core functionality implemented and error-free
- **Next Phase**: Ready for functional testing and UI refinements

## [2.1.2] - 2025-05-26

### 🚀 Distribution
- **App Distribution**: Configured Firebase App Distribution for beta testing
- **Fastlane Setup**: Created Fastlane configuration for iOS and Android builds
- **Version Update**: Updated version number to 2.1.2+12 for distribution
- **Distribution Script**: Added helper script for easy build and distribution

### 🐛 Bug Fixes
- **Fixed AI Meal Logging**: Resolved serialization issue causing "Invalid argument: Instance of '_$ConfirmedMealItemImpl'" error
- **Improved Firestore Integration**: Enhanced model conversion in repository implementations for consistent serialization
- **Enhanced Error Handling**: Added detailed logging for serialization operations in meal logging repositories

## [2.1.1] - 2025-05-26

### 🚧 EPIC 4 IN PROGRESS: Advanced Meal Management
**Feature Progress**: Domain layer entities and repositories implemented

### ✅ Completed Components
- **Domain Entities**: Implemented complete entity models for meal history, nutritional goals, and analytics
- **Repository Interfaces**: Defined all repository interfaces with clean architecture principles
- **Data Models**: Created Firestore-compatible data models with serialization support
- **Repository Implementations**: Implemented repository implementations with Firestore integration

### 🔧 Technical Improvements
- Added comprehensive error handling in repository implementations
- Improved domain model consistency between manual and AI meal logs
- Enhanced Firestore serialization with proper type safety
- Implemented proper data transformation between layers

### 🏗️ Architecture Updates
- Followed Clean Architecture patterns for domain/data separation
- Maintained consistent repository pattern across all features
- Ensured proper error handling with Result type returns
- Applied proper dependency injection with Injectable

### 📝 Next Steps
- Implement presentation layer providers
- Create UI screens for meal history viewing and editing
- Develop analytics visualization components
- Build favorite meals quick-logging interface

## [2.1.0] - 2025-05-25 🚀

### 🎉 EPIC 3 COMPLETED: AI-Powered Photo Meal Logging
**Major Milestone**: Complete AI meal logging pipeline functional

### ✅ Completed Features
- **AI Photo Analysis**: Full integration with Google Gemini Vision API
- **Food Recognition**: Structured JSON parsing with confidence scores
- **User Confirmation**: Intuitive editing interface for AI suggestions
- **Firestore Persistence**: Reliable saving of AI-recognized meals
- **Error Recovery**: Comprehensive error handling and retry mechanisms

### 🐛 Critical Fixes
- **Firestore Serialization**: Fixed `Instance of '_$ConfirmedMealltemImpl'` error
- **AI Service Initialization**: Resolved `NotInitializedError` crashes
- **JSON Field Mapping**: Fixed snake_case vs camelCase mismatches
- **Repository Logging**: Added comprehensive debugging throughout pipeline

### 📊 Impact
- Users can now photograph meals and get accurate AI recognition
- End-to-end meal logging flow works seamlessly
- 90% overall project completion achieved
- Ready for beta testing

### 🔧 Technical Improvements
- Enhanced error logging in `ai_meal_logging_repository_impl.dart`
- Fixed JSON serialization in `.g.dart` generated files
- Improved AI service error handling and recovery
- Optimized data flow architecture

### 📚 Documentation Updates
- Epic 3 moved to completed epics
- Epic 4 (Advanced Meal Management) set as current focus
- Updated project status to 90% completion
- Comprehensive documentation restructure completed

## [2.0.4] - 2025-05-25

### Fixed
- **Dashboard AI Meal Integration**: Fixed functional bug where dashboard was not reflecting ai_meal_logs in daily nutritional totals
- Dashboard now properly fetches and combines data from both 'loggedMeals' and 'ai_meal_logs' collections
- AI-logged meals are now correctly included in daily calorie, protein, carbs, and fat calculations
- Enhanced `_calculateConsumptionForDate()` method to handle both manual and AI-assisted meal logging data sources

## [2.0.3] - 2025-05-25

### Fixed
- **Critical Fix**: Resolved Firestore serialization error "Instance of '_$ConfirmedMealltemImpl'" when saving AI-recognized meals
- Fixed JSON serialization in generated Freezed code to properly convert nested objects to JSON maps
- Updated `AIMealLog.toJson()`, `ConfirmedMealItem.toJson()`, `RecognizedFoodItem.toJson()`, and `AIMealRecognitionResult.toJson()` methods
- Enhanced error logging in `logAIMeal()` repository method for better debugging of save operations
- Meals can now be successfully saved to Firestore after AI recognition and confirmation

## [2.0.2] - 2025-05-25

### Fixed
- **Critical Fix**: Resolved `NotInitializedError` in AI Photo Meal Logging screen when clicking analyze

