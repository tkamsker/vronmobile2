import 'package:flutter/material.dart';

/// Enum representing the status of a project
enum ProjectStatus {
  active,
  paused,
  archived;

  /// Convert from string (from API)
  static ProjectStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ProjectStatus.active;
      case 'paused':
        return ProjectStatus.paused;
      case 'archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.active;
    }
  }

  /// Convert to string (for API)
  String toJson() {
    switch (this) {
      case ProjectStatus.active:
        return 'active';
      case ProjectStatus.paused:
        return 'paused';
      case ProjectStatus.archived:
        return 'archived';
    }
  }

  /// Get display label for status
  String get label {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.paused:
        return 'Paused';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }

  /// Get color for status badge
  Color get color {
    switch (this) {
      case ProjectStatus.active:
        return const Color(0xFF4CAF50); // Green
      case ProjectStatus.paused:
        return const Color(0xFFFF9800); // Orange
      case ProjectStatus.archived:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  /// Get background color for status badge
  Color get backgroundColor {
    switch (this) {
      case ProjectStatus.active:
        return const Color(0xFFE8F5E9); // Light green
      case ProjectStatus.paused:
        return const Color(0xFFFFF3E0); // Light orange
      case ProjectStatus.archived:
        return const Color(0xFFF5F5F5); // Light gray
    }
  }
}
