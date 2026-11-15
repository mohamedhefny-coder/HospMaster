import 'package:flutter/material.dart';
import 'package:hospmaster/surgery/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a "Create account" button while signed out, and an account menu
/// (email + sign out) once the user is signed in.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (!SurgerySupabaseConfig.isConfigured) {
      return _CreateAccountButton(isArabic: isArabic);
    }
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) {
          return _CreateAccountButton(isArabic: isArabic);
        }
        return PopupMenuButton<String>(
          tooltip: user.email ?? '',
          icon: const Icon(Icons.account_circle_rounded),
          onSelected: (_) => auth.signOut(),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(user.email ?? ''),
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

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({required this.isArabic});

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
        tooltip: 'Create account',
        onPressed: () => _open(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilledButton.tonalIcon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text('Create account'),
      ),
    );
  }
}

/// Create account / sign in page backed by Supabase Auth.
class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.isArabic = true,
    this.startWithSignIn = false,
  });

  final bool isArabic;
  final bool startWithSignIn;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _isSignIn = widget.startWithSignIn;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  String tr(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!SurgerySupabaseConfig.isConfigured) {
      setState(() {
        _error = tr(
          'لم يتم إعداد Supabase في هذا التشغيل.',
          'Supabase is not configured for this run.',
        );
        _info = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final auth = Supabase.instance.client.auth;
    final email = _email.text.trim();
    try {
      if (_isSignIn) {
        await auth.signInWithPassword(email: email, password: _password.text);
      } else {
        final response = await auth.signUp(
          email: email,
          password: _password.text,
        );
        if (response.session == null) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _info = tr(
              'تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.',
              'Account created. Check your email to confirm it, then sign in.',
            );
            _isSignIn = true;
          });
          return;
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = tr(
          'تعذر الاتصال. حاول مرة أخرى.',
          'Could not connect. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignIn
        ? tr('تسجيل الدخول', 'Sign in')
        : tr('إنشاء حساب', 'Create account');
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
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
                        'سجّل لإنشاء المحتوى أو الاطلاع على المحتوى الموجود',
                        'Sign up to create content or view existing content',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: tr('البريد الإلكتروني', 'Email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(text)) {
                          return tr(
                            'أدخل بريدًا إلكترونيًا صحيحًا',
                            'Enter a valid email',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      autofillHints: [
                        _isSignIn
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: tr('كلمة المرور', 'Password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return tr(
                            'كلمة المرور 6 أحرف على الأقل',
                            'Password must be at least 6 characters',
                          );
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _info!,
                        style: const TextStyle(color: Color(0xFF15803D)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(title),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _isSignIn = !_isSignIn;
                              _error = null;
                              _info = null;
                            }),
                      child: Text(
                        _isSignIn
                            ? tr(
                                'ليس لديك حساب؟ إنشاء حساب',
                                "Don't have an account? Create account",
                              )
                            : tr(
                                'لديك حساب؟ تسجيل الدخول',
                                'Already have an account? Sign in',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
