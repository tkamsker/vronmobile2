import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';
import 'package:vronmobile2/features/home/widgets/bottom_nav_bar.dart';
import 'package:vronmobile2/features/home/widgets/custom_fab.dart';
import 'package:vronmobile2/features/home/widgets/project_card.dart';

/// Home screen displaying user's project list with search and filter capabilities
class HomeScreen extends StatefulWidget {
  final String? userEmail;

  const HomeScreen({super.key, this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _searchController = TextEditingController();

  List<Project> _allProjects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // Track selected filter: All, Active, Archived

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    if (kDebugMode) print('🏠 [HOME] Loading projects...');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projects = await _projectService.fetchProjects();

      if (kDebugMode) {
        print('✅ [HOME] Loaded ${projects.length} projects');
      }

      setState(() {
        _allProjects = projects;
        _filteredProjects = projects;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('❌ [HOME] Error loading projects: $e');

      setState(() {
        _errorMessage = 'Failed to load projects: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Project> filtered = _allProjects;

    // Apply status filter first
    switch (_selectedFilter) {
      case 'Active':
        filtered = filtered.where((project) => project.isLive).toList();
        break;
      case 'Archived':
        filtered = filtered.where((project) => !project.isLive).toList();
        break;
      case 'All':
      default:
        // No filter, show all
        break;
    }

    // Then apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((project) => project.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    _filteredProjects = filtered;
  }

  void _onFilterChanged(String filter) {
    if (kDebugMode) print('🏠 [HOME] Filter changed to: $filter');
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _handleProjectTap(String projectId) {
    if (kDebugMode) print('🏠 [HOME] Project tapped: $projectId');
    // TODO: Navigate to project detail screen
    Navigator.pushNamed(context, AppRoutes.projectDetail, arguments: projectId);
  }

  void _handleBottomNavTap(int index) {
    if (kDebugMode) print('🏠 [HOME] Bottom nav tapped: $index');

    switch (index) {
      case 0: // Home - already here
        break;
      case 1: // Projects - already here
        break;
      case 2: // LiDAR
        Navigator.pushNamed(context, AppRoutes.lidar);
        break;
      case 3: // Profile
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  void _handleCreateProject() {
    if (kDebugMode) print('🏠 [HOME] Create project tapped');
    Navigator.pushNamed(context, AppRoutes.createProject);
  }

  void _handleProfileTap() {
    if (kDebugMode) print('🏠 [HOME] Profile icon tapped');
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Home tab is active
        onTap: _handleBottomNavTap,
      ),
      floatingActionButton: CustomFAB(
        onPressed: _handleCreateProject,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.white,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: _handleProfileTap,
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterTabs(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your projects',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jump back into your workspace',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search projects',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Active'),
          const SizedBox(width: 8),
          _buildFilterChip('Archived'),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              // TODO: Implement sort
            },
            icon: const Icon(Icons.sort),
            label: const Text('Sort'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onFilterChanged(label);
        }
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredProjects.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProjectList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load projects',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProjects,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No projects found' : 'No projects yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Create your first project to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleCreateProject,
                icon: const Icon(Icons.add),
                label: const Text('Create Project'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent projects',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${_filteredProjects.length} total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 120.0, // Extra padding to clear bottom nav and FAB
            ),
            itemCount: _filteredProjects.length,
            itemBuilder: (context, index) {
              final isLast = index == _filteredProjects.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                child: ProjectCard(
                  project: _filteredProjects[index],
                  onTap: _handleProjectTap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
