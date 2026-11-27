import 'package:hospmaster/surgery/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Items users add to the patient form dropdowns (diagnosis, doctor, signs...).
/// They are cached in memory and, when Supabase is configured, saved to
/// `custom_field_options` so they show up for every later patient and user.
class CustomFieldOptions {
  CustomFieldOptions._();

  static final CustomFieldOptions instance = CustomFieldOptions._();

  static const String _table = 'custom_field_options';

  final Map<String, List<String>> _options = {};
  Future<void>? _loading;

  List<String> of(String field) =>
      List.unmodifiable(_options[field] ?? const <String>[]);

  /// Loads the saved items once; a failed load is retried on the next call.
  Future<void> load() {
    return _loading ??= _fetch().catchError((_) {
      _loading = null;
    });
  }

  Future<void> _fetch() async {
    if (!SurgerySupabaseConfig.isConfigured) return;
    final rows = await Supabase.instance.client
        .from(_table)
        .select('field, value')
        .order('created_at');
    for (final row in rows) {
      _remember(row['field'] as String, row['value'] as String);
    }
  }

  bool _remember(String field, String value) {
    final list = _options.putIfAbsent(field, () => []);
    final key = value.toLowerCase();
    if (list.any((option) => option.toLowerCase() == key)) return false;
    list.add(value);
    return true;
  }

  /// Makes [value] available right away and saves it for later sessions.
  Future<void> add(String field, String value) async {
    final text = value.trim();
    if (text.isEmpty || !_remember(field, text)) return;
    if (!SurgerySupabaseConfig.isConfigured) return;
    try {
      await Supabase.instance.client.from(_table).insert({
        'field': field,
        'value': text,
      });
    } catch (_) {
      // Kept in memory for this session if the table is missing or the
      // user is offline.
    }
  }
}
