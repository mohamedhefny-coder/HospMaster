import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hospmaster/auth/service_access.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef DashboardBuilder =
    Widget Function(
      BuildContext context,
      bool isGuest,
      Set<HospService>? services,
    );

String accessErrorMessage(Object error, bool isArabic) {
  if (error is FunctionException) {
    if (error.status == 404) {
      return isArabic
          ? 'دالة admin-create-user غير منشورة. شغّل: supabase functions deploy admin-create-user'
          : 'The admin-create-user function is not deployed. Run: supabase functions deploy admin-create-user';
    }
    final details = error.details;
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
  }
  final text = error.toString();
  if (text.contains('PGRST205') || text.contains('service_access')) {
    return isArabic
        ? 'جدول service_access غير موجود. شغّل ملف supabase/migrations/20261118_service_access.sql في Supabase ثم أعد المحاولة.'
        : 'The service_access table is missing. Run supabase/migrations/20261118_service_access.sql in Supabase and try again.';
  }
  if (text.contains('23505')) {
    return isArabic
        ? 'هذا الطلب موجود بالفعل.'
        : 'This request already exists.';
  }
  return isArabic
      ? 'تعذر الاتصال. حاول مرة أخرى.'
      : 'Could not connect. Please try again.';
}

/// Opens the dashboard for a signed-in subscriber with only the services an
/// admin approved. Users without any approved service see the request page
/// until an admin accepts them.
class SubscriberGate extends StatefulWidget {
  const SubscriberGate({
    super.key,
    required this.dashboardBuilder,
    required this.signedOutBuilder,
    this.isArabic = true,
  });

  final DashboardBuilder dashboardBuilder;
  final WidgetBuilder signedOutBuilder;
  final bool isArabic;

  @override
  State<SubscriberGate> createState() => _SubscriberGateState();
}

class _SubscriberGateState extends State<SubscriberGate> {
  ServiceAccess? _access;
  Object? _error;
  StreamSubscription<AuthState>? _authSub;

  String tr(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: widget.signedOutBuilder),
          (_) => false,
        );
      }
    });
    _load();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final access = await ServiceAccessRepository().loadMine();
      if (mounted) setState(() => _access = access);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = _access;
    if (access != null && access.hasAccess) {
      return widget.dashboardBuilder(context, false, access.approved);
    }
    if (access != null) {
      return ServiceRequestPage(
        isArabic: widget.isArabic,
        initialAccess: access,
        onApproved: (updated) => setState(() => _access = updated),
      );
    }
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        accessErrorMessage(_error!, widget.isArabic),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: Text(tr('إعادة المحاولة', 'Retry')),
                      ),
                      TextButton(
                        onPressed: () =>
                            Supabase.instance.client.auth.signOut(),
                        child: Text(tr('تسجيل الخروج', 'Sign out')),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Lets a user pick the services they want and shows the status of earlier
/// requests. [onApproved] fires when a refresh finds at least one approved
/// service.
class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({
    super.key,
    this.isArabic = true,
    this.initialAccess,
    this.onApproved,
  });

  final bool isArabic;
  final ServiceAccess? initialAccess;
  final ValueChanged<ServiceAccess>? onApproved;

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  late ServiceAccess? _access = widget.initialAccess;
  final Set<HospService> _selected = {};
  bool _busy = false;
  String? _error;

  String tr(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    if (_access == null) _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final access = await ServiceAccessRepository().loadMine();
      if (!mounted) return;
      setState(() {
        _access = access;
        _busy = false;
      });
      if (access.hasAccess) widget.onApproved?.call(access);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = accessErrorMessage(e, widget.isArabic);
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ServiceAccessRepository().request(_selected);
      _selected.clear();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = accessErrorMessage(e, widget.isArabic);
      });
    }
  }

  Color _statusColor(AccessStatus status) => switch (status) {
    AccessStatus.approved => const Color(0xFF15803D),
    AccessStatus.rejected => const Color(0xFFB91C1C),
    AccessStatus.pending => const Color(0xFFB45309),
  };

  @override
  Widget build(BuildContext context) {
    final access = _access;
    final hasPending =
        access?.statuses.values.contains(AccessStatus.pending) ?? false;
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('خدماتي', 'My services')),
          actions: [
            IconButton(
              tooltip: tr('تحديث', 'Refresh'),
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: tr('تسجيل الخروج', 'Sign out'),
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr(
                      'اختر الخدمة التي تريد الاشتراك فيها، وسيصلك الوصول بعد موافقة المسؤول.',
                      'Choose the services you need. Access starts once an admin approves your request.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasPending) ...[
                    const SizedBox(height: 12),
                    Text(
                      tr(
                        'طلبك قيد المراجعة. اضغط تحديث للتحقق من الموافقة.',
                        'Your request is under review. Tap refresh to check for approval.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFB45309)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (access == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    for (final service in HospService.values)
                      _serviceTile(service, access.statuses[service]),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy || _selected.isEmpty ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(tr('إرسال الطلب', 'Send request')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceTile(HospService service, AccessStatus? status) {
    if (status != null) {
      return Card(
        child: ListTile(
          leading: Icon(service.icon),
          title: Text(service.label(widget.isArabic)),
          trailing: Text(
            status.label(widget.isArabic),
            style: TextStyle(
              color: _statusColor(status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Card(
      child: CheckboxListTile(
        secondary: Icon(service.icon),
        title: Text(service.label(widget.isArabic)),
        value: _selected.contains(service),
        onChanged: _busy
            ? null
            : (value) => setState(() {
                if (value ?? false) {
                  _selected.add(service);
                } else {
                  _selected.remove(service);
                }
              }),
      ),
    );
  }
}
