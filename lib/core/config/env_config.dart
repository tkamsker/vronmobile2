import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loader
/// Provides access to environment variables from .env file
/// PRD Reference: Requirements/Google_OAuth.prd.md Section 8.1
class EnvConfig {
  /// Initializes the environment configuration by loading the .env file
  /// Should be called once at app startup before runApp()
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  /// VRon API base URI (without /graphql)
  /// Example: https://api.vron.stage.motorenflug.at
  static String get vronApiUri {
    return dotenv.env['VRON_API_URI'] ??
        'https://api.vron.stage.motorenflug.at';
  }

  /// GraphQL HTTP endpoint for queries and mutations
  /// Derived from vronApiUri + /graphql
  static String get graphqlEndpoint {
    return '$vronApiUri/graphql';
  }

  /// GraphQL WebSocket endpoint for subscriptions
  /// Derived from vronApiUri (https → wss) + /graphql
  static String get graphqlWsEndpoint {
    final wsUri = vronApiUri.replaceFirst('https://', 'wss://');
    return '$wsUri/graphql';
  }

  /// VRon Merchants web app URL
  /// Example: https://app.vron.stage.motorenflug.at
  static String get vronMerchantsUrl {
    return dotenv.env['VRON_MERCHANTS_URL'] ??
        'https://app.vron.stage.motorenflug.at';
  }

  /// VRon Projects page URL
  /// Full URL to the projects management page in the web app
  static String get projectsPageUrl {
    return '$vronMerchantsUrl/en/app/projects';
  }

  /// Cookie domain for web-based authentication
  /// Example: .motorenflug.at
  static String get appCookieDomain {
    return dotenv.env['APP_COOKIE_DOMAIN'] ?? '.motorenflug.at';
  }

  /// Current environment (development, staging, production)
  static String get environment {
    return dotenv.env['ENV'] ?? 'development';
  }

  /// Debug mode flag
  static bool get isDebug {
    final debug = dotenv.env['DEBUG'] ?? 'false';
    return debug.toLowerCase() == 'true';
  }

  /// Backwards compatibility: Merchant web app base URL
  /// @deprecated Use vronMerchantsUrl instead
  static String get merchantUrl => vronMerchantsUrl;

  // BlenderAPI Configuration (for USDZ to GLB conversion)
  // PRD Reference: Requirements/FLUTTER_API_PRD.md

  /// BlenderAPI base URL for USDZ→GLB conversion
  /// Example: https://blenderapi.stage.motorenflug.at
  static String get blenderApiBaseUrl {
    return dotenv.env['BLENDER_API_BASE_URL'] ??
        'https://blenderapi.stage.motorenflug.at';
  }

  /// BlenderAPI authentication key (obtain from administrator)
  /// Minimum 16 characters required
  static String get blenderApiKey {
    final key = dotenv.env['BLENDER_API_KEY'] ?? '';
    if (key.isEmpty || key == 'your-api-key-here-min-16-chars') {
      throw Exception(
        'BLENDER_API_KEY not configured in .env file. Please add a valid API key (minimum 16 characters).',
      );
    }
    return key;
  }

  /// BlenderAPI processing timeout in seconds (default: 900 = 15 minutes)
  static int get blenderApiTimeoutSeconds {
    final timeout = dotenv.env['BLENDER_API_TIMEOUT_SECONDS'];
    return timeout != null ? int.tryParse(timeout) ?? 900 : 900;
  }

  /// BlenderAPI status polling interval in seconds (default: 2 seconds)
  static int get blenderApiPollIntervalSeconds {
    final interval = dotenv.env['BLENDER_API_POLL_INTERVAL_SECONDS'];
    return interval != null ? int.tryParse(interval) ?? 2 : 2;
  }

  // Room Stitching Canvas Configuration
  // PRD Reference: specs/017-room-stitching/spec.md

  /// Room rotation increment in degrees (default: 45)
  /// Used when user taps Rotate button on canvas
  static int get roomRotationDegrees {
    final degrees = dotenv.env['ROOM_ROTATION_DEGREES'];
    final value = degrees != null ? int.tryParse(degrees) ?? 45 : 45;
    // Validate: must be between 1 and 90 degrees
    if (value < 1 || value > 90) {
      return 45; // fallback to default
    }
    return value;
  }

  /// Door connection suggestion threshold in pixels (default: 50)
  /// Doors within this distance will show connection suggestion
  static int get doorConnectionThreshold {
    final threshold = dotenv.env['DOOR_CONNECTION_THRESHOLD'];
    return threshold != null ? int.tryParse(threshold) ?? 50 : 50;
  }

  /// Canvas grid size in pixels (default: 20, 0 = disabled)
  /// Optional grid overlay for room positioning
  static int get canvasGridSize {
    final gridSize = dotenv.env['CANVAS_GRID_SIZE'];
    return gridSize != null ? int.tryParse(gridSize) ?? 20 : 20;
  }
}
