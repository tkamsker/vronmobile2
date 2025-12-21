/// Model representing project subscription information from the VRon API
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
  final ProjectSubscriptionPrices prices;

  const ProjectSubscription({
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
    required this.prices,
  });

  /// Create ProjectSubscription from JSON (from API response)
  factory ProjectSubscription.fromJson(Map<String, dynamic> json) {
    return ProjectSubscription(
      isActive: json['isActive'] as bool? ?? false,
      isTrial: json['isTrial'] as bool? ?? false,
      status: json['status'] as String? ?? 'NOT_STARTED',
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
      prices: ProjectSubscriptionPrices.fromJson(
        json['prices'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Get user-friendly status label
  String get statusLabel {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'TRIAL_EXPIRED':
        return 'Trial Expired';
      case 'CANCELLED':
        return 'Cancelled';
      case 'NOT_STARTED':
        return 'Not Started';
      case 'PERMANENTLY_ACTIVE':
        return 'Permanently Active';
      case 'RENEWAL_FAILED':
        return 'Renewal Failed';
      default:
        return status;
    }
  }

  /// Get status color for UI
  String get statusColorHex {
    if (isActive) {
      return '#4CAF50'; // Green
    } else if (isTrial) {
      return '#FF9800'; // Orange
    } else if (hasExpired) {
      return '#F44336'; // Red
    } else {
      return '#9E9E9E'; // Gray
    }
  }

  @override
  String toString() {
    return 'ProjectSubscription(status: $status, isActive: $isActive, isTrial: $isTrial)';
  }
}

/// Model representing subscription pricing information
class ProjectSubscriptionPrices {
  final String currency;
  final double monthly;
  final double yearly;

  const ProjectSubscriptionPrices({
    required this.currency,
    required this.monthly,
    required this.yearly,
  });

  /// Create ProjectSubscriptionPrices from JSON
  factory ProjectSubscriptionPrices.fromJson(Map<String, dynamic> json) {
    return ProjectSubscriptionPrices(
      currency: json['currency'] as String? ?? 'EUR',
      monthly: json['monthly'] != null ? (json['monthly'] as num).toDouble() : 0.0,
      yearly: json['yearly'] != null ? (json['yearly'] as num).toDouble() : 0.0,
    );
  }

  /// Format price with currency symbol
  String formatPrice(double price) {
    final symbol = currency == 'USD' ? '\$' : '€';
    return '$symbol${price.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'ProjectSubscriptionPrices(currency: $currency, monthly: $monthly, yearly: $yearly)';
  }
}
