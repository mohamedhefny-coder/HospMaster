import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hospmaster/auth/google_oauth.dart';
import 'package:hospmaster/auth/subscriber_gate.dart';
import 'package:hospmaster/surgery/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a "Sign in" button while signed out, and an account menu
/// (email + sign out) once the user is signed in.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (!SurgerySupabaseConfig.isConfigured) {
      return _SignInButton(isArabic: isArabic);
    }
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) {
          return _SignInButton(isArabic: isArabic);
        }
        return PopupMenuButton<String>(
          tooltip: user.email ?? '',
          icon: const Icon(Icons.account_circle_rounded),
          onSelected: (value) {
            switch (value) {
              case 'my_services':
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceRequestPage(isArabic: isArabic),
                  ),
                );
              default:
                auth.signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(user.email ?? ''),
            ),
            PopupMenuItem<String>(
              value: 'my_services',
              child: Text(isArabic ? 'خدماتي' : 'My services'),
            ),
            PopupMenuItem<String>(
              value: 'sign_out',
              child: Text(isArabic ? 'تسجيل الخروج' : 'Sign out'),
            ),
          ],
        );
      },
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.isArabic});

  final bool isArabic;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AuthPage(isArabic: isArabic)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 480;
    if (narrow) {
      return IconButton(
        tooltip: isArabic ? 'تسجيل الدخول' : 'Sign in',
        onPressed: () => _open(context),
        icon: const Icon(Icons.login_rounded),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilledButton.tonalIcon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.login_rounded, size: 18),
        label: Text(isArabic ? 'تسجيل الدخول' : 'Sign in'),
      ),
    );
  }
}

/// Sign-in page backed by Supabase Auth. Google is the only sign-in method.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _busy = false;
  bool _googleSignInPending = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  String tr(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    if (SurgerySupabaseConfig.isConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
        state,
      ) {
        if (state.event == AuthChangeEvent.signedIn &&
            _googleSignInPending &&
            mounted) {
          _googleSignInPending = false;
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (!SurgerySupabaseConfig.isConfigured) {
      setState(() {
        _error = tr(
          'لم يتم إعداد Supabase في هذا التشغيل.',
          'Supabase is not configured for this run.',
        );
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _googleSignInPending = true;
    });
    try {
      final launched = await signInWithGoogle();
      if (!launched && mounted) {
        setState(() {
          _googleSignInPending = false;
          _error = tr(
            'تعذر بدء تسجيل الدخول عبر Google.',
            'Could not start Google sign-in.',
          );
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _googleSignInPending = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _googleSignInPending = false;
          _error = tr(
            'تعذر تسجيل الدخول عبر Google. تحقق من إعدادات Supabase.',
            'Google sign-in failed. Check the Supabase configuration.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('تسجيل الدخول', 'Sign in'))),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    size: 56,
                    color: Color(0xFF1585A6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'سجّل الدخول بحساب Google للمتابعة',
                      'Sign in with your Google account to continue',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _busy ? null : _signInWithGoogle,
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata, size: 24),
                    label: Text(
                      tr('المتابعة باستخدام Google', 'Continue with Google'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
