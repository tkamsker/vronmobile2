import 'package:vronmobile2/features/home/models/project_subscription.dart';

/// Model representing a project from the VRon API
/// Based on the getProjects GraphQL query response
class Project {
  final String id;
  final String slug;
  final String name;
  final String imageUrl;
  final bool isLive;
  final DateTime? liveDate;
  final ProjectSubscription subscription;

  const Project({
    required this.id,
    required this.slug,
    required this.name,
    required this.imageUrl,
    required this.isLive,
    this.liveDate,
    required this.subscription,
  });

  /// Create Project from JSON (from API response)
  /// The language parameter should match the query language used
  factory Project.fromJson(Map<String, dynamic> json) {
    // Extract name from I18NField structure
    String projectName = '';
    if (json['name'] != null) {
      final nameField = json['name'];
      if (nameField is Map<String, dynamic> && nameField['text'] != null) {
        projectName = nameField['text'] as String;
      } else if (nameField is String) {
        projectName = nameField;
      }
    }

    return Project(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? '',
      name: projectName,
      imageUrl: json['imageUrl'] as String? ?? '',
      isLive: json['isLive'] as bool? ?? false,
      liveDate: json['liveDate'] != null
          ? DateTime.parse(json['liveDate'] as String)
          : null,
      subscription: ProjectSubscription.fromJson(
        json['subscription'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Get user-friendly status label based on subscription and isLive
  String get statusLabel {
    if (isLive) {
      if (subscription.isActive) {
        return 'Live';
      } else if (subscription.isTrial) {
        return 'Live (Trial)';
      } else {
        return 'Live (Inactive)';
      }
    } else {
      return 'Not Live';
    }
  }

  /// Get status color for UI
  String get statusColorHex {
    if (isLive && subscription.isActive) {
      return '#4CAF50'; // Green - Live and active
    } else if (isLive && subscription.isTrial) {
      return '#FF9800'; // Orange - Live but trial
    } else if (!isLive) {
      return '#9E9E9E'; // Gray - Not live
    } else {
      return '#F44336'; // Red - Live but inactive
    }
  }

  /// Get a short description for display
  String get shortDescription {
    final parts = <String>[];

    if (isLive) {
      parts.add('Live');
    } else {
      parts.add('Not published');
    }

    if (subscription.isTrial) {
      parts.add('Trial');
    } else if (subscription.isActive) {
      parts.add('Active subscription');
    } else if (subscription.hasExpired) {
      parts.add('Expired');
    }

    return parts.join(' • ');
  }

  /// Get team info string (for backward compatibility with UI)
  String get teamInfo {
    // This field doesn't exist in the API, but keeping for UI compatibility
    // Could be derived from subscription or other fields in future
    if (subscription.renewalInterval != null) {
      return subscription.renewalInterval == 'YEARLY'
          ? 'Yearly plan'
          : 'Monthly plan';
    }
    return subscription.statusLabel;
  }

  /// Get formatted update time (for backward compatibility with UI)
  DateTime get updatedAt {
    // Use liveDate or renewsAt as a proxy for "updated"
    return liveDate ??
        subscription.renewsAt ??
        subscription.expiresAt ??
        DateTime.now();
  }

  /// Create a copy of this Project with some fields replaced
  Project copyWith({
    String? id,
    String? slug,
    String? name,
    String? imageUrl,
    bool? isLive,
    DateTime? liveDate,
    ProjectSubscription? subscription,
  }) {
    return Project(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isLive: isLive ?? this.isLive,
      liveDate: liveDate ?? this.liveDate,
      subscription: subscription ?? this.subscription,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project &&
        other.id == id &&
        other.slug == slug &&
        other.name == name &&
        other.imageUrl == imageUrl &&
        other.isLive == isLive &&
        other.liveDate == liveDate;
  }

  @override
  int get hashCode {
    return Object.hash(id, slug, name, imageUrl, isLive, liveDate);
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, slug: $slug, isLive: $isLive)';
  }
}
