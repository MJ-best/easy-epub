import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.goalController,
    required this.onGoalChanged,
    required this.onGoogleSignIn,
    required this.onOpenPreview,
    required this.showPreviewAction,
    this.isBusy = false,
    this.statusMessage,
    this.errorMessage,
  });

  final TextEditingController goalController;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onOpenPreview;
  final bool showPreviewAction;
  final bool isBusy;
  final String? statusMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final hero = _HeroPanel(theme: theme);
                  final form = _LoginCard(
                    theme: theme,
                    goalController: goalController,
                    onGoalChanged: onGoalChanged,
                    onGoogleSignIn: onGoogleSignIn,
                    onOpenPreview: onOpenPreview,
                    showPreviewAction: showPreviewAction,
                    isBusy: isBusy,
                    statusMessage: statusMessage,
                    errorMessage: errorMessage,
                  );

                  if (isWide) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: hero),
                          const SizedBox(width: 24),
                          Expanded(flex: 4, child: form),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      hero,
                      const SizedBox(height: 20),
                      form,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workflow-first multi-agent coding',
              style: theme.textTheme.displaySmall),
          const SizedBox(height: 16),
          Text(
            '사용자가 목표를 입력하면 Orchestrator가 계획을 만들고, PM, System Designer, Flutter, QA 에이전트가 구조화된 산출물을 생성합니다.',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _FeatureChip(label: 'Goal to plan'),
              _FeatureChip(label: 'Artifact pipeline'),
              _FeatureChip(label: 'Supabase + Flutter'),
              _FeatureChip(label: 'No chat-first UX'),
            ],
          ),
          const SizedBox(height: 28),
          const _FlowPreview(),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.theme,
    required this.goalController,
    required this.onGoalChanged,
    required this.onGoogleSignIn,
    required this.onOpenPreview,
    required this.showPreviewAction,
    required this.isBusy,
    this.statusMessage,
    this.errorMessage,
  });

  final ThemeData theme;
  final TextEditingController goalController;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onOpenPreview;
  final bool showPreviewAction;
  final bool isBusy;
  final String? statusMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Google OAuth via Supabase Auth',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                statusMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: goalController,
              decoration: const InputDecoration(
                labelText: 'Project goal',
                hintText: 'Build a design system audit tool...',
              ),
              maxLines: 4,
              onChanged: onGoalChanged,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isBusy ? null : onGoogleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
            if (showPreviewAction) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isBusy ? null : onOpenPreview,
                child: const Text('Open demo workspace'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Edge cases handled: OAuth redirect failure, empty goal, permission issues, and partial artifact generation.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

class _FlowPreview extends StatelessWidget {
  const _FlowPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _FlowNode(label: 'Goal', icon: Icons.edit_note),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          _FlowNode(label: 'Plan', icon: Icons.route),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          _FlowNode(label: 'Artifacts', icon: Icons.dataset),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  const _FlowNode({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.labelLarge),
      ],
    );
  }
}
