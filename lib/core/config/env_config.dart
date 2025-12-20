import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loader
/// Provides access to environment variables from .env file
class EnvConfig {
  /// Initializes the environment configuration by loading the .env file
  /// Should be called once at app startup before runApp()
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  /// GraphQL HTTP endpoint for queries and mutations
  static String get graphqlEndpoint {
    return dotenv.env['GRAPHQL_ENDPOINT'] ?? 'https://api.vron.stage.motorenflug.at/graphql';
  }

  /// GraphQL WebSocket endpoint for subscriptions
  static String get graphqlWsEndpoint {
    return dotenv.env['GRAPHQL_WS_ENDPOINT'] ?? 'wss://api.vron.stage.motorenflug.at/graphql';
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
}
