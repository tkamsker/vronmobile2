import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vronmobile2/core/config/env_config.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
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
  Timer? _debounceTimer;

  List<Project> _allProjects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter =
      'All'; // Track selected filter: All, Active, Archived

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
      // Fetch ALL projects (no subscription filter)
      final projects = await _projectService.fetchProjects();

      if (kDebugMode) {
        print(
          '✅ [HOME] Loaded ${projects.length} projects (all subscriptions)',
        );
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
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Create new timer with 300ms delay (FR-003 requirement)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _searchQuery = query;
        _applyFilters();
      });
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
      case 'BYO':
        // Filter for Bring Your Own (MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER)
        filtered = filtered
            .where(
              (project) =>
                  project.subscription.status ==
                  'MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER',
            )
            .toList();
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
    HapticFeedback.selectionClick();
    if (kDebugMode) print('🏠 [HOME] Filter changed to: $filter');
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _handleProjectTap(String projectId) {
    HapticFeedback.lightImpact();
    if (kDebugMode) print('🏠 [HOME] Project tapped: $projectId');
    // TODO: Navigate to project detail screen
    Navigator.pushNamed(context, AppRoutes.projectDetail, arguments: projectId);
  }

  void _handleBottomNavTap(int index) {
    HapticFeedback.selectionClick();
    if (kDebugMode) print('🏠 [HOME] Bottom nav tapped: $index');

    switch (index) {
      case 0: // Home - already here
        break;
      case 1: // Projects - already here
        break;
      case 2: // Products
        Navigator.pushNamed(context, AppRoutes.products);
        break;
      case 3: // LiDAR
        Navigator.pushNamed(context, AppRoutes.lidar);
        break;
      case 4: // Profile
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  Future<void> _handleCreateProject() async {
    HapticFeedback.mediumImpact();
    if (kDebugMode) print('🏠 [HOME] Create project tapped');

    // Open VRON web app projects page in external browser
    final url = Uri.parse(EnvConfig.projectsPageUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (kDebugMode) {
          print('🏠 [HOME] Opened projects page in browser: $url');
        }

        // Refresh project list when user returns to app
        // (in case they created a project in the web app)
        await _loadProjects();
      } else {
        if (kDebugMode) print('❌ [HOME] Could not launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open projects page'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ [HOME] Error launching URL: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening projects page: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleProfileTap() {
    HapticFeedback.lightImpact();
    if (kDebugMode) print('🏠 [HOME] Profile icon tapped');
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(onRefresh: _loadProjects, child: _buildBody()),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Home tab is active
        onTap: _handleBottomNavTap,
      ),
      floatingActionButton: CustomFAB(onPressed: _handleCreateProject),
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
              child: Icon(Icons.person, color: Colors.grey[700]),
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
          Expanded(child: _buildContent()),
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
            'home.title'.tr(),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'home.subtitle'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
          hintText: 'home.searchPlaceholder'.tr(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Active'),
            const SizedBox(width: 8),
            _buildFilterChip('BYO'),
            const SizedBox(width: 8),
            _buildFilterChip('Archived'),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                // TODO: Implement sort
              },
              icon: const Icon(Icons.sort),
              label: Text('home.sort'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    // Translate label for display
    String displayLabel;
    switch (label) {
      case 'All':
        displayLabel = 'home.filterAll'.tr();
        break;
      case 'Active':
        displayLabel = 'home.filterActive'.tr();
        break;
      case 'BYO':
        displayLabel = 'home.filterBYO'.tr();
        break;
      case 'Archived':
        displayLabel = 'home.filterArchived'.tr();
        break;
      default:
        displayLabel = label;
    }

    return FilterChip(
      label: Text(displayLabel),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onFilterChanged(label);
        }
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
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
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'home.loadingError'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProjects,
              child: Text('home.retry'.tr()),
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
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'home.noResults'.tr()
                  : 'home.noProjects'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'home.noResultsMessage'.tr()
                  : 'home.noProjectsMessage'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleCreateProject,
                icon: const Icon(Icons.add),
                label: Text('home.createProject'.tr()),
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
                'home.recentProjects'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'home.totalCount'.tr(
                  params: {'count': _filteredProjects.length},
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
