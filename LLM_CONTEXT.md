# 🤖 LLM Quick Context

> **Start here for AI assistants working on NutriVision**

## 📱 What is this project?
Flutter app for nutrition tracking with AI photo recognition using Google Gemini.

## 🎯 Current Status (June 5, 2025)
- **Version**: 2.2.1 - Bug Fixes & Feature Completion
- **Overall**: 98% complete, beta testing in progress
- **Latest**: Fixed nutrition goal tracking and completed meal favorites functionality
- **Recent completion**: Advanced meal management (Epic 4), Dashboard UX refinement, Typography system
- **Font System**: Interactive font selection with live preview across entire app
- **Ready for**: Enhanced user customization and UI polish before Epic 5
- **Next**: Smart Meal Planning (Epic 5) preparation

## 🗺️ Codebase Roadmap

```
NutriVision/
├── 🏗️ Core Infrastructure (COMPLETE)
│   ├── lib/core/
│   │   ├── di/injection.dart              # Dependency injection setup
│   │   ├── error/failures.dart           # Error handling patterns
│   │   ├── utils/base_repository.dart     # Repository base class
│   │   └── utils/environment.dart         # Configuration management
│   │
├── 🎨 Features (Clean Architecture)
│   ├── 🔐 auth/ (COMPLETE)                # Authentication & user management
│   │   ├── domain/entities/user.dart
│   │   ├── data/repositories/auth_repository_impl.dart
│   │   └── presentation/signin_screen.dart
│   │
│   ├── 🤖 ai_meal_logging/ (COMPLETE) ✅   # AI photo recognition & logging
│   │   ├── domain/
│   │   │   ├── entities/ai_meal_recognition.dart     # 📋 Core data models
│   │   │   └── repositories/ai_meal_logging_repository.dart
│   │   ├── data/
│   │   │   ├── services/gemini_ai_service.dart       # 🧠 AI integration
│   │   │   └── repositories/ai_meal_logging_repository_impl.dart # 💾 Firestore
│   │   └── presentation/
│   │       ├── ai_photo_meal_screen.dart             # 📷 Photo capture
│   │       └── ai_meal_confirmation_screen.dart      # ✅ Confirmation UI
│   │
│   ├── 📊 advanced_meal_mgmt/ (85% DONE) ⭐ CURRENT FOCUS # Meal history & analytics
│   │   ├── domain/
│   │   │   ├── entities/meal_history.dart          # 📋 History models
│   │   │   └── repositories/meal_history_repository.dart
│   │   ├── data/
│   │   │   ├── models/meal_history_model.dart       # 💾 Serialization
│   │   │   └── repositories/meal_history_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/meal_history_screen.dart     # 📊 History view
│   │       └── screens/nutritional_goals_screen.dart # 🎯 Goals UI
│   │
│   ├── 📝 meal_logging/ (COMPLETE)        # Manual meal entry
│   └── 📊 dashboard/ (COMPLETE)           # Main dashboard
│
└── 🔧 Services & Config (COMPLETE)
    ├── services/food_database_service.dart  # Legacy food DB
    ├── firebase_options.dart                # Firebase config
    └── main.dart                            # App entry point
```

## 🔄 Advanced Meal Management Flow (Current Focus)

```
📱 User Journey:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ � View     │ ➤  │ ✏️ Edit     │ ➤  │ 🎯 Track    │ ➤  │ � Analyze  │
│ History     │    │ Past Meals  │    │ Goals       │    │ Progress    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘

🔧 Technical Implementation Plan:
1. meal_history_screen.dart           # Display past logged meals
2. meal_edit_screen.dart             # Edit existing meal entries
3. nutrition_goals_service.dart      # Goal setting & tracking
4. meal_analytics_screen.dart        # Weekly/monthly reports
5. meal_favorites_repository.dart    # Quick-log favorite meals
```

## 🎯 Data Flow Architecture

```
📱 Presentation Layer
    ↕️ (Riverpod State Management)
🏢 Domain Layer (Entities + Use Cases)
    ↕️ (Repository Interfaces)
💾 Data Layer (Repositories + Services)
    ↕️ (External APIs)
🌐 External Services (Firebase, Gemini AI)
```

## 🔑 Key Files to Understand

| Priority | File | Purpose | Status |
|----------|------|---------|--------|
| 🔥 HIGH | `meal_history_screen.dart` | View past logged meals | 🔄 To Build |
| 🔥 HIGH | `meal_edit_repository.dart` | Edit existing meal entries | 🔄 To Build |
| 🔥 HIGH | `nutrition_goals_service.dart` | Goal setting & tracking | 🔄 To Build |
| 🟡 MED | `meal_analytics_screen.dart` | Weekly/monthly reports | 📅 Planning |
| 🟡 MED | `meal_favorites_repository.dart` | Quick-log favorite meals | 📅 Planning |

## ✅ What Works Right Now
```
� Auth → 📝 Manual Logging → 📸 AI Photo Analysis → 🍎 Food Recognition →  Firestore Save → 📊 Dashboard
```

## 🚧 What Needs Work (Epic 4)
- **Meal History**: View and edit past logged meals
- **Goal Setting**: Define and track nutritional targets
- **Analytics**: Weekly/monthly progress reports
- **Favorites**: Quick-log frequently eaten meals

## 🛠️ Tech Stack Quick Reference

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Flutter + Dart | Cross-platform mobile app |
| **State** | Riverpod | State management |
| **Architecture** | Clean Architecture | Feature-based modules |
| **Backend** | Firebase | Auth, Firestore, Remote Config |
| **AI** | Google Gemini Vision | Food recognition |
| **Models** | Freezed + json_annotation | Immutable data classes |
| **DI** | Injectable + GetIt | Dependency injection |

## 🔍 For Complete Context
- **Full Project Overview**: [`docs/README.md`](docs/README.md)
- **Implementation Status**: [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)
- **Architecture Details**: [`docs/architecture/modern-architecture.md`](docs/architecture/modern-architecture.md)

---
**🎯 TLDR**: Epic 3 (AI meal logging) is complete! Now focusing on Epic 4 (Advanced Meal Management) - `lib/features/advanced_meal_mgmt/` needs to be built!
