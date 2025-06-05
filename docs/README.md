# NutriVision - LLM Context Guide

This document provides a comprehensive overview of the NutriVision project for AI assistants and developers working on the codebase.

## 📋 Project Overview

**NutriVision** is a Flutter-based nutritional tracking app with AI-powered food recognition capabilities. Users can take photos of their meals, and the app uses Google Gemini AI to identify food items and estimate nutritional content.

## 🎯 Current Status (May 25, 2025)

### ✅ Completed Features
- ✅ User Authentication (Firebase Auth)
- ✅ Profile Setup & Onboarding
- ✅ Manual Meal Logging
- ✅ Basic Dashboard
- ✅ AI Photo Analysis (Google Gemini)
- ✅ AI Food Recognition & Parsing
- ✅ Meal Confirmation & Saving

### 🚧 Current Epic: AI-Powered Photo Meal Logging
**Status**: ~90% Complete - Core functionality working, fixing edge cases

**Recent Fixes (May 25, 2025)**:
- ✅ Fixed Gemini AI initialization crashes
- ✅ Fixed JSON parsing mismatches between API response and model
- ✅ Fixed Firestore serialization errors for saving meals
- ✅ Enhanced error logging throughout the AI pipeline

### 🔄 Next Up
- Meal history viewing and editing
- Nutritional goal tracking
- Advanced meal planning features

## 📁 Documentation Structure

```
docs/
├── README.md (this file)           # Main LLM context guide
├── planning/
│   ├── user-stories.md            # Complete user story breakdown
│   ├── completed-epics.md          # Finished features & epics
│   └── current-epic.md             # Active development work
├── architecture/
│   ├── system-design.md            # High-level architecture
│   ├── modern-architecture.md      # Clean architecture patterns
│   ├── uml-diagrams.md            # Class diagrams & relationships
│   └── architecture-status.md      # Current implementation status
└── implementation/
    ├── changelog.md                # Detailed change history
    ├── testing-guide.md           # Testing strategies & docs
    └── setup-guide.md             # Development setup instructions
```

## 🏗️ Architecture

**Pattern**: Clean Architecture with Feature-based modules
**State Management**: Riverpod
**Backend**: Firebase (Auth, Firestore, Remote Config)
**AI Service**: Google Gemini Vision API

### Key Directories:
```
lib/
├── core/                          # Shared utilities, DI, base classes
├── features/
│   ├── auth/                     # Authentication & user management
│   ├── ai_meal_logging/          # 🎯 Current focus - AI photo analysis
│   ├── meal_logging/             # Manual meal entry
│   └── dashboard/                # Main app dashboard
└── services/                     # Global services (legacy food DB, etc.)
```

## 🔧 Current Implementation Status

### AI Meal Logging Pipeline (Current Focus)
1. **Photo Capture** ✅ - Camera integration working
2. **AI Analysis** ✅ - Gemini Vision API integration complete
3. **Response Parsing** ✅ - JSON transformation & model mapping fixed
4. **Meal Confirmation** ✅ - User can edit recognized items
5. **Firestore Save** ✅ - Serialization issues resolved
6. **Error Handling** ✅ - Comprehensive logging added

### Recent Critical Fixes:
- **May 25**: Fixed `NotInitializedError` in AI service initialization
- **May 25**: Resolved API response field name mismatches (snake_case vs camelCase)
- **May 25**: Fixed Firestore serialization for complex nested objects

## 🐛 Known Issues & Considerations

### Resolved Issues:
- ~~AI service initialization crashes~~ ✅ Fixed
- ~~JSON parsing failures between Gemini API and Freezed models~~ ✅ Fixed  
- ~~Firestore serialization errors with `_$ConfirmedMealItemImpl`~~ ✅ Fixed

### Current Considerations:
- Confidence threshold tuning for food recognition
- Handling edge cases in food item parsing
- Optimizing API calls and response times

## 📝 For LLM Assistants

### When working on this codebase:

1. **Check Current Status**: Always refer to `docs/implementation/changelog.md` for latest changes
2. **Follow Architecture**: Use the established Clean Architecture patterns in `lib/features/`
3. **AI Integration**: The Gemini AI service is in `lib/features/ai_meal_logging/data/services/`
4. **Error Handling**: Use comprehensive logging - see recent implementations for patterns
5. **Testing**: Check `docs/implementation/testing-guide.md` for testing strategies

### Key Files to Understand:
- `lib/features/ai_meal_logging/domain/entities/ai_meal_recognition.dart` - Core data models
- `lib/features/ai_meal_logging/data/services/gemini_ai_service.dart` - AI integration
- `lib/features/ai_meal_logging/data/repositories/ai_meal_logging_repository_impl.dart` - Data persistence

### Common Tasks:
- **Adding Features**: Follow the feature-based structure in `lib/features/`
- **Fixing Bugs**: Check error logs and add comprehensive logging
- **AI Updates**: Modify prompts and parsing in `gemini_ai_service.dart`
- **UI Changes**: Flutter screens are in each feature's `presentation/` folder

## 🚀 Quick Start for Development

1. **Setup**: See `docs/implementation/setup-guide.md`
2. **Current Work**: Check `docs/planning/current-epic.md`
3. **Run App**: Use VS Code task "Run NutriVision" or `flutter run`
4. **Testing**: `flutter test` or see testing guide

---

**Last Updated**: May 25, 2025
**Current Version**: 2.0.3
**Next Milestone**: Complete AI Meal Logging Epic (95% done)
