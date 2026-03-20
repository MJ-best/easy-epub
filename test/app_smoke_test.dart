import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easypub/core/config/app_constants.dart';
import 'package:easypub/core/services/projects/in_memory_project_repository.dart';
import 'package:easypub/features/dashboard/presentation/dashboard_screen.dart';
import 'package:easypub/features/auth/presentation/login_screen.dart';
import 'package:easypub/features/projects/models/project_workflow_models.dart';

void main() {
  test('core project detail maps into workflow presentation model', () async {
    final repository = InMemoryProjectRepository();
    final summaries =
        await repository.getProjects(AppConstants.defaultWorkspaceId);
    final detail = await repository.getProjectDetail(summaries.first.id);

    final mapped = ProjectWorkflowData.fromProjectDetail(
      detail!,
      workspaceName: 'Core Product Studio',
      catalog: InMemoryProjectRepository.catalog,
    );

    expect(mapped.executionPlan, isNotEmpty);
    expect(mapped.artifacts, isNotEmpty);
    expect(mapped.agents.length, 5);
  });

  testWidgets('login screen renders goal input and auth actions',
      (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          goalController: controller,
          onGoalChanged: (_) {},
          onGoogleSignIn: () {},
          onOpenPreview: () {},
          showPreviewAction: true,
        ),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Open demo workspace'), findsOneWidget);
  });

  testWidgets('dashboard renders empty state without projects', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          projects: const [],
          metrics: const {
            'activeProjects': 0,
            'completedTasks': 0,
            'artifacts': 0,
            'totalTasks': 0,
          },
          goalController: controller,
          onGoalChanged: (_) {},
          onStartWorkflow: () {},
          onOpenProject: (_) {},
          onDestinationSelected: (_) {},
        ),
      ),
    );

    final emptyWorkflowFinder =
        find.text('No workflows yet', skipOffstage: false);
    await tester.scrollUntilVisible(
      emptyWorkflowFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(emptyWorkflowFinder, findsOneWidget);
  });
}
