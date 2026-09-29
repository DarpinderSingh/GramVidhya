import 'package:flutter/material.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/scholarships.dart';

class ScholarshipScreen extends StatefulWidget {
  const ScholarshipScreen({super.key});
  @override
  State<ScholarshipScreen> createState() => _ScholState();
}

class _ScholState extends State<ScholarshipScreen> {
  String group = 'ST', level = 'UG';
  double income = 2;
  bool girl = false, pwd = false;

  @override
  Widget build(BuildContext context) {
    final r = matchSchemes(group: group, level: level, incomeLakh: income, girl: girl, pwd: pwd);
    final theme = Theme.of(context);
    final tok = context.tokens;

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      appBar: AppBar(
        title: Text(tr('scholarships_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Banner ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('schol_db'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('schol_db_sub'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Match Profile Card ─────────────────────────────────
                  Text(
                    tr('match_profile'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tok.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: tok.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tok.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: tok.isDark ? 0.2 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Group
                        Row(
                          children: [
                            Icon(Icons.group, size: 18, color: tok.accent),
                            const SizedBox(width: 10),
                            Text(tr('group'), style: TextStyle(fontWeight: FontWeight.w600, color: tok.textPrimary)),
                            const Spacer(),
                            DropdownButton<String>(
                              dropdownColor: tok.surface,
                              value: group,
                              underline: const SizedBox(),
                              style: TextStyle(color: tok.textPrimary, fontSize: 14),
                              items: ['General', 'SC', 'ST', 'OBC', 'Minority']
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g == 'ST' ? 'ST (Tribal)' : g),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => group = v!),
                            ),
                          ],
                        ),
                        Divider(color: tok.border, height: 20),

                        // Level
                        Row(
                          children: [
                            Icon(Icons.school_outlined, size: 18, color: tok.accent),
                            const SizedBox(width: 10),
                            Text(tr('level'), style: TextStyle(fontWeight: FontWeight.w600, color: tok.textPrimary)),
                            const Spacer(),
                            DropdownButton<String>(
                              dropdownColor: tok.surface,
                              value: level,
                              underline: const SizedBox(),
                              style: TextStyle(color: tok.textPrimary, fontSize: 14),
                              items: ['UG', 'PG', 'Diploma']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) => setState(() => level = v!),
                            ),
                          ],
                        ),
                        Divider(color: tok.border, height: 20),

                        // Income Slider
                        Row(
                          children: [
                            Icon(Icons.currency_rupee, size: 18, color: tok.accent),
                            const SizedBox(width: 10),
                            Text(
                              trf('income_label', {'n': income.toStringAsFixed(1)}),
                              style: TextStyle(fontWeight: FontWeight.w600, color: tok.textPrimary),
                            ),
                          ],
                        ),
                        Slider(
                          value: income,
                          min: 0,
                          max: 10,
                          divisions: 20,
                          activeColor: tok.accent,
                          inactiveColor: tok.border,
                          onChanged: (v) => setState(() => income = v),
                        ),
                        Divider(color: tok.border, height: 4),

                        // Female student toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('female_student'), style: TextStyle(color: tok.textPrimary)),
                          value: girl,
                          onChanged: (v) => setState(() => girl = v),
                          activeColor: tok.accent,
                        ),

                        // Person with disability toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr('pwd'), style: TextStyle(color: tok.textPrimary)),
                          value: pwd,
                          onChanged: (v) => setState(() => pwd = v),
                          activeColor: tok.accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Results Header ──────────────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.verified, size: 20, color: tok.success),
                      const SizedBox(width: 8),
                      Text(
                        trf('eligible_schol', {'n': r.length.toString()}),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tok.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Scholarship Cards ──────────────────────────────────────────
          if (r.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: tok.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tok.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_off, color: tok.textMuted, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('no_match'),
                          style: TextStyle(color: tok.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = r[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: tok.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tok.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: tok.isDark ? 0.18 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: tok.accent.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.description, color: tok.accent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: tok.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        s.body,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tok.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (s.note.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: tok.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: tok.warning.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: tok.warning),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        s.note,
                                        style: TextStyle(fontSize: 11, color: tok.warning),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: r.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('starting_schol_assistant'))),
          );
        },
        icon: const Icon(Icons.chat),
        label: Text(tr('schol_assistant')),
        backgroundColor: const Color(0xFFF472B6),
        foregroundColor: Colors.white,
      ),
    );
  }
}
