import 'package:flutter/material.dart';
import 'package:hospmaster/auth/service_access.dart';
import 'package:hospmaster/auth/subscriber_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin screen: approve / reject service requests, manage users' services
/// and pre-approve new users by e-mail.
class AdminAccessPage extends StatefulWidget {
  const AdminAccessPage({super.key, this.isArabic = true});

  final bool isArabic;

  @override
  State<AdminAccessPage> createState() => _AdminAccessPageState();
}

class _AdminAccessPageState extends State<AdminAccessPage> {
  final _repository = ServiceAccessRepository();
  List<ServiceAccessEntry>? _entries;
  String? _error;
  bool _busy = false;

  String tr(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _repository.listAll();
      if (mounted) {
        setState(() {
          _entries = entries;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = accessErrorMessage(e, widget.isArabic));
      }
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accessErrorMessage(e, widget.isArabic))),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addUser() async {
    final user = await showDialog<_NewUser>(
      context: context,
      builder: (_) => _AddUserDialog(isArabic: widget.isArabic),
    );
    if (user == null) return;
    final ok = await _run(
      () => user.password.isEmpty
          ? _repository.grant(user.email, user.services)
          : _repository.createUser(user.email, user.password, user.services),
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.password.isEmpty
              ? tr('تمت إضافة المستخدم', 'User added')
              : tr('تم إنشاء الحساب', 'Account created'),
        ),
      ),
    );
  }

  Color _statusColor(AccessStatus status) => switch (status) {
    AccessStatus.approved => const Color(0xFF15803D),
    AccessStatus.rejected => const Color(0xFFB91C1C),
    AccessStatus.pending => const Color(0xFFB45309),
  };

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final pending = [
      for (final entry in entries ?? <ServiceAccessEntry>[])
        if (entry.status == AccessStatus.pending && entry.service != null)
          entry,
    ];
    final byEmail = <String, List<ServiceAccessEntry>>{};
    for (final entry in entries ?? <ServiceAccessEntry>[]) {
      if (entry.service == null) continue;
      byEmail.putIfAbsent(entry.email, () => []).add(entry);
    }
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr('المستخدمون والطلبات', 'Users & requests')),
            actions: [
              IconButton(
                tooltip: tr('تحديث', 'Refresh'),
                onPressed: _busy ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: tr('تسجيل الخروج', 'Sign out'),
                onPressed: () => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: '${tr('الطلبات', 'Requests')} (${pending.length})'),
                Tab(text: tr('المستخدمون', 'Users')),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _busy ? null : _addUser,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(tr('إضافة مستخدم', 'Add user')),
          ),
          body: _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : entries == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [_requestsTab(pending), _usersTab(byEmail)],
                ),
        ),
      ),
    );
  }

  Widget _requestsTab(List<ServiceAccessEntry> pending) {
    if (pending.isEmpty) {
      return Center(
        child: Text(tr('لا توجد طلبات معلقة', 'No pending requests')),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        for (final entry in pending)
          Card(
            child: ListTile(
              leading: Icon(entry.service!.icon),
              title: Text(entry.service!.label(widget.isArabic)),
              subtitle: Text(entry.email, textDirection: TextDirection.ltr),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: tr('قبول', 'Approve'),
                    color: const Color(0xFF15803D),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => _repository.setStatus(
                              entry.id,
                              AccessStatus.approved,
                            ),
                          ),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  IconButton(
                    tooltip: tr('رفض', 'Reject'),
                    color: const Color(0xFFB91C1C),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => _repository.setStatus(
                              entry.id,
                              AccessStatus.rejected,
                            ),
                          ),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _usersTab(Map<String, List<ServiceAccessEntry>> byEmail) {
    if (byEmail.isEmpty) {
      return Center(child: Text(tr('لا يوجد مستخدمون بعد', 'No users yet')));
    }
    final emails = byEmail.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        for (final email in emails)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      email,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final entry in byEmail[email]!)
                    ListTile(
                      dense: true,
                      leading: Icon(entry.service!.icon, size: 20),
                      title: Text(entry.service!.label(widget.isArabic)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.status.label(widget.isArabic),
                            style: TextStyle(
                              color: _statusColor(entry.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            enabled: !_busy,
                            onSelected: (value) => _run(() async {
                              switch (value) {
                                case 'approve':
                                  await _repository.setStatus(
                                    entry.id,
                                    AccessStatus.approved,
                                  );
                                case 'reject':
                                  await _repository.setStatus(
                                    entry.id,
                                    AccessStatus.rejected,
                                  );
                                case 'delete':
                                  await _repository.remove(entry.id);
                              }
                            }),
                            itemBuilder: (_) => [
                              if (entry.status != AccessStatus.approved)
                                PopupMenuItem(
                                  value: 'approve',
                                  child: Text(tr('قبول', 'Approve')),
                                ),
                              if (entry.status != AccessStatus.rejected)
                                PopupMenuItem(
                                  value: 'reject',
                                  child: Text(
                                    tr('رفض / سحب', 'Reject / revoke'),
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(tr('حذف', 'Delete')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NewUser {
  const _NewUser(this.email, this.password, this.services);

  final String email;
  final String password;
  final Set<HospService> services;
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({required this.isArabic});

  final bool isArabic;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final Set<HospService> _services = {};
  bool _obscure = true;
  String? _error;

  String tr(String ar, String en) => widget.isArabic ? ar : en;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save() {
    final email = _email.text.trim();
    final password = _password.text;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(
        () =>
            _error = tr('أدخل بريدًا إلكترونيًا صحيحًا', 'Enter a valid email'),
      );
      return;
    }
    if (password.isNotEmpty && password.length < 6) {
      setState(
        () => _error = tr(
          'كلمة المرور 6 أحرف على الأقل',
          'Password must be at least 6 characters',
        ),
      );
      return;
    }
    if (_services.isEmpty) {
      setState(
        () => _error = tr(
          'اختر خدمة واحدة على الأقل',
          'Pick at least one service',
        ),
      );
      return;
    }
    Navigator.pop(context, _NewUser(email, password, Set.of(_services)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        title: Text(tr('إضافة مستخدم', 'Add user')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(
                  'أدخل كلمة مرور لإنشاء الحساب فورًا. أو اتركها فارغة ليحصل المستخدم على الخدمات عند تسجيله بهذا البريد.',
                  'Enter a password to create the account now, or leave it empty so the user gets the services when they sign up with this email.',
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: tr('البريد الإلكتروني', 'Email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: tr('كلمة المرور (اختياري)', 'Password (optional)'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final service in HospService.values)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(service.label(widget.isArabic)),
                  value: _services.contains(service),
                  onChanged: (value) => setState(() {
                    if (value ?? false) {
                      _services.add(service);
                    } else {
                      _services.remove(service);
                    }
                  }),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('إلغاء', 'Cancel')),
          ),
          FilledButton(onPressed: _save, child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
  }
}
