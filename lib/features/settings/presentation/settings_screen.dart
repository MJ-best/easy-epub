import 'package:flutter/material.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.accountName,
    required this.accountEmail,
    required this.onSignOut,
    required this.onDestinationSelected,
    this.systemStatus,
    this.previewMode = false,
  });

  final String accountName;
  final String accountEmail;
  final VoidCallback onSignOut;
  final ValueChanged<int> onDestinationSelected;
  final String? systemStatus;
  final bool previewMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Settings',
      selectedIndex: 3,
      onDestinationSelected: onDestinationSelected,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Account',
            subtitle: 'Google OAuth and workspace access',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: !previewMode,
                  onChanged: (_) {},
                  title: Text(accountName),
                  subtitle: Text(accountEmail),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  onChanged: (_) {},
                  title: const Text('Email notifications'),
                  subtitle: const Text('Receive workflow and QA updates.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Workspace defaults',
            subtitle: 'Behaviors applied across new projects',
            child: Column(
              children: [
                if (systemStatus != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: const Text('System status'),
                    subtitle: Text(systemStatus!),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language),
                  title: const Text('Locale'),
                  trailing: Text('Korean', style: theme.textTheme.labelLarge),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('RLS access mode'),
                  trailing:
                      Text('Default deny', style: theme.textTheme.labelLarge),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Artifact retention'),
                  trailing: Text('Workspace scoped',
                      style: theme.textTheme.labelLarge),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
