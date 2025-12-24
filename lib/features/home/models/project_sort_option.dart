import 'package:flutter/material.dart';

/// Sort options for project list
///
/// Used by ProjectService.fetchProjects() to determine list ordering
enum ProjectSortOption {
  /// Sort by name A-Z (case-insensitive)
  nameAscending,

  /// Sort by name Z-A (case-insensitive)
  nameDescending,

  /// Sort by updated date, newest first
  dateNewest,

  /// Sort by updated date, oldest first
  dateOldest,

  /// Sort by status priority (Live > Trial > Inactive > Not Live),
  /// with secondary sort by name A-Z
  status,
}

extension ProjectSortOptionExtension on ProjectSortOption {
  /// Human-readable label for UI display
  String get label {
    switch (this) {
      case ProjectSortOption.nameAscending:
        return 'Name (A-Z)';
      case ProjectSortOption.nameDescending:
        return 'Name (Z-A)';
      case ProjectSortOption.dateNewest:
        return 'Date (Newest)';
      case ProjectSortOption.dateOldest:
        return 'Date (Oldest)';
      case ProjectSortOption.status:
        return 'Status';
    }
  }

  /// Icon for UI display
  IconData get icon {
    switch (this) {
      case ProjectSortOption.nameAscending:
        return Icons.arrow_upward;
      case ProjectSortOption.nameDescending:
        return Icons.arrow_downward;
      case ProjectSortOption.dateNewest:
        return Icons.date_range;
      case ProjectSortOption.dateOldest:
        return Icons.history;
      case ProjectSortOption.status:
        return Icons.label;
    }
  }
}
