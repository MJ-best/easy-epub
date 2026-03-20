import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/artifacts/presentation/artifact_viewer_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/projects/models/project_workflow_models.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/project_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../providers/app_providers.dart';
import '../services/auth/auth_service.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authSessionProvider);
  final isLoggedIn = authState.valueOrNull != null;

  return GoRouter(
    initialLocation: isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
    redirect: (context, state) {
      final goingToLogin = state.matchedLocation == AppRoutes.login;
      if (authState.isLoading) {
        return null;
      }
      if (!isLoggedIn && !goingToLogin) {
        return AppRoutes.login;
      }
      if (isLoggedIn && goingToLogin) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const _LoginRouteScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const _DashboardRouteScreen(),
      ),
      GoRoute(
        path: AppRoutes.projects,
        builder: (context, state) => const _ProjectListRouteScreen(),
        routes: [
          GoRoute(
            path: ':projectId',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId']!;
              return _ProjectDetailRouteScreen(projectId: projectId);
            },
            routes: [
              GoRoute(
                path: 'artifacts/:artifactId',
                builder: (context, state) {
                  final projectId = state.pathParameters['projectId']!;
                  final artifactId = state.pathParameters['artifactId']!;
                  return _ArtifactViewerRouteScreen(
                    projectId: projectId,
                    artifactId: artifactId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const _SettingsRouteScreen(),
      ),
    ],
  );
});

class _LoginRouteScreen extends ConsumerStatefulWidget {
  const _LoginRouteScreen();

  @override
  ConsumerState<_LoginRouteScreen> createState() => _LoginRouteScreenState();
}

class _LoginRouteScreenState extends ConsumerState<_LoginRouteScreen> {
  late final TextEditingController _goalController;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: ref.read(goalDraftProvider),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final statusMessage = ref.watch(supabaseStatusProvider);

    return LoginScreen(
      goalController: _goalController,
      onGoalChanged: (value) =>
          ref.read(goalDraftProvider.notifier).state = value,
      onGoogleSignIn: () => _handleGoogleSignIn(authService),
      onOpenPreview: () => _handlePreview(authService),
      showPreviewAction: authService.supportsPreviewMode,
      isBusy: _isBusy,
      statusMessage: statusMessage,
      errorMessage: _errorMessage,
    );
  }

  Future<void> _handleGoogleSignIn(AuthService authService) async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await authService.signInWithGoogle();
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _handlePreview(AuthService authService) async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await authService.continueWithPreview();
      final detail = await ref
          .read(goalSubmissionProvider.notifier)
          .submitGoal(_goalController.text);
      ref.invalidate(projectListProvider);
      if (!mounted) {
        return;
      }
      if (detail != null) {
        context.go(AppRoutes.projectDetail(detail.summary.id));
      } else {
        context.go(AppRoutes.dashboard);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }
}

class _DashboardRouteScreen extends ConsumerStatefulWidget {
  const _DashboardRouteScreen();

  @override
  ConsumerState<_DashboardRouteScreen> createState() =>
      _DashboardRouteScreenState();
}

class _DashboardRouteScreenState extends ConsumerState<_DashboardRouteScreen> {
  late final TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: ref.read(goalDraftProvider),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsValue = ref.watch(projectListProvider);
    final metrics = ref.watch(dashboardMetricsProvider);
    final submission = ref.watch(goalSubmissionProvider);
    final statusMessage = ref.watch(supabaseStatusProvider);
    final workspaceNames = ref.watch(workspaceNameByIdProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);

    final projects = projectsValue.valueOrNull ?? const [];
    final mappedProjects = projects
        .map(
          (project) => ProjectWorkflowData.fromProjectSummary(
            project,
            workspaceName: workspaceNames[project.workspaceId] ??
                activeWorkspace?.name ??
                'Workspace',
          ),
        )
        .toList();

    return DashboardScreen(
      projects: mappedProjects,
      metrics: metrics,
      goalController: _goalController,
      onGoalChanged: (value) =>
          ref.read(goalDraftProvider.notifier).state = value,
      onStartWorkflow: _handleStartWorkflow,
      onOpenProject: (projectId) =>
          context.go(AppRoutes.projectDetail(projectId)),
      onDestinationSelected: (index) => _navigateFromShell(context, index),
      statusMessage: statusMessage,
      submissionError: submission.whenOrNull(
        error: (error, _) => error.toString(),
      ),
      isSubmitting: submission.isLoading,
    );
  }

  Future<void> _handleStartWorkflow() async {
    final detail = await ref
        .read(goalSubmissionProvider.notifier)
        .submitGoal(_goalController.text);
    ref.invalidate(projectListProvider);
    if (!mounted || detail == null) {
      return;
    }
    _goalController.clear();
    context.go(AppRoutes.projectDetail(detail.summary.id));
  }
}

class _ProjectListRouteScreen extends ConsumerWidget {
  const _ProjectListRouteScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider).valueOrNull ?? const [];
    final workspaceNames = ref.watch(workspaceNameByIdProvider);
    final mappedProjects = projects
        .map(
          (project) => ProjectWorkflowData.fromProjectSummary(
            project,
            workspaceName: workspaceNames[project.workspaceId] ?? 'Workspace',
          ),
        )
        .toList();

    return ProjectListScreen(
      projects: mappedProjects,
      onNewProject: () => context.go(AppRoutes.dashboard),
      onOpenProject: (projectId) =>
          context.go(AppRoutes.projectDetail(projectId)),
      onDestinationSelected: (index) => _navigateFromShell(context, index),
    );
  }
}

class _ProjectDetailRouteScreen extends ConsumerWidget {
  const _ProjectDetailRouteScreen({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(projectDetailProvider(projectId)).valueOrNull;
    final catalog = ref.watch(agentCatalogProvider);
    final workspaceNames = ref.watch(workspaceNameByIdProvider);

    final mapped = detail == null
        ? null
        : ProjectWorkflowData.fromProjectDetail(
            detail,
            workspaceName:
                workspaceNames[detail.summary.workspaceId] ?? 'Workspace',
            catalog: catalog,
          );

    return ProjectDetailScreen(
      project: mapped,
      onOpenArtifact: (artifactId) =>
          context.go(AppRoutes.artifactViewer(projectId, artifactId)),
      onDestinationSelected: (index) => _navigateFromShell(
        context,
        index,
        projectId: projectId,
        artifactId: mapped?.artifacts.firstOrNull?.id,
      ),
    );
  }
}

class _ArtifactViewerRouteScreen extends ConsumerWidget {
  const _ArtifactViewerRouteScreen({
    required this.projectId,
    required this.artifactId,
  });

  final String projectId;
  final String artifactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(projectDetailProvider(projectId)).valueOrNull;
    final catalog = ref.watch(agentCatalogProvider);
    final workspaceNames = ref.watch(workspaceNameByIdProvider);
    final mapped = detail == null
        ? null
        : ProjectWorkflowData.fromProjectDetail(
            detail,
            workspaceName:
                workspaceNames[detail.summary.workspaceId] ?? 'Workspace',
            catalog: catalog,
          );
    final artifacts = mapped?.artifacts ?? const <WorkflowArtifactSummary>[];
    final selected = artifacts
        .where((artifact) => artifact.id == artifactId)
        .cast<WorkflowArtifactSummary?>()
        .firstOrNull;

    return ArtifactViewerScreen(
      artifacts: artifacts,
      artifact: selected,
      onSelectArtifact: (nextArtifactId) =>
          context.go(AppRoutes.artifactViewer(projectId, nextArtifactId)),
      onDestinationSelected: (index) => _navigateFromShell(
        context,
        index,
        projectId: projectId,
        artifactId: artifactId,
      ),
    );
  }
}

class _SettingsRouteScreen extends ConsumerWidget {
  const _SettingsRouteScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).valueOrNull;
    final status = ref.watch(supabaseStatusProvider);
    final authService = ref.watch(authServiceProvider);

    return SettingsScreen(
      accountName: user?.displayName ?? 'Guest',
      accountEmail: user?.email ?? 'Not signed in',
      systemStatus: status,
      previewMode: user?.isPreview ?? false,
      onSignOut: () async {
        await authService.signOut();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
      onDestinationSelected: (index) => _navigateFromShell(context, index),
    );
  }
}

void _navigateFromShell(
  BuildContext context,
  int index, {
  String? projectId,
  String? artifactId,
}) {
  switch (index) {
    case 0:
      context.go(AppRoutes.dashboard);
      break;
    case 1:
      if (projectId != null) {
        context.go(AppRoutes.projectDetail(projectId));
      } else {
        context.go(AppRoutes.projects);
      }
      break;
    case 2:
      if (projectId != null && artifactId != null) {
        context.go(AppRoutes.artifactViewer(projectId, artifactId));
      } else {
        context.go(AppRoutes.projects);
      }
      break;
    case 3:
      context.go(AppRoutes.settings);
      break;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
