import 'package:flutter/material.dart';

/// Tab navigation component for project detail screen
/// Displays three tabs: Viewer, Project data, and Products
class ProjectTabNavigation extends StatefulWidget {
  final void Function(int index)? onTabChanged;
  final List<Widget>? tabViews;

  const ProjectTabNavigation({
    super.key,
    this.onTabChanged,
    this.tabViews,
  });

  @override
  State<ProjectTabNavigation> createState() => _ProjectTabNavigationState();
}

class _ProjectTabNavigationState extends State<ProjectTabNavigation>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && widget.onTabChanged != null) {
        widget.onTabChanged!(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Viewer'),
            Tab(text: 'Project data'),
            Tab(text: 'Products'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabViews ??
                [
                  const Center(child: Text('Viewer Tab')),
                  const Center(child: Text('Project Data Tab')),
                  const Center(child: Text('Products Tab')),
                ],
          ),
        ),
      ],
    );
  }
}
