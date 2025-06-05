# Epic 4: Advanced Meal Management ⚙️

> **Status**: 100% Complete (June 5, 2025)  
> **Priority**: High - Enhanced user experience  
> **ETA**: Completed on June 4, 2025

## 📊 Implementation Status

| User Story | Status | Implementation Notes |
|------------|--------|---------------------|
| 4.1 Meal History Viewing & Editing | ✅ Complete | All functionality implemented |
| 4.2 Nutritional Goal Tracking | ✅ Complete | All functionality implemented |
| 4.3 Weekly/Monthly Reports | ✅ Complete | All functionality implemented |
| 4.4 Meal Favorites & Quick Log | ✅ Complete | All functionality implemented |

## 🎯 Current Focus (June 5, 2025)

### Completed Milestones ✅
- **Firebase Integration**: Implemented subcollections for efficient data storage
- **State Management**: Fully centralized Riverpod providers for all advanced meal management features
- **UI Implementation**: Built complete UI for all meal management screens
- **Data Flow**: Connected all repositories with proper error handling
- **Performance**: Optimized database queries and data caching for meal history
- **Testing**: Implemented unit tests for all core entities and repositories
- **Bug Fixes**: Fixed nutrition goal tracking not reflecting actual food consumption (June 5, 2025)
- **UX Enhancement**: Added ability to save logged meals as favorites directly from meal details (June 5, 2025)

### Transition to Epic 5 (Smart Meal Planning) 🚀
- [ ] Document Epic 4 lessons learned for team knowledge base
- [ ] Conduct user feedback sessions on Advanced Meal Management features
- [ ] Begin planning user stories for Epic 5
- [ ] Prepare architecture diagrams for Smart Meal Planning
- [ ] Evaluate necessary Firebase extensions and AI requirements for Epic 5

---

## Original User Stories
Phase 3: Advanced Personalization & Coaching
Epic 4: Personalized Meal Planning (LLM-Powered)
User Story 4.1: Generate Weekly Meal Plan
As a user,
I want to be able to request and receive a 7-day personalized meal plan (e.g., for breakfast, lunch, dinner) tailored to my profile (dietary goals, calorie/macro targets, preferences, allergies, restrictions),
So that I have a structured, actionable plan to follow for healthy eating.

Product Requirements:

User action to request a new weekly meal plan (e.g., "Generate My Plan").

The plan should cover 7 days, with distinct meal suggestions for breakfast, lunch, and dinner (snacks optional, configurable).

Meals must strictly adhere to user's allergies and strongly consider restrictions/preferences.

The overall daily nutritional values (calories, macros) of the planned meals should align closely with the user's calculated targets.

Aim for variety in meal suggestions across the week to prevent boredom.

Display the plan in an easy-to-read, day-by-day format.

Option to regenerate the plan or parts of it.

Technical Requirements:

Front-end: UI to request plan generation, display the weekly plan (e.g., daily cards, expandable sections).

Back-end:

API endpoint for meal plan generation.

Retrieve comprehensive user profile: goals, calorie/macro targets, preferences (vegan, keto etc.), allergies, restrictions.

LLM Integration (GPT-4 via API):

Craft detailed prompts for the LLM. Prompt should include: daily calorie/macro targets, number of meals, list of allergies (critical for exclusion), dietary preferences, desired variety, request for meal names and ideally key ingredients.

Request structured output from LLM if possible (e.g., JSON array of days, each with meals, each meal with name and ingredients).

Post-processing of LLM output:

Validate LLM suggestions against allergies again (critical safety check).

Map suggested meal components/ingredients to the food database to get accurate nutritional data.

Adjust/iterate if the LLM plan doesn't meet nutritional targets or violates constraints. This might involve further LLM calls or rule-based adjustments.

Database: Store generated meal plans associated with the user: MealPlans collection (userId, planId, startDate, days (array of daily plans), dailyAverageNutrition). Each day contains meals, and each meal contains mealName, ingredients (array: foodItem, quantity), calculatedNutrition.

Acceptance Criteria:

A 7-day meal plan is generated upon request.

All meals are strictly consistent with the user's specified allergies.

Meals align well with preferences and dietary style (e.g., vegan meals for a vegan user).

The plan's daily average nutritional values are within an acceptable range (e.g., +/- 10%) of the user's targets.

The plan is displayed clearly and is understandable.

The generation process handles LLM errors or unsatisfactory outputs gracefully (e.g., offers to try again).

User Story 4.2: View and Interact with Meal Plan Details
As a user,
I want to be able to tap on any meal in my generated plan to view its details, including a list of ingredients, simple preparation instructions (if provided by LLM), and its nutritional information,
So that I know what to buy and how to prepare the meals, and can decide if I want to eat it.

Product Requirements:

Tapping a meal in the plan opens a detail view.

Display: Meal name, list of ingredients with quantities.

Display concise preparation steps (if LLM provided and deemed reliable).

Detailed nutritional information for that specific meal (calories, P/C/F, key micronutrients).

Option to "Log this meal now" (pre-fills the logger with the meal's ingredients).

Option to "Swap this meal" for an alternative (see next story).

Option to mark a meal as "eaten" directly from the plan.

Technical Requirements:

Front-end: UI for displaying meal details.

Back-end: Ensure LLM prompts for meal generation also request key ingredients and simple instructions. Store this structured data with the meal plan. The "Log this meal" functionality would leverage the existing meal logging system.

LLM: Prompt engineering to request ingredients and concise, actionable instructions.

Acceptance Criteria:

User can view detailed ingredients and quantities for each planned meal.

Simple preparation instructions are shown if available and make sense.

Accurate nutritional info for the specific meal is displayed.

User can easily log a planned meal or mark it as eaten.

User Story 4.3: Adaptive Meal Suggestions (Swap/Replace in Plan)
As a user,
If I don't like a suggested meal in my plan, or if I have different ingredients on hand,
I want to be able to request an alternative suggestion for that specific meal slot that still fits my dietary profile and daily nutritional targets,
So that my meal plan remains flexible and enjoyable.

Product Requirements:

"Swap meal" or "Get alternative" button/option for each meal in the plan.

The new suggestion should adhere to all allergies, preferences, and attempt to match the original meal's approximate calorie/macro contribution to the day.

The plan should update with the new swapped meal.

(Future: System learns from swaps to improve future full-plan generations).

Technical Requirements:

Front-end: UI for requesting a swap and displaying the alternative.

Back-end:

API endpoint for a single meal swap.

Call LLM again with constraints for a single meal replacement. Prompt should include: original meal's target nutrition, user's full dietary profile (allergies are paramount), context of other meals that day (to maintain daily balance), and potentially "don't suggest [original meal type] again" or "something with [specific ingredient user has]".

Validate and process the LLM's suggestion similarly to full plan generation.

Database: Update the stored meal plan with the swapped meal.

Acceptance Criteria:

User can request and receive a suitable alternative for any planned meal.

The alternative respects all dietary constraints and broadly aligns with nutritional goals for that meal slot.

The meal plan view updates correctly with the swapped meal.

User Story 4.4: Generate Aggregated Grocery List from Meal Plan
As a user,
Once I have a weekly meal plan (or a selection of days from it),
I want to automatically generate an aggregated grocery list for all the ingredients needed,
So that I can easily and efficiently shop for my planned meals.

Product Requirements:

Button to "Generate Grocery List" from the meal plan view (e.g., for the whole week, or selected days).

The list should consolidate identical ingredients and sum their quantities (e.g., "Chicken Breast - 500g" instead of multiple small entries).

Intelligently group items by common grocery store categories (e.g., Produce, Meat & Poultry, Dairy & Alternatives, Pantry Staples, Frozen).

Allow users to check off items they already have or have purchased.

Option to manually add items to the list.

Option to share/export the list (e.g., as text).

Technical Requirements:

Front-end: UI to display and interact with the categorized, aggregated grocery list.

Back-end:

API endpoint to generate the grocery list.

Logic to parse all ingredients and their quantities from the selected meal plan days.

Standardize ingredient names (e.g., "apple" vs "red apple" might need mapping or rely on LLM consistency).

Aggregate quantities, converting units where necessary and sensible (e.g., 2 x 1/2 cup to 1 cup).

Implement categorization logic (can be rule-based using keywords in ingredients, or potentially assisted by LLM).

Database: Meal plan data must include detailed ingredients with standardized names and quantities/units.

Acceptance Criteria:

A consolidated grocery list is accurately generated from the selected meal plan.

Ingredients are correctly aggregated and summed.

Items are reasonably categorized for easier shopping.

User can interact with the list (check off, add items).