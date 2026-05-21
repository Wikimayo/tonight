import 'package:flutter/material.dart';

class TonightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TonightAppBar({
    required this.title,
    this.showBackButton = true,
    this.onBack,
    this.backIcon = Icons.arrow_back_rounded,
    this.backTooltip = 'Volver',
    this.actions,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final IconData backIcon;
  final String backTooltip;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height,
      backgroundColor: const Color(0xFF121018),
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      leadingWidth: showBackButton ? 64 : 20,
      leading: showBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Tooltip(
                  message: backTooltip,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(backIcon, color: Colors.white, size: 21),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      titleSpacing: showBackButton ? 10 : 24,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      actions: actions == null
          ? null
          : [...actions!, const SizedBox(width: 10)],
    );
  }
}
