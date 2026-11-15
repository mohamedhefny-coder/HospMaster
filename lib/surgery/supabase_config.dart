import 'package:supabase_flutter/supabase_flutter.dart';

class SurgerySupabaseConfig {
  static const _url = String.fromEnvironment('HOSPMASTER_SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'HOSPMASTER_SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: _url,
      publishableKey: _publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      storageOptions: const StorageClientOptions(retryAttempts: 3),
    );
  }
}
