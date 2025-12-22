import 'package:flutter/material.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';

/// Bottom navigation bar with Home, Projects, Products, LiDAR, and Profile tabs
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'navigation.home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.folder),
          label: 'navigation.projects'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2_outlined),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.camera_alt),
          label: 'navigation.lidar'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: 'navigation.profile'.tr(),
        ),
      ],
    );
  }
}
