import '../data/scholarships.dart';
import '../core/i18n.dart';

/// Offline scholarship AI that answers based on local scholarship data only.
/// NEVER hallucinates — if data is not in the local database, it says so.
class ScholarshipAI {
  /// Search local scholarship data and generate an answer.
  /// Uses keyword matching against the enriched scheme data.
  Stream<String> answer(String question) async* {
    final q = question.toLowerCase();
    
    // Normalize punctuation
    final cleanQ = q.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final stopWords = {'what', 'are', 'the', 'for', 'is', 'a', 'an', 'in', 'of', 'and', 'to', 'scholarship', 'scholarships'};
    final queryWords = cleanQ.split(RegExp(r'\s+')).where((w) => w.length > 1 && !stopWords.contains(w)).toList();

    // Determine what aspect of scholarship is being asked
    final asksEligibility = _matches(q, ['eligib', 'qualif', 'criteria', 'who can', 'requirement', 'पात्र', 'योग्य']);
    final asksDocuments = _matches(q, ['document', 'paper', 'certificate', 'proof', 'दस्तावेज़', 'कागज', 'marksheet', 'aadhaar']);
    final asksProcess = _matches(q, ['apply', 'process', 'how to', 'step', 'procedure', 'registration', 'आवेदन', 'कैसे']);
    final asksAmount = _matches(q, ['amount', 'money', 'how much', 'stipend', 'fee', 'maintenance', 'कितन', 'राशि', 'पैसा']);
    final asksDeadline = _matches(q, ['deadline', 'last date', 'due date', 'कब', 'तारीख', 'अंतिम']);
    final asksSpecificAspect = asksEligibility || asksDocuments || asksProcess || asksAmount || asksDeadline;
    final asksList = !asksSpecificAspect && _matches(q, ['list', 'show all', 'all scholarships', 'available', 'which scholarships', 'सूची']);
    final asksSpecificCategory = _matches(q, ['sc', 'st', 'obc', 'tribal', 'minority', 'girl', 'women', 'disability', 'pwd', 'अनुसूचित', 'जनजाति', 'अल्पसंख्यक', 'महिला', 'दिव्यांग']);

    // Score and match schemes
    final scoredSchemes = <MapEntry<Scheme, int>>[];
    for (final s in schemes) {
      final nameLower = s.name.toLowerCase();
      final bodyLower = s.body.toLowerCase();
      final searchable = '$nameLower $bodyLower ${s.note.toLowerCase()} ${(s.eligibility ?? '').toLowerCase()} ${(s.groups.join(' ')).toLowerCase()}';

      int score = 0;
      for (final w in queryWords) {
        if (nameLower.contains(w)) {
          score += 3; // Name match gets highest weight
        } else if (searchable.contains(w)) {
          score += 1;
        }
      }
      if (score > 0) {
        scoredSchemes.add(MapEntry(s, score));
      }
    }

    // Sort by highest score
    scoredSchemes.sort((a, b) => b.value.compareTo(a.value));
    final matched = scoredSchemes.map((e) => e.key).toList();

    if (matched.isEmpty && !asksList && !asksSpecificCategory) {
      yield tr('schol_no_info');
      return;
    }

    // If asking for a list or no specific scheme matched but asking by category
    if (asksList || (matched.isEmpty && asksSpecificCategory)) {
      final relevantSchemes = matched.isNotEmpty ? matched : schemes;
      yield 'Here are the scholarships available in the local database:\n\n';
      for (final s in relevantSchemes) {
        yield '• **${s.name}** (${s.body})\n';
        if (s.groups.isNotEmpty) yield '  Category: ${s.groups.join(", ")}\n';
        yield '  Levels: ${s.levels.join(", ")}\n\n';
      }
      return;
    }

    // Narrow down to top matches (up to 2) if specific scheme asked
    final displaySchemes = matched.take(2).toList();

    // Answer about matched schemes
    for (final s in displaySchemes) {
      yield '**${s.name}**\n';
      yield '${s.body}\n\n';

      if (asksEligibility && s.eligibility != null) {
        yield '**Eligibility:**\n${s.eligibility}\n\n';
      }

      if (asksDocuments && s.documents.isNotEmpty) {
        yield '**Required Documents:**\n';
        for (final d in s.documents) {
          yield '• $d\n';
        }
        yield '\n';
      }

      if (asksProcess && s.applicationProcess != null) {
        yield '**Application Process:**\n${s.applicationProcess}\n\n';
      }

      if (asksAmount && s.amount != null) {
        yield '**Scholarship Amount:**\n${s.amount}\n\n';
      }

      if (asksDeadline) {
        if (s.deadline != null) {
          yield '**Deadline:**\n${s.deadline}\n\n';
        } else {
          yield '**Deadline:** Information not available in local database. Please check ${s.website ?? "the official website"} for current deadlines.\n\n';
        }
      }

      // If no specific aspect was asked, give a summary
      if (!asksSpecificAspect) {
        yield '${s.note}\n\n';
        if (s.amount != null) yield '**Amount:** ${s.amount}\n';
        if (s.eligibility != null) yield '**Eligibility:** ${s.eligibility}\n';
        if (s.incomeCapLakh != null) yield '**Income cap:** ₹${s.incomeCapLakh}L/year\n';
        if (s.groups.isNotEmpty) yield '**Category:** ${s.groups.join(", ")}\n';
        yield '**Levels:** ${s.levels.join(", ")}\n';
        yield '\n';
      }
    }

    yield '⚠️ This information is from the local offline database. Please verify details on official websites when internet is available.';
  }

  bool _matches(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}
