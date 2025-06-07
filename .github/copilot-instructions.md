<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## 🤖 Context & Documentation
**START HERE**: Always begin by reading `LLM_CONTEXT.md` for immediate project understanding and current status.
Ask me to run the app when you need. Do not run it yourself.

### Required Reading Order:
1. **Quick Context**: `LLM_CONTEXT.md` - Project overview, current status
2. **Implementation Status**: `docs/PROJECT_STATUS.md` - Real-time progress dashboard and next goals  
3. **Architecture Guide**: `docs/architecture/uml-diagrams.md` - Visual codebase roadmap and data flow
4. **Current Work**: `docs/planning/current-epic.md` - Active Epic 4 (Advanced Meal Management) details

### Documentation Structure:
- `docs/README.md` - Complete LLM context guide
- `docs/IMPLEMENTATION_ROADMAP.md` - Visual progress and priority matrix
- `docs/planning/` - User stories, epics, and planning docs
- `docs/architecture/` - System design, UML diagrams, architecture status  
- `docs/implementation/` - Changelog, setup guide, testing docs

## 🏗️ Architecture & Code Standards
**Clean Architecture**: Follow feature-based modules in `lib/features/` - each feature has domain/data/presentation layers.

**Current Focus Area**: `lib/features/advanced_meal_mgmt/` (85% complete - feature almost complete)

### Key Technical Patterns:
- **State Management**: Riverpod for state management
- **Data Models**: Freezed + json_annotation for immutable models
- **Dependency Injection**: Injectable + GetIt
- **Error Handling**: Comprehensive logging with safeCall() pattern
- **API Integration**: Repository pattern with service classes

## 📝 Change Management
- **Always update**: `docs/implementation/changelog.md` when making changes
- **Architecture changes**: Update `docs/architecture/uml-diagrams.md` if modifying structure
- **Epic progress**: Update `docs/planning/current-epic.md` when completing features

## 🎯 Current Development Guidelines (June 2025)
### Smart Meal Planning (Epic 5 - Active Development):
- **CRITICAL**: Minimize AI API calls (Gemini) to reduce costs
- Implement resource-conscious design
### Code Quality:
- Follow established patterns from `lib/features/ai_meal_logging/` for new features
- Use Clean Architecture with domain/data/presentation layers
- Implement proper error handling and logging throughout
- Break up long files into smaller, manageable components
- **Resource Management**: Always be conscious of expensive external API calls (AI services)

### AI Usage Guidelines:
- **Gemini API**: Use sparingly - max 1 call per user request for meal suggestions
- **Fallback Strategy**: Always provide quality fallback options without AI when possible
- **Caching**: Implement aggressive caching for AI-generated content
- **Cost Monitoring**: Log AI usage and avoid redundant calls

### External Resources:
- Use Perplexity for Firebase/Firestore latest documentation
- Check latest library documentation before implementing features
- Validate Firebase integration patterns with current best practices

## 🚀 Development Workflow
1. Check `LLM_CONTEXT.md` for current project status
2. Review `docs/PROJECT_STATUS.md` for what needs attention
3. Look at current epic in `docs/planning/current-epic.md`  
4. Follow established patterns in `lib/features/ai_meal_logging/` for new Epic 4 features
5. Update changelog and relevant docs when making changes

## ⚠️ Important Notes
- **Current Version**: 2.1.6 (as of May 27, 2025)
- **Ready for**: Beta testing (Epic 4 nearly complete)
- **Next Epic**: Smart Meal Planning (Epic 5) - planning phase starting
- **Architecture Status**: Clean Architecture fully implemented