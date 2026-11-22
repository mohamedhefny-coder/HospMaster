import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String googleOAuthRedirectTo() {
  if (!kIsWeb) return 'io.supabase.flutter://login-callback/';

  var path = Uri.base.path;
  if (path.endsWith('index.html')) {
    path = path.substring(0, path.length - 'index.html'.length);
  }
  if (!path.endsWith('/')) path = '$path/';
  // Built from origin + path: Uri.replace(query: '', fragment: '') would leave
  // a trailing "?#" that no Supabase redirect allow-list entry matches.
  return '${Uri.base.origin}$path';
}

Future<bool> signInWithGoogle() {
  return Supabase.instance.client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: googleOAuthRedirectTo(),
  );
}
