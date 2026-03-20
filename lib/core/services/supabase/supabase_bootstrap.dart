import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_env.dart';

class SupabaseBootstrap {
  static bool _initialized = false;
  static Object? _error;

  static Future<void> initialize() async {
    if (!AppEnv.hasSupabaseConfig || _initialized) {
      return;
    }

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        anonKey: AppEnv.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _initialized = true;
      _error = null;
    } catch (error) {
      _error = error;
    }
  }

  static bool get isConfigured => AppEnv.hasSupabaseConfig;
  static bool get isReady => isConfigured && _initialized && _error == null;
  static String? get errorMessage => _error?.toString();
  static SupabaseClient? get client => isReady ? Supabase.instance.client : null;
}
