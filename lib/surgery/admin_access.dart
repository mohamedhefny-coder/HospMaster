import 'package:supabase_flutter/supabase_flutter.dart';

bool isAdminUser(User? user) {
  final role = user?.appMetadata['role'];
  return role == 'admin';
}
