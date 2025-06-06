# 🤖 LLM Quick Context

> **Start here for AI assistants working on NutriVision**

## 📱 What is this pr## 🔑 Key Files to Understand

| Priority | File | Purpose | Status |
|----------|------|---------|--------|
| 🔥 HIGH | `smart_meal_planning/domain/entities/` | Core domain entities | ✅ Implemented |
| 🔥 HIGH | `smart_meal_planning/domain/repositories/` | Repository interfaces | ✅ Implemented |
| 🔥 HIGH | `smart_meal_planning/domain/usecases/` | Business logic | ✅ Implemented |
| 🔥 HIGH | `smart_meal_planning/data/models/` | Data serialization | ✅ Implemented |
| 🔥 HIGH | `smart_meal_planning/data/repositories/` | Repository implementations | ✅ Implemented |
| � HIGH | `smart_meal_planning/presentation/providers/` | State management | ✅ Implemented |
| 🔥 HIGH | `smart_meal_planning/presentation/screens/` | UI interfaces | 🔄 In Progress |Flutter app for nutrition tracking with AI photo recognition using Google Gemini.

## 🎯 Current Status (June 5, 2025)
- **Version**: 2.2.2 - Major progress in Smart Meal Planning implementation
- **Overall**: 60% complete for Epic 5, significant advancement in core functionality
- **Latest**: Fixed code generation issues, added table_calendar dependency, enhanced repository implementations
- **Fully Completed**: Advanced meal management (Epic 4) with interactive nutrition visualization and favorites
- **Recent Features**: Resolved freezed compilation errors, improved provider implementations, enhanced UI screens
- **Current Focus**: Finalizing Smart Meal Planning implementation and dependency injection setup
- **Next**: Complete remaining error fixes, implement AI integration, and add comprehensive testing

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
│   ├── 📊 advanced_meal_mgmt/ (COMPLETE) ✅         # Meal history & analytics
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
│   ├── 🍽️ smart_meal_planning/ (IN PROGRESS) 🚧      # Smart meal planning
│   │   ├── domain/
│   │   │   ├── entities/meal_plan.dart             # 📋 Core planning models (✅ Complete)
│   │   │   └── repositories/meal_plan_repository.dart # Repository interfaces (✅ Complete)
│   │   ├── data/ 
│   │   │   ├── models/                             # 💾 Serialization (✅ Complete)
│   │   │   └── repositories/                       # Repository implementations (✅ Complete)
│   │   └── presentation/ 
│   │       ├── screens/                            # Planning screens (🔄 80% Complete)
│   │       ├── providers/                          # State management (✅ Complete)
│   │       └── widgets/                            # Planning UI components (🔄 Planning)
│   │
│   ├── 📝 meal_logging/ (COMPLETE)        # Manual meal entry
│   └── 📊 dashboard/ (COMPLETE)           # Main dashboard with interactive charts
│
└── 🔧 Services & Config (COMPLETE)
    ├── services/food_database_service.dart  # Legacy food DB
    ├── firebase_options.dart                # Firebase config
    └── main.dart                            # App entry point
```

## 🔄 Smart Meal Planning Flow (New Focus)

```
📱 Planned User Journey:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 🧠 Get AI   │ ➤  │ 📅 Plan     │ ➤  │ 🛒 Generate │ ➤  │ 📊 Track    │
│ Suggestions │    │ Meals       │    │ Grocery List│    │ Adherence   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘

🔧 Technical Implementation Plan:
1. meal_suggestion_service.dart       # AI-powered meal suggestions
2. meal_planning_screen.dart          # Weekly meal calendar interface
3. grocery_list_generator.dart        # Shopping list creation
4. diet_plan_integration.dart         # Integration with diet plans
5. plan_adherence_tracker.dart        # Tracking meal plan compliance
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
| 🔥 HIGH | `smart_meal_planning/` | New feature directory | � Planning |
| 🔥 HIGH | `meal_suggestion_service.dart` | AI-powered suggestions | � Planning |
| 🔥 HIGH | `meal_planning_screen.dart` | Weekly calendar UI | � Planning |
| 🟡 MED | `grocery_list_generator.dart` | Shopping list creation | 📅 Planning |
| 🟡 MED | `diet_plan_integration.dart` | Diet plan integration | 📅 Planning |

## ✅ What Works Right Now
```
� Auth → 📝 Manual Logging → 📸 AI Photo Analysis → 🍎 Food Recognition → Firestore Save → 📊 Interactive Dashboard
→ 📝 Meal History → 🎯 Goal Tracking → 📊 Analytics → ⭐ Favorites
```

## 🚧 What Needs Work (Epic 5)
- **AI Meal Suggestions**: Generate personalized meal suggestions
- **Custom Meal Planning**: Calendar-based meal scheduling
- **Grocery List Generation**: Create shopping lists from meal plans
- **Diet Plan Integration**: Connect to predefined diet plans

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
| **Visualization** | FL Chart | Interactive nutrition charts |

## 🔍 For Complete Context
- **Full Project Overview**: [`docs/README.md`](docs/README.md)
- **Implementation Status**: [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)
- **Architecture Details**: [`docs/architecture/modern-architecture.md`](docs/architecture/modern-architecture.md)
- **Smart Meal Planning**: [`docs/planning/epic5-smart-meal-planning.md`](docs/planning/epic5-smart-meal-planning.md)

---
**🎯 TLDR**: Epic 4 (Advanced Meal Management) is complete! Now focusing on Epic 5 (Smart Meal Planning) - building the AI-based meal planning system!
