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
}
