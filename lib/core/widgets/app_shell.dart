import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<Widget> actions;

  static const _destinations = <_ShellDestination>[
    _ShellDestination(Icons.space_dashboard_outlined, 'Dashboard'),
    _ShellDestination(Icons.folder_outlined, 'Projects'),
    _ShellDestination(Icons.bolt_outlined, 'Artifacts'),
    _ShellDestination(Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1080;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex:
                      selectedIndex.clamp(0, _destinations.length - 1).toInt(),
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 88,
                  backgroundColor: theme.colorScheme.surface,
                  destinations: _destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.icon,
                              color: theme.colorScheme.primary),
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _ShellAppBar(title: title, actions: actions),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: _ShellAppBar(title: title, actions: actions),
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex:
                selectedIndex.clamp(0, _destinations.length - 1).toInt(),
            onDestinationSelected: onDestinationSelected,
            destinations: _destinations
                .map(
                  (destination) => NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.icon,
                        color: theme.colorScheme.primary),
                    label: destination.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShellAppBar({
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(title),
      centerTitle: false,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class _ShellDestination {
  const _ShellDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}
