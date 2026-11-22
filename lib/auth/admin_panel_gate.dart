import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hospmaster/auth/admin_access_page.dart';
import 'package:hospmaster/auth/google_oauth.dart';
import 'package:hospmaster/surgery/admin_access.dart';
import 'package:hospmaster/surgery/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Opens the admin panel only for a signed-in admin; everyone else gets an
/// admin sign-in form first.
class AdminPanelGate extends StatefulWidget {
  const AdminPanelGate({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  State<AdminPanelGate> createState() => _AdminPanelGateState();
}

class _AdminPanelGateState extends State<AdminPanelGate> {
  StreamSubscription<AuthState>? _authSub;
  bool _busy = false;
  bool _googleSignInPending = false;
  String? _error;

  String tr(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    if (SurgerySupabaseConfig.isConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
        state,
      ) async {
        if (!mounted || !_googleSignInPending) return;
        if (state.event == AuthChangeEvent.signedIn) {
          _googleSignInPending = false;
          if (!isAdminUser(state.session?.user)) {
            await Supabase.instance.client.auth.signOut();
            if (!mounted) return;
            setState(() {
              _error = tr(
                'هذا الحساب ليس لديه صلاحية المدير.',
                'This account does not have admin access.',
              );
            });
          } else {
            setState(() {});
          }
        }
      });
    }
  }

  Future<void> _signInWithGoogle() async {
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
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = SurgerySupabaseConfig.isConfigured;
    if (configured && isAdminUser(Supabase.instance.client.auth.currentUser)) {
      return AdminAccessPage(isArabic: widget.isArabic);
    }
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('لوحة تحكم المدير', 'Admin panel'))),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: !configured
                  ? Text(
                      tr(
                        'لم يتم إعداد Supabase في هذا التشغيل.',
                        'Supabase is not configured for this run.',
                      ),
                      textAlign: TextAlign.center,
                    )
                  : _form(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.admin_panel_settings_outlined,
          size: 56,
          color: Color(0xFF102A43),
        ),
        const SizedBox(height: 8),
        Text(
          tr(
            'سجّل الدخول بحساب Google الخاص بالمدير للمتابعة',
            'Sign in with the admin Google account to continue',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
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
          label: Text(tr('المتابعة باستخدام Google', 'Continue with Google')),
        ),
      ],
    );
  }
}
