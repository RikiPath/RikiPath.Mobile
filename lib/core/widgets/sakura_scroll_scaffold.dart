import 'package:flutter/material.dart';

/// A reusable scaffold wrapper that tracks scroll depth on the primary vertical
/// scroll view and passes [isScrolled] to [appBarBuilder] without causing
/// frame-by-frame rebuilds.
class SakuraScrollScaffold extends StatefulWidget {
  const SakuraScrollScaffold({
    required this.appBarBuilder,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.threshold = 4.0,
    super.key,
  });

  final PreferredSizeWidget Function(BuildContext context, bool isScrolled)
      appBarBuilder;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final double threshold;

  @override
  State<SakuraScrollScaffold> createState() => _SakuraScrollScaffoldState();
}

class _SakuraScrollScaffoldState extends State<SakuraScrollScaffold> {
  bool _isScrolled = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical) {
      final isScrolled = notification.metrics.pixels > widget.threshold;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.appBarBuilder(context, _isScrolled),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.body,
      ),
    );
  }
}
