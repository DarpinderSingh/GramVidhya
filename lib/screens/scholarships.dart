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
    final tok = context.tokens;

    return Scaffold(
      backgroundColor: tok.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: tok.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: tok.textPrimary),
        title: Text(
          tr('scholarships_title'),
          style: TextStyle(fontWeight: FontWeight.bold, color: tok.textPrimary),
        ),
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
                      gradient: LinearGradient(
                        colors: [tok.primary, tok.secondaryAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: tok.shadow,
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
                            color: tok.buttonText.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.card_membership_rounded, color: tok.buttonText, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('scholarship_finder'),
                                style: TextStyle(
                                  color: tok.buttonText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('scholarship_desc'),
                                style: TextStyle(
                                  color: tok.buttonText.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Filter Card ─────────────────────────────────────────
                  Card(
                    elevation: 3,
                    shadowColor: tok.shadow,
                    color: tok.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: tok.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('eligibility_filter'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: tok.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: group,
                                  dropdownColor: tok.cardBackground,
                                  decoration: InputDecoration(
                                    labelText: tr('social_category'),
                                    labelStyle: TextStyle(color: tok.textSecondary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: tok.border),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  style: TextStyle(color: tok.textPrimary),
                                  items: ['ST', 'SC', 'OBC', 'General']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) => setState(() => group = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: level,
                                  dropdownColor: tok.cardBackground,
                                  decoration: InputDecoration(
                                    labelText: tr('education_level'),
                                    labelStyle: TextStyle(color: tok.textSecondary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: tok.border),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  style: TextStyle(color: tok.textPrimary),
                                  items: [
                                    DropdownMenuItem(value: 'UG', child: Text(tr('undergraduate'))),
                                    DropdownMenuItem(value: 'PG', child: Text(tr('postgraduate'))),
                                    DropdownMenuItem(value: 'PhD', child: Text(tr('doctorate'))),
                                  ],
                                  onChanged: (v) => setState(() => level = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '${tr('family_income')}: ₹${income.toStringAsFixed(1)} L/yr',
                                style: TextStyle(color: tok.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Slider(
                            value: income,
                            min: 0.5,
                            max: 8.0,
                            divisions: 15,
                            activeColor: tok.primary,
                            inactiveColor: tok.border,
                            label: '₹${income.toStringAsFixed(1)} Lakhs',
                            onChanged: (v) => setState(() => income = v),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: FilterChip(
                                  selected: girl,
                                  label: Text(tr('girl_child'), style: TextStyle(color: girl ? tok.buttonText : tok.textPrimary)),
                                  selectedColor: tok.primary,
                                  backgroundColor: tok.chipBackground,
                                  side: BorderSide(color: tok.border),
                                  onSelected: (v) => setState(() => girl = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilterChip(
                                  selected: pwd,
                                  label: Text(tr('person_disability'), style: TextStyle(color: pwd ? tok.buttonText : tok.textPrimary)),
                                  selectedColor: tok.primary,
                                  backgroundColor: tok.chipBackground,
                                  side: BorderSide(color: tok.border),
                                  onSelected: (v) => setState(() => pwd = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Results Count ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tr('matching_schemes')} (${r.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tok.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Scheme List ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = r[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: tok.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: tok.border),
                    ),
                    elevation: 2,
                    shadowColor: tok.shadow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: tok.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.stars_rounded, color: tok.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: tok.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.note,
                            style: TextStyle(color: tok.textSecondary, fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(
                                  item.body,
                                  style: TextStyle(color: tok.textSecondary, fontSize: 11),
                                ),
                                backgroundColor: tok.backgroundSecondary,
                                side: BorderSide(color: tok.border),
                                padding: EdgeInsets.zero,
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.arrow_forward, size: 14, color: tok.buttonText),
                                label: Text(tr('apply_now'), style: TextStyle(fontSize: 12, color: tok.buttonText)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tok.buttonPrimary,
                                  foregroundColor: tok.buttonText,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: r.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
