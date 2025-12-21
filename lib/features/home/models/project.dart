/// Project model representing a VRon project
class Project {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isLive;
  final DateTime? liveDate;
  final DateTime? updatedAt;
  final String? teamInfo;
  final ProjectSubscription? subscription;

  Project({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isLive,
    this.liveDate,
    this.updatedAt,
    this.teamInfo,
    this.subscription,
  });

  /// Create Project from GraphQL JSON response
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: _extractText(json['name']),
      description: json['description'] != null
          ? _extractText(json['description'])
          : null,
      imageUrl: json['imageUrl'] as String?,
      isLive: json['isLive'] as bool? ?? false,
      liveDate: json['liveDate'] != null
          ? DateTime.parse(json['liveDate'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      teamInfo: json['teamInfo'] as String?,
      subscription: json['subscription'] != null
          ? ProjectSubscription.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Extract text from multilingual text object
  /// Expected format: { "text": "Project Name" }
  static String _extractText(dynamic textObj) {
    if (textObj is String) {
      return textObj;
    }
    if (textObj is Map<String, dynamic> && textObj.containsKey('text')) {
      return textObj['text'] as String;
    }
    return '';
  }

  /// Get short description (truncated to 100 characters)
  String get shortDescription {
    if (description == null || description!.isEmpty) {
      return '';
    }
    if (description!.length <= 100) {
      return description!;
    }
    return '${description!.substring(0, 100)}...';
  }

  /// Get status color in hex format
  String get statusColorHex {
    if (isLive) {
      return '#4CAF50'; // Green for live projects
    } else if (subscription?.isTrial == true) {
      return '#FF9800'; // Orange for trial
    } else if (subscription?.isActive == true) {
      return '#2196F3'; // Blue for active subscription
    } else {
      return '#9E9E9E'; // Gray for inactive
    }
  }

  /// Get status label
  String get statusLabel {
    if (isLive) {
      return 'Live';
    } else if (subscription?.isTrial == true) {
      return 'Trial';
    } else if (subscription?.isActive == true) {
      return 'Active';
    } else {
      return 'Inactive';
    }
  }

  /// Convert Project to JSON (for updates/mutations)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isLive': isLive,
      'liveDate': liveDate?.toIso8601String(),
    };
  }
}

/// Project subscription model
class ProjectSubscription {
  final bool isActive;
  final bool isTrial;
  final String status;
  final bool canChoosePlan;
  final bool hasExpired;
  final String? currency;
  final double? price;
  final String? renewalInterval;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? renewsAt;
  final SubscriptionPrices? prices;

  ProjectSubscription({
    required this.isActive,
    required this.isTrial,
    required this.status,
    required this.canChoosePlan,
    required this.hasExpired,
    this.currency,
    this.price,
    this.renewalInterval,
    this.startedAt,
    this.expiresAt,
    this.renewsAt,
    this.prices,
  });

  /// Create ProjectSubscription from GraphQL JSON response
  factory ProjectSubscription.fromJson(Map<String, dynamic> json) {
    return ProjectSubscription(
      isActive: json['isActive'] as bool? ?? false,
      isTrial: json['isTrial'] as bool? ?? false,
      status: json['status'] as String? ?? 'UNKNOWN',
      canChoosePlan: json['canChoosePlan'] as bool? ?? false,
      hasExpired: json['hasExpired'] as bool? ?? false,
      currency: json['currency'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      renewalInterval: json['renewalInterval'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      renewsAt: json['renewsAt'] != null
          ? DateTime.parse(json['renewsAt'] as String)
          : null,
      prices: json['prices'] != null
          ? SubscriptionPrices.fromJson(json['prices'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Subscription pricing model
class SubscriptionPrices {
  final String currency;
  final double monthly;
  final double yearly;

  SubscriptionPrices({
    required this.currency,
    required this.monthly,
    required this.yearly,
  });

  /// Create SubscriptionPrices from GraphQL JSON response
  factory SubscriptionPrices.fromJson(Map<String, dynamic> json) {
    return SubscriptionPrices(
      currency: json['currency'] as String? ?? 'EUR',
      monthly: (json['monthly'] as num?)?.toDouble() ?? 0.0,
      yearly: (json['yearly'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
