import 'package:flutter/material.dart';
import 'package:hospmaster/auth/account_button.dart';
import 'package:hospmaster/auth/admin_panel_gate.dart';
import 'package:hospmaster/auth/subscriber_gate.dart';
import 'package:hospmaster/surgery/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// First screen of the app: lets the user continue as a guest or sign in as
/// a subscriber.
class ModeSelectionPage extends StatefulWidget {
  const ModeSelectionPage({
    super.key,
    required this.dashboardBuilder,
    this.isArabic = true,
    this.autoOpen = true,
  });

  final DashboardBuilder dashboardBuilder;
  final bool isArabic;

  /// When false, a signed-in user stays on this page instead of being sent
  /// straight to the dashboard (used when returning from the dashboard).
  final bool autoOpen;

  @override
  State<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends State<ModeSelectionPage> {
  bool _opened = false;

  bool get isArabic => widget.isArabic;
  DashboardBuilder get dashboardBuilder => widget.dashboardBuilder;

  String tr(String ar, String en) => isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autoOpen && _signedIn) {
        _openDashboard(context, isGuest: false);
      }
    });
  }

  void _openDashboard(BuildContext context, {required bool isGuest}) {
    if (_opened) return;
    _opened = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => isGuest
            ? dashboardBuilder(context, true, null)
            : SubscriberGate(
                dashboardBuilder: dashboardBuilder,
                isArabic: isArabic,
                signedOutBuilder: (_) => ModeSelectionPage(
                  dashboardBuilder: dashboardBuilder,
                  isArabic: isArabic,
                ),
              ),
      ),
    );
  }

  bool get _signedIn =>
      SurgerySupabaseConfig.isConfigured &&
      Supabase.instance.client.auth.currentUser != null;

  Future<void> _subscriber(BuildContext context) async {
    if (!_signedIn) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => AuthPage(isArabic: isArabic)),
      );
    }
    if (context.mounted && _signedIn) {
      _openDashboard(context, isGuest: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ModeCard(
        icon: Icons.person_outline_rounded,
        title: 'Guest Mode',
        subtitle: tr(
          'تصفّح التطبيق بدون تسجيل الدخول',
          'Browse the app without signing in',
        ),
        color: const Color(0xFF1585A6),
        onTap: () => _openDashboard(context, isGuest: true),
      ),
      _ModeCard(
        icon: Icons.verified_user_outlined,
        title: 'Subscriber Mode',
        subtitle: tr(
          'سجّل الدخول للوصول إلى كل الميزات',
          'Sign in to access all features',
        ),
        color: const Color(0xFF102A43),
        onTap: () => _subscriber(context),
      ),
    ];
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SecretTapLogo(
                      onUnlocked: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdminPanelGate(isArabic: isArabic),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 16),
                              cards[1],
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                            ],
                          ),
                        );
                      },
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

class _SecretTapLogo extends StatefulWidget {
  const _SecretTapLogo({required this.child, required this.onUnlocked});

  final Widget child;
  final VoidCallback onUnlocked;

  @override
  State<_SecretTapLogo> createState() => _SecretTapLogoState();
}

/// Counts quick consecutive taps; five taps with less than two seconds
/// between them trigger [_SecretTapLogo.onUnlocked].
class _SecretTapLogoState extends State<_SecretTapLogo> {
  static const _requiredTaps = 5;
  static const _maxGap = Duration(seconds: 2);

  int _taps = 0;
  DateTime? _lastTap;

  void _onTap() {
    final now = DateTime.now();
    final last = _lastTap;
    _taps = last != null && now.difference(last) <= _maxGap ? _taps + 1 : 1;
    _lastTap = now;
    if (_taps >= _requiredTaps) {
      _taps = 0;
      _lastTap = null;
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child: widget.child);
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color,
                child: Icon(icon, size: 34, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
