import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_models.dart';
import '../models/app_user.dart';
import '../models/project_models.dart';
import '../services/auth/auth_service.dart';
import '../services/projects/in_memory_project_repository.dart';
import '../services/projects/project_repository.dart';
import '../services/projects/supabase_project_repository.dart';
import '../services/supabase/supabase_bootstrap.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authSessionProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).watchAuthState();
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final client = SupabaseBootstrap.client;
  if (client != null) {
    return SupabaseProjectRepository(client);
  }
  return InMemoryProjectRepository();
});

final workspaceListProvider = FutureProvider<List<WorkspaceSummary>>((ref) {
  return ref.watch(projectRepositoryProvider).getWorkspaces();
});

final selectedWorkspaceIdProvider = StateProvider<String?>((ref) {
  return null;
});

final activeWorkspaceProvider = Provider<WorkspaceSummary?>((ref) {
  final workspaces = ref.watch(workspaceListProvider).valueOrNull ??
      const <WorkspaceSummary>[];
  final selectedWorkspaceId = ref.watch(selectedWorkspaceIdProvider);
  if (workspaces.isEmpty) {
    return null;
  }
  if (selectedWorkspaceId == null || selectedWorkspaceId.isEmpty) {
    return workspaces.first;
  }
  for (final workspace in workspaces) {
    if (workspace.id == selectedWorkspaceId) {
      return workspace;
    }
  }
  return workspaces.first;
});

final workspaceNameByIdProvider = Provider<Map<String, String>>((ref) {
  final workspaces = ref.watch(workspaceListProvider).valueOrNull ??
      const <WorkspaceSummary>[];
  return {
    for (final workspace in workspaces) workspace.id: workspace.name,
  };
});

final goalDraftProvider = StateProvider<String>((ref) => '');

final projectListProvider = FutureProvider<List<ProjectSummary>>((ref) {
  final workspace = ref.watch(activeWorkspaceProvider);
  if (workspace == null) {
    return Future.value(const <ProjectSummary>[]);
  }
  return ref.watch(projectRepositoryProvider).getProjects(workspace.id);
});

final projectDetailProvider =
    FutureProvider.family<ProjectDetail?, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).getProjectDetail(projectId);
});

final agentCatalogProvider = Provider<List<AgentNode>>((ref) {
  return InMemoryProjectRepository.catalog;
});

final supabaseStatusProvider = Provider<String?>((ref) {
  if (SupabaseBootstrap.isReady) {
    return null;
  }
  return SupabaseBootstrap.isConfigured
      ? SupabaseBootstrap.errorMessage ?? 'Supabase initialization failed.'
      : 'Supabase is not configured. Google OAuth is disabled until env vars are set.';
});

final dashboardMetricsProvider = Provider<Map<String, int>>((ref) {
  final projects =
      ref.watch(projectListProvider).valueOrNull ?? const <ProjectSummary>[];
  final activeProjects = projects.where((project) {
    return project.status == ProjectStatus.running ||
        project.status == ProjectStatus.planning;
  }).length;
  final totalTasks =
      projects.fold<int>(0, (sum, project) => sum + project.totalTasks);
  final completedTasks = projects.fold<int>(
    0,
    (sum, project) => sum + project.completedTasks,
  );
  return {
    'activeProjects': activeProjects,
    'completedTasks': completedTasks,
    'totalTasks': totalTasks,
    'artifacts':
        projects.fold<int>(0, (sum, project) => sum + project.totalArtifacts),
  };
});

class GoalSubmissionController
    extends StateNotifier<AsyncValue<ProjectDetail?>> {
  GoalSubmissionController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  bool _isSubmitting = false;

  Future<ProjectDetail?> submitGoal(String goal) async {
    if (_isSubmitting) {
      return null;
    }
    if (goal.trim().isEmpty) {
      state = AsyncError(
        ArgumentError('Project goal is required.'),
        StackTrace.current,
      );
      return null;
    }

    _isSubmitting = true;
    state = const AsyncLoading();
    try {
      final selectedWorkspaceId = _ref.read(selectedWorkspaceIdProvider);
      final workspaces = await _ref.read(workspaceListProvider.future);
      final workspaceId = _resolveWorkspaceId(selectedWorkspaceId, workspaces);
      final detail = await _ref.read(projectRepositoryProvider).createProject(
            workspaceId: workspaceId,
            goal: goal,
          );
      _ref.read(goalDraftProvider.notifier).state = '';
      state = AsyncData(detail);
      return detail;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    } finally {
      _isSubmitting = false;
    }
  }

  void clear() {
    state = const AsyncData(null);
  }

  String _resolveWorkspaceId(
    String? selectedWorkspaceId,
    List<WorkspaceSummary> workspaces,
  ) {
    if (selectedWorkspaceId != null && selectedWorkspaceId.isNotEmpty) {
      for (final workspace in workspaces) {
        if (workspace.id == selectedWorkspaceId) {
          return selectedWorkspaceId;
        }
      }
    }
    if (workspaces.isNotEmpty) {
      return workspaces.first.id;
    }
    return '';
  }
}

final goalSubmissionProvider =
    StateNotifierProvider<GoalSubmissionController, AsyncValue<ProjectDetail?>>(
        (ref) {
  return GoalSubmissionController(ref);
});

final scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);
