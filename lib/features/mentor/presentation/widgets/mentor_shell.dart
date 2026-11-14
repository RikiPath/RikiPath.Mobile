import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/navigation_configuration.dart';
import 'package:rikipath_mobile/app/router/riki_path_app_shell.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Persistent five-tab shell for Mentor users sharing [RikiPathAppShell] and
/// [SakuraBottomNavigation] with Learner `MainShell`.
class MentorShell extends StatelessWidget {
  const MentorShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return MentorShellScope(
      isInsideShell: true,
      child: RikiPathAppShell(
        navigationShell: navigationShell,
        configuration: MentorNavigationConfiguration.instance,
      ),
    );
  }
}
