import 'package:flutter/material.dart';

class ResponsiveSplitView extends StatelessWidget {
  const ResponsiveSplitView({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = 980,
    this.primaryFlex = 5,
    this.secondaryFlex = 4,
    this.spacing = 16,
  });

  final Widget primary;
  final Widget secondary;
  final double breakpoint;
  final int primaryFlex;
  final int secondaryFlex;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              primary,
              SizedBox(height: spacing),
              secondary,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            SizedBox(width: spacing),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}
