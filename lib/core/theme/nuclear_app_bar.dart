import 'package:flutter/material.dart';
import 'atom_logo.dart';
import 'app_theme.dart';

/// Custom AppBar with atom logo for Nuclear MOTD
class NuclearAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const NuclearAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
          ],
          Text(title),
        ],
      ),
      actions: actions,
    );
  }
}

/// Small atom icon for AppBar use
class AppBarAtomLogo extends StatelessWidget {
  const AppBarAtomLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 12),
      child: AtomIcon(size: 32),
    );
  }
}
