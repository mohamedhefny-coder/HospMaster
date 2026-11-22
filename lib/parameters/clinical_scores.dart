import 'package:flutter/material.dart';

const _navy = Color(0xFF172B4D);
const _purple = Color(0xFF7A4CB3);

/// Scoring tools shown in the "scores" tab. The content is always English,
/// regardless of the app language.
class ClinicalScoresSection extends StatelessWidget {
  const ClinicalScoresSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Clinical support only; it does not replace examination and clinical judgment.',
              style: TextStyle(
                color: Color(0xFF9B2C2C),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
          _AlvaradoCard(),
          SizedBox(height: 12),
          _ApgarCard(),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: CircleAvatar(
            backgroundColor: _purple.withValues(alpha: 0.12),
            child: Icon(icon, color: _purple),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF718096), fontSize: 11),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: children,
        ),
      ),
    );
  }
}

class _ScoreResult extends StatelessWidget {
  const _ScoreResult({
    required this.total,
    required this.max,
    required this.label,
    required this.color,
    required this.onReset,
  });

  final int total;
  final int max;
  final String label;
  final Color color;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Text(
                '$total / $max',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset'),
          ),
        ),
      ],
    );
  }
}

class _AlvaradoItem {
  const _AlvaradoItem(this.label, this.points);

  final String label;
  final int points;
}

const _alvaradoGroups = <(String, List<_AlvaradoItem>)>[
  (
    'Symptoms',
    [
      _AlvaradoItem('Migratory right iliac fossa pain', 1),
      _AlvaradoItem('Anorexia', 1),
      _AlvaradoItem('Nausea / vomiting', 1),
    ],
  ),
  (
    'Signs',
    [
      _AlvaradoItem('Tenderness in right iliac fossa', 2),
      _AlvaradoItem('Rebound tenderness', 1),
      _AlvaradoItem('Elevated temperature', 1),
    ],
  ),
  (
    'Laboratory findings',
    [
      _AlvaradoItem('Leucocytosis', 2),
      _AlvaradoItem('Shift to the left of neutrophils', 1),
    ],
  ),
];

class _AlvaradoCard extends StatefulWidget {
  const _AlvaradoCard();

  @override
  State<_AlvaradoCard> createState() => _AlvaradoCardState();
}

class _AlvaradoCardState extends State<_AlvaradoCard> {
  final Set<String> _checked = {};

  int get _total => [
    for (final (_, items) in _alvaradoGroups)
      for (final item in items)
        if (_checked.contains(item.label)) item.points,
  ].fold(0, (a, b) => a + b);

  (String, Color) get _interpretation {
    final total = _total;
    if (total <= 4) {
      return ('Appendicitis unlikely', const Color(0xFF15803D));
    }
    if (total <= 6) {
      return (
        'Possible: observation or imaging advised',
        const Color(0xFFB45309),
      );
    }
    if (total <= 8) {
      return (
        'Probable: surgical consultation advised',
        const Color(0xFFEA580C),
      );
    }
    return (
      'Very probable: urgent surgical consultation',
      const Color(0xFFB91C1C),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _interpretation;
    return _ScoreCard(
      initiallyExpanded: true,
      icon: Icons.fact_check_outlined,
      title: 'Alvarado Score (Appendicitis)',
      subtitle: 'Tick the findings present',
      children: [
        for (final (group, items) in _alvaradoGroups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
            child: Text(
              group,
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          for (final item in items)
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checked.contains(item.label),
              onChanged: (value) => setState(() {
                if (value ?? false) {
                  _checked.add(item.label);
                } else {
                  _checked.remove(item.label);
                }
              }),
              title: Text(item.label),
              secondary: Text(
                '+${item.points}',
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        _ScoreResult(
          total: _total,
          max: 10,
          label: label,
          color: color,
          onReset: _checked.isEmpty ? null : () => setState(_checked.clear),
        ),
      ],
    );
  }
}

class _ApgarCriterion {
  const _ApgarCriterion(this.name, this.options);

  final String name;

  /// Descriptions for 0, 1 and 2 points.
  final List<String> options;
}

const _apgarCriteria = [
  _ApgarCriterion('Heart rate (per minute)', ['Absent', '< 100', '≥ 100']),
  _ApgarCriterion('Respiration', [
    'Absent',
    'Irregular, slow',
    'Crying, active',
  ]),
  _ApgarCriterion('Color', [
    'Blue / pale',
    'Pink torso, blue extremities',
    'Pink',
  ]),
  _ApgarCriterion('Muscle tone', ['Limp', 'Mild flexion', 'Active']),
  _ApgarCriterion('Irritability', ['No response', 'Grimace', 'Sneeze']),
];

class _ApgarCard extends StatefulWidget {
  const _ApgarCard();

  @override
  State<_ApgarCard> createState() => _ApgarCardState();
}

class _ApgarCardState extends State<_ApgarCard> {
  final Map<int, int> _points = {};

  int get _total => _points.values.fold(0, (a, b) => a + b);
  bool get _complete => _points.length == _apgarCriteria.length;

  (String, Color) get _interpretation {
    if (!_complete) {
      return ('Choose a value for every item', const Color(0xFF718096));
    }
    final total = _total;
    if (total >= 7) {
      return ('Normal / reassuring', const Color(0xFF15803D));
    }
    if (total >= 4) {
      return ('Moderately low: may need assistance', const Color(0xFFB45309));
    }
    return ('Low: needs immediate resuscitation', const Color(0xFFB91C1C));
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _interpretation;
    return _ScoreCard(
      initiallyExpanded: true,
      icon: Icons.child_friendly_outlined,
      title: 'Apgar Score (Newborn)',
      subtitle: 'Performed at 1, 5, and 10 min',
      children: [
        for (var i = 0; i < _apgarCriteria.length; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
            child: Text(
              _apgarCriteria[i].name,
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          for (var p = 0; p < 3; p++)
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _points[i] == p,
              onChanged: (value) => setState(() {
                if (value ?? false) {
                  _points[i] = p;
                } else {
                  _points.remove(i);
                }
              }),
              title: Text(_apgarCriteria[i].options[p]),
              secondary: Text(
                '+$p',
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        _ScoreResult(
          total: _total,
          max: 10,
          label: label,
          color: color,
          onReset: _points.isEmpty ? null : () => setState(_points.clear),
        ),
      ],
    );
  }
}
