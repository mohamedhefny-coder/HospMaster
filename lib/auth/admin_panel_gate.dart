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
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<AuthState>? _authSub;
  bool _busy = false;
  bool _obscure = true;
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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = Supabase.instance.client.auth;
    try {
      final response = await auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!isAdminUser(response.user)) {
        await auth.signOut();
        if (!mounted) return;
        setState(() {
          _error = tr(
            'هذا الحساب ليس لديه صلاحية المدير.',
            'This account does not have admin access.',
          );
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = tr(
            'تعذر الاتصال. حاول مرة أخرى.',
            'Could not connect. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    return Form(
      key: _formKey,
      child: Column(
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
              'سجّل الدخول بحساب المدير للمتابعة',
              'Sign in with an admin account to continue',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: tr('البريد الإلكتروني', 'Email'),
              prefixIcon: const Icon(Icons.email_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value?.trim() ?? '')
                ? null
                : tr('أدخل بريدًا إلكترونيًا صحيحًا', 'Enter a valid email'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _busy ? null : _signIn(),
            decoration: InputDecoration(
              labelText: tr('كلمة المرور', 'Password'),
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (value) => (value ?? '').isEmpty
                ? tr('أدخل كلمة المرور', 'Enter your password')
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _signIn,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr('تسجيل الدخول', 'Sign in')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: Text(tr('المتابعة باستخدام Google', 'Continue with Google')),
          ),
        ],
      ),
    );
  }
}
