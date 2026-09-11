import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Minimal route destination used only until its feature phase is authorized.
class RoutePlaceholderScreen extends StatelessWidget {
  const RoutePlaceholderScreen({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ),
        ),
      ),
    );
  }
}
