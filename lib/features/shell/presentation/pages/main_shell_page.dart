import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/app_bottom_nav_bar.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/pages/folders_page.dart';
import 'package:shoto/features/home/presentation/pages/home_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/share_intent_listener.dart';
import 'package:shoto/features/settings/presentation/pages/settings_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  // FoldersBloc lives here (above the IndexedStack) instead of inside
  // FoldersPage, because IndexedStack keeps every tab's widget alive once
  // built — FoldersPage would never rebuild (and its counts would never
  // refresh) just from switching tabs. Owning it here lets us force a
  // reload every time the Folders tab is selected.
  late final FoldersBloc _foldersBloc = sl<FoldersBloc>()
    ..add(LoadFoldersEvent());

  static const List<AppNavItem> _items = [
    AppNavItem(
      icon: Icons.image_outlined,
      activeIcon: Icons.image_rounded,
      label: 'Home',
    ),
    AppNavItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Folders',
    ),
    AppNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  void _onTabSelected(int index) {
    if (index == 1) {
      _foldersBloc.add(LoadFoldersEvent());
    }
    setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    _foldersBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _foldersBloc,
      child: ShareIntentListener(
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: _currentIndex,
            children: const [HomePage(), FoldersPage(), SettingsPage()],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _currentIndex,
            items: _items,
            onTap: _onTabSelected,
          ),
        ),
      ),
    );
  }
}
