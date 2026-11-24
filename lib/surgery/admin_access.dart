import 'package:supabase_flutter/supabase_flutter.dart';

bool isAdminUser(User? user) {
  final role = user?.appMetadata['role'];
  return role == 'admin';
}

/// Safe even when Supabase was never initialised (e.g. guest mode).
bool isCurrentUserAdmin() {
  try {
    return isAdminUser(Supabase.instance.client.auth.currentUser);
  } catch (_) {
    return false;
  }
}
