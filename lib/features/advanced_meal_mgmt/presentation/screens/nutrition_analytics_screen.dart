import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nutrition_analytics_provider.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../../../core/providers/auth_providers.dart';
import '../widgets/nutrition_analytics_widgets.dart';
import '../widgets/overview_tab.dart';
import '../widgets/trends_tab.dart';
import '../widgets/distribution_tab.dart';

class NutritionAnalyticsScreen extends ConsumerStatefulWidget {
  const NutritionAnalyticsScreen({super.key});

  @override
  ConsumerState<NutritionAnalyticsScreen> createState() =>
      _NutritionAnalyticsScreenState();
}

class _NutritionAnalyticsScreenState
    extends ConsumerState<NutritionAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Generate report when screen initializes
    Future.microtask(() {
      final userId = ref.read(currentUserIdProvider);
      ref
          .read(nutritionAnalyticsProvider.notifier)
          .generateReport(userId: userId, period: AnalyticsPeriod.weekly);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changePeriod(AnalyticsPeriod period) {
    final userId = ref.read(currentUserIdProvider);
    ref
        .read(nutritionAnalyticsProvider.notifier)
        .generateReport(userId: userId, period: period);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(nutritionAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Distribution'),
          ],
        ),
      ),
      body: _buildBody(analyticsState),
    );
  }

  Widget _buildBody(NutritionAnalyticsState state) {
    switch (state.status) {
      case NutritionAnalyticsStatus.initial:
      case NutritionAnalyticsStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case NutritionAnalyticsStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userId = ref.read(currentUserIdProvider);
                  ref
                      .read(nutritionAnalyticsProvider.notifier)
                      .generateReport(
                        userId: userId,
                        period: state.currentPeriod,
                      );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case NutritionAnalyticsStatus.loaded:
        if (state.report == null) {
          return const Center(
            child: Text('No data available for the selected period'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: PeriodSelector(
                currentPeriod: state.currentPeriod,
                onPeriodChanged: _changePeriod,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(state: state),
                  TrendsTab(state: state),
                  DistributionTab(state: state),
                ],
              ),
            ),
          ],
        );
    }
  }
}
