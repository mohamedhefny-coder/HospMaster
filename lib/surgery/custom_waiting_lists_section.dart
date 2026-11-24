import 'package:flutter/material.dart';
import 'package:hospmaster/surgery/pediatric_surgery_waiting_repository.dart';
import 'package:hospmaster/surgery/surgery_department_page.dart';

typedef WaitingListCardBuilder =
    Widget Function({
      required String title,
      required String arabicTitle,
      required String arabicDescription,
      required String description,
      required IconData icon,
      required List<Color> colors,
      required VoidCallback onTap,
    });

/// Waiting lists of the other medical departments. Admins create a list,
/// name it and add its doctors; everyone with access can open the lists.
class CustomWaitingListsSection extends StatefulWidget {
  const CustomWaitingListsSection({
    super.key,
    required this.repository,
    required this.canManage,
    required this.cardBuilder,
    required this.wide,
  });

  final WaitingListsRepository repository;

  /// Admins (and guests trying the demo) can create, rename and delete lists.
  final bool canManage;
  final WaitingListCardBuilder cardBuilder;
  final bool wide;

  @override
  State<CustomWaitingListsSection> createState() =>
      _CustomWaitingListsSectionState();
}

class _CustomWaitingListsSectionState extends State<CustomWaitingListsSection> {
  static const _palettes = <List<Color>>[
    [Color(0xFF0F766E), Color(0xFF14B8A6)],
    [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
    [Color(0xFF7C3AED), Color(0xFFEC4899)],
    [Color(0xFF166534), Color(0xFF84CC16)],
    [Color(0xFF9A3412), Color(0xFFF59E0B)],
  ];

  List<WaitingList>? _lists;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final lists = await widget.repository.fetchLists();
      if (mounted) setState(() => _lists = lists);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _errorText(Object error) {
    final text = '$error';
    if (text.contains('PGRST205') || text.contains('waiting_lists')) {
      return 'شغّل ملف 20261124_custom_waiting_lists.sql في Supabase أولاً.';
    }
    return 'تعذر تحميل القوائم: $text';
  }

  Future<void> _open(WaitingList list) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PediatricSurgeryDoctorsPage(
          title: list.name,
          customList: true,
          waitingRepository: widget.repository.waitingRepositoryFor(list.id),
          doctorsRepository: widget.repository.doctorsRepositoryFor(list.id),
        ),
      ),
    );
  }

  Future<void> _create() async {
    final draft = await showDialog<_NewListDraft>(
      context: context,
      builder: (_) => const _NewListDialog(),
    );
    if (draft == null) return;
    try {
      final list = await widget.repository.createList(draft.name);
      final doctors = widget.repository.doctorsRepositoryFor(list.id);
      for (final doctor in draft.doctors) {
        await doctors.addDoctor(doctor);
      }
      _message('تم إنشاء القائمة');
    } catch (error) {
      _message(
        '$error'.contains('duplicate') || '$error'.contains('23505')
            ? 'يوجد قائمة بنفس الاسم'
            : _errorText(error),
      );
    }
    await _load();
  }

  Future<void> _rename(WaitingList list) async {
    final controller = TextEditingController(text: list.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل اسم القائمة'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اسم القائمة',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == list.name) return;
    try {
      await widget.repository.renameList(list.id, name);
    } catch (error) {
      _message('تعذر تعديل القائمة. هذه الصلاحية للأدمن فقط.');
    }
    await _load();
  }

  Future<void> _delete(WaitingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف القائمة'),
          content: Text(
            'سيتم حذف قائمة "${list.name}" بكل أطبائها ومرضاها وصورهم نهائياً. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final waiting = widget.repository.waitingRepositoryFor(list.id);
      final patients = await waiting.fetchPatients();
      await widget.repository.deleteList(list.id);
      await waiting.removeImages([
        for (final patient in patients)
          for (final image in patient.images)
            if (image['path'] is String) image['path'] as String,
      ]);
      _message('تم حذف القائمة');
    } catch (error) {
      _message('تعذر حذف القائمة. هذه الصلاحية للأدمن فقط.');
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final lists = _lists;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'قوائم انتظار الأقسام الأخرى',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.canManage)
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إنشاء قائمة'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_error != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  _errorText(_error!),
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
              TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          )
        else if (lists == null)
          const Center(child: CircularProgressIndicator())
        else if (lists.isEmpty)
          Text(
            widget.canManage
                ? 'لا توجد قوائم بعد. اضغط "إنشاء قائمة" لإضافة قائمة لقسم جديد.'
                : 'لا توجد قوائم أخرى بعد.',
            style: const TextStyle(color: Color(0xFF718096)),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var i = 0; i < lists.length; i++)
                SizedBox(
                  width: widget.wide ? 310 : double.infinity,
                  child: Stack(
                    children: [
                      widget.cardBuilder(
                        title: lists[i].name,
                        arabicTitle: lists[i].name,
                        arabicDescription: 'قائمة انتظار حسب الطبيب',
                        description: 'Waiting list by doctor',
                        icon: Icons.format_list_numbered_rounded,
                        colors: _palettes[i % _palettes.length],
                        onTap: () => _open(lists[i]),
                      ),
                      if (widget.canManage)
                        PositionedDirectional(
                          bottom: 4,
                          end: 4,
                          child: PopupMenuButton<String>(
                            tooltip: 'إدارة القائمة',
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white,
                            ),
                            onSelected: (value) => value == 'rename'
                                ? _rename(lists[i])
                                : _delete(lists[i]),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('تعديل الاسم'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف القائمة'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _NewListDraft {
  const _NewListDraft(this.name, this.doctors);

  final String name;
  final List<String> doctors;
}

class _NewListDialog extends StatefulWidget {
  const _NewListDialog();

  @override
  State<_NewListDialog> createState() => _NewListDialogState();
}

class _NewListDialogState extends State<_NewListDialog> {
  final _name = TextEditingController();
  final _doctor = TextEditingController();
  final List<String> _doctors = [];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _doctor.dispose();
    super.dispose();
  }

  void _addDoctor() {
    final value = _doctor.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_doctors.contains(value)) _doctors.add(value);
      _doctor.clear();
    });
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'أدخل اسم القائمة');
      return;
    }
    _addDoctor();
    Navigator.pop(context, _NewListDraft(name, List.of(_doctors)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('قائمة انتظار جديدة'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'اسم القائمة (مثال: جراحة العظام)',
                    prefixIcon: const Icon(Icons.list_alt_rounded),
                    border: const OutlineInputBorder(),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _doctor,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addDoctor(),
                  decoration: InputDecoration(
                    labelText: 'إضافة طبيب (اختياري)',
                    hintText: 'مثال: د. محمد أحمد',
                    prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'إضافة',
                      onPressed: _addDoctor,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ),
                if (_doctors.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final doctor in _doctors)
                        InputChip(
                          label: Text(doctor),
                          onDeleted: () =>
                              setState(() => _doctors.remove(doctor)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(onPressed: _submit, child: const Text('إنشاء')),
        ],
      ),
    );
  }
}
