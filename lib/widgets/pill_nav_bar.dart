import 'package:flutter/material.dart';

import '../utils/app_style.dart';
import '../utils/motion.dart';

/// One tab of the [PillNavBar]: its icons and its name.
class PillNavItem {
  const PillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// The icon when the tab isn't selected (outlined).
  final IconData icon;

  /// The icon when the tab is selected (filled).
  final IconData selectedIcon;

  /// The tab's name, e.g. "Home". It is shown only on the selected tab.
  final String label;
}

/// The floating dark pill at the bottom of the app, with one button per tab.
/// The selected tab is a white pill with its icon and name; the other tabs
/// show only their icon. Tapping a tab calls [onSelected] with its index.
class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// The icons of tabs that aren't selected: white, slightly see-through.
  static const Color _idleColor = Color(0xB8FFFFFF);

  final List<PillNavItem> items;

  /// The index of the selected tab in [items].
  final int selectedIndex;

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // The off-white strip around the pill, so the pill seems to float above
    // the bottom of the screen.
    return ColoredBox(
      color: AppStyle.canvas,
      // SafeArea keeps the pill clear of the phone's navigation buttons.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Material(
            color: AppStyle.ink,
            shape: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < items.length; i++) _buildTab(context, i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The button of tab [index].
  Widget _buildTab(BuildContext context, int index) {
    final item = items[index];
    final selected = index == selectedIndex;

    // Screen readers hear the tab's name and whether it is selected, even
    // when only its icon is shown.
    return Semantics(
      container: true,
      label: item.label,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => onSelected(index),
        customBorder: const StadiumBorder(),
        child: ExcludeSemantics(
          // Switching tabs: TweenAnimationBuilder runs t from 0 to 1 on the
          // tab that was tapped, and from 1 to 0 on the old one, in 300 ms.
          // As t grows the pill turns white, the icon turns dark and the name
          // slides open. The first build shows the selected tab at once.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1 : 0),
            duration: Motion.duration(context, Motion.tabSwitch),
            curve: Motion.curve,
            builder: (context, t, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: t),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      color: Color.lerp(_idleColor, AppStyle.ink, t),
                    ),
                    // Only a share t of the name's width is shown, so the
                    // name slides open next to the icon.
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: t,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: AppStyle.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
