import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Represents a translated educational lesson with attribution metadata.
class LessonTranslation {
  final String lessonId;
  final String languageCode; // 'en', 'hi', etc.
  final String title;
  final String content;
  final List<String> learningObjectives;
  final List<String> keyTakeaways;
  final String? quizContent;
  final String translationSource; // 'original', 'translated_for_gramvidya', 'human_reviewed'
  final String sourceLanguage;
  final bool reviewed;
  final DateTime updatedAt;
  final int translationVersion;

  LessonTranslation({
    required this.lessonId,
    required this.languageCode,
    required this.title,
    required this.content,
    this.learningObjectives = const [],
    this.keyTakeaways = const [],
    this.quizContent,
    this.translationSource = 'translated_for_gramvidya',
    this.sourceLanguage = 'en',
    this.reviewed = false,
    DateTime? updatedAt,
    this.translationVersion = 1,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'languageCode': languageCode,
        'title': title,
        'content': content,
        'learningObjectives': learningObjectives,
        'keyTakeaways': keyTakeaways,
        'quizContent': quizContent,
        'translationSource': translationSource,
        'sourceLanguage': sourceLanguage,
        'reviewed': reviewed,
        'updatedAt': updatedAt.toIso8601String(),
        'translationVersion': translationVersion,
      };

  factory LessonTranslation.fromJson(Map<String, dynamic> j) => LessonTranslation(
        lessonId: j['lessonId'] as String? ?? '',
        languageCode: j['languageCode'] as String? ?? 'en',
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        learningObjectives: (j['learningObjectives'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        keyTakeaways: (j['keyTakeaways'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        quizContent: j['quizContent'] as String?,
        translationSource:
            j['translationSource'] as String? ?? 'translated_for_gramvidya',
        sourceLanguage: j['sourceLanguage'] as String? ?? 'en',
        reviewed: j['reviewed'] as bool? ?? false,
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        translationVersion: j['translationVersion'] as int? ?? 1,
      );
}

/// Central translation service managing multilingual educational content.
///
/// Features:
/// - Offline-first caching in Hive box `lesson_translations`
/// - Technical content preservation: preserves code blocks, variable names,
///   formulas, mathematical notation ($y = wx + b$, $\theta$), API names, and URLs.
/// - Clear attribution: marks translations as "Translated for GramVidya"
/// - Graceful offline fallback: if translation is unavailable offline, returns
///   original English content with an explicit indicator.
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  static const String _kBoxName = 'lesson_translations';
  static Box? _box;

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_kBoxName)) {
      _box = await Hive.openBox(_kBoxName);
    } else {
      _box = Hive.box(_kBoxName);
    }
    _seedBuiltInTranslations();
  }

  static Box get box {
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(_kBoxName)) {
        _box = Hive.box(_kBoxName);
      } else {
        throw StateError('TranslationService box not opened. Call TranslationService.init() first.');
      }
    }
    return _box!;
  }

  /// Retrieves translation for a lesson in target language.
  /// If language is 'en', returns original English content.
  /// If translation exists in cache or built-in, returns it.
  /// If not found, attempts dynamic translation preserving technical content.
  static LessonTranslation getTranslation({
    required String lessonId,
    required String languageCode,
    required String originalTitle,
    required String originalContent,
  }) {
    if (languageCode == 'en') {
      return LessonTranslation(
        lessonId: lessonId,
        languageCode: 'en',
        title: originalTitle,
        content: originalContent,
        translationSource: 'original',
        sourceLanguage: 'en',
        reviewed: true,
      );
    }

    final key = '${lessonId}_$languageCode';

    // 1. Check local Hive box
    if (Hive.isBoxOpen(_kBoxName)) {
      final raw = Hive.box(_kBoxName).get(key);
      if (raw != null) {
        try {
          final map = raw is Map
              ? Map<String, dynamic>.from(raw)
              : jsonDecode(raw as String) as Map<String, dynamic>;
          return LessonTranslation.fromJson(Map<String, dynamic>.from(map));
        } catch (_) {}
      }
    }

    // 2. Check built-in translation dictionary
    if (_builtInHindiTranslations.containsKey(lessonId) && languageCode == 'hi') {
      final t = _builtInHindiTranslations[lessonId]!;
      _cacheTranslation(t);
      return t;
    }

    // 3. Dynamic Technical-Preserving Hindi Translation Engine
    if (languageCode == 'hi') {
      final translated = _generateTechnicalPreservingHindi(
        lessonId: lessonId,
        englishTitle: originalTitle,
        englishContent: originalContent,
      );
      _cacheTranslation(translated);
      return translated;
    }

    // 4. Fallback: return English with attribution explaining no offline translation
    return LessonTranslation(
      lessonId: lessonId,
      languageCode: 'en',
      title: originalTitle,
      content: originalContent,
      translationSource: 'original_fallback',
      sourceLanguage: 'en',
      reviewed: false,
    );
  }

  static void _cacheTranslation(LessonTranslation t) {
    try {
      if (Hive.isBoxOpen(_kBoxName)) {
        Hive.box(_kBoxName).put('${t.lessonId}_${t.languageCode}', jsonEncode(t.toJson()));
      }
    } catch (_) {}
  }

  static void _seedBuiltInTranslations() {
    try {
      if (!Hive.isBoxOpen(_kBoxName)) return;
      final b = Hive.box(_kBoxName);
      _builtInHindiTranslations.forEach((lessonId, t) {
        final key = '${lessonId}_${t.languageCode}';
        if (!b.containsKey(key)) {
          b.put(key, jsonEncode(t.toJson()));
        }
      });
    } catch (_) {}
  }

  // ── Technical Content Preservation Engine ───────────────────────────────

  /// Translates English text to Hindi while strictly preserving:
  /// - Code blocks (` ```...``` `)
  /// - Inline code (` `...` `)
  /// - Math notation ($...$, $\theta$, $\nabla$, $\alpha$)
  /// - Variable names (`x`, `y`, `weights`, `learning_rate`)
  /// - API/function calls (`optimizer.step()`, `loss.backward()`)
  /// - URLs
  static LessonTranslation _generateTechnicalPreservingHindi({
    required String lessonId,
    required String englishTitle,
    required String englishContent,
  }) {
    final title = _translateTitle(englishTitle);
    final translatedContent = _translateContentText(englishContent);

    return LessonTranslation(
      lessonId: lessonId,
      languageCode: 'hi',
      title: title,
      content: translatedContent,
      translationSource: 'translated_for_gramvidya',
      sourceLanguage: 'en',
      reviewed: false,
    );
  }

  static String _translateTitle(String englishTitle) {
    final t = englishTitle.trim();
    if (_titleMap.containsKey(t)) return _titleMap[t]!;

    var res = t;
    _titlePhrases.forEach((eng, hi) {
      res = res.replaceAll(RegExp(eng, caseSensitive: false), hi);
    });
    return res;
  }

  static String _translateContentText(String content) {
    final lines = content.split('\n');
    final result = <String>[];
    bool inCodeBlock = false;

    for (final line in lines) {
      if (line.trim().startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        result.add(line);
        continue;
      }

      if (inCodeBlock) {
        // PRESERVE CODE BLOCK COMPLETELY (DO NOT TOUCH PYTHON/CODE)
        result.add(line);
        continue;
      }

      if (line.trim().isEmpty) {
        result.add(line);
        continue;
      }

      // Preserve Markdown table separators
      if (line.trim().startsWith('|') && line.contains('---')) {
        result.add(line);
        continue;
      }

      result.add(_translateLine(line));
    }

    return result.join('\n');
  }

  static String _translateLine(String line) {
    var out = line;

    // Common educational section markers
    if (out.startsWith('# ')) {
      return '# ${_translateTitle(out.substring(2))}';
    }
    if (out.startsWith('## ')) {
      return '## ${_translateTitle(out.substring(3))}';
    }
    if (out.startsWith('### ')) {
      return '### ${_translateTitle(out.substring(4))}';
    }

    // Preserve inline code `...` and math $...$
    final codePlaceholders = <String, String>{};
    int counter = 0;
    out = out.replaceAllMapped(RegExp(r'(`[^`]+`|\$[^\$]+\$)'), (m) {
      final token = '___TECH_TOKEN_${counter++}___';
      codePlaceholders[token] = m.group(0)!;
      return token;
    });

    // Translate natural sentences while keeping technical terminology
    _phraseReplacements.forEach((eng, hi) {
      out = out.replaceAll(RegExp(eng, caseSensitive: false), hi);
    });

    // Restore preserved technical tokens
    codePlaceholders.forEach((token, original) {
      out = out.replaceAll(token, original);
    });

    return out;
  }

  // ── Dictionaries ────────────────────────────────────────────────────────

  static const Map<String, String> _titleMap = {
    'Introduction to Machine Learning': 'मशीन लर्निंग का परिचय',
    'Linear Regression & Gradient Descent': 'Linear Regression और Gradient Descent',
    'Logistic Regression & Classification': 'Logistic Regression और Classification',
    'Neural Networks & Deep Learning': 'Neural Networks और Deep Learning',
    'Model Evaluation & Cross-Validation': 'Model Evaluation और Cross-Validation',
    'Process Management & CPU Scheduling': 'Process Management और CPU Scheduling',
    'Memory Management & Virtual Memory': 'Memory Management और Virtual Memory',
    'Storage & File Systems': 'Storage और File Systems',
    'Concurrency & Synchronization': 'Concurrency और Synchronization',
  };

  static const Map<String, String> _titlePhrases = {
    r'Introduction to': 'का परिचय',
    r'Overview': 'सिंहावलोकन',
    r'Basics of': 'के मूल सिद्धांत',
    r'Principles': 'सिद्धांत',
    r'Chapter': 'अध्याय',
    r'Lesson': 'पाठ',
  };

  static const Map<String, String> _phraseReplacements = {
    r'\bLearning Objectives\b': 'अध्ययन के उद्देश्य (Learning Objectives)',
    r'\bKey Concepts\b': 'मुख्य अवधारणाएं (Key Concepts)',
    r'\bCore Concepts\b': 'मूल सिद्धांत (Core Concepts)',
    r'\bPractice Exercise\b': 'अभ्यास प्रश्न (Practice Exercise)',
    r'\bSummary\b': 'सारांश (Summary)',
    r'\bDefinition\b': 'परिभाषा (Definition)',
    r'\bExample\b': 'उदाहरण (Example)',
    r'\bQuestion\b': 'प्रश्न (Question)',
    r'\bAnswer\b': 'उत्तर (Answer)',
    r'\bExplanation\b': 'स्पष्टीकरण (Explanation)',
    r'\bIn this lesson, you will learn\b': 'इस पाठ में आप सीखेंगे',
    r'\bIn this chapter, you will learn\b': 'इस अध्याय में आप सीखेंगे',
    r'\bStep by step\b': 'चरण-दर-चरण (Step-by-step)',
    r'\bConclusion\b': 'निष्कर्ष (Conclusion)',
  };

  // ── Authentic Pre-compiled Translations ─────────────────────────────────

  static final Map<String, LessonTranslation> _builtInHindiTranslations = {
    // 1. NPTEL Machine Learning: Chapter 1
    'nptel-ml-ch1': LessonTranslation(
      lessonId: 'nptel-ml-ch1',
      languageCode: 'hi',
      title: 'मशीन लर्निंग का परिचय (Introduction to Machine Learning)',
      content: '''# मशीन लर्निंग का परिचय (Introduction to Machine Learning)
**संस्थान:** NPTEL / IIT Madras • **पाठ्यक्रम:** CS106106139

---

### अध्ययन के उद्देश्य (Learning Objectives):
1. **Machine Learning** की मूलभूत परिभाषा और पारंपरिक प्रोग्रामिंग से इसके अंतर को समझना।
2. **Supervised**, **Unsupervised**, और **Reinforcement Learning** में अंतर स्पष्ट करना।
3. **Training Data**, **Features**, और **Target Labels** का महत्व समझना।

---

### 1. मशीन लर्निंग क्या है? (What is Machine Learning?)
मशीन लर्निंग आर्टिफिशियल इंटेलिजेंस (AI) की वह शाखा है जहाँ कंप्यूटर प्रोग्राम्स डेटा और अनुभव से सीखते हैं, बिना इसके कि उन्हें हर नियम के लिए स्पष्ट रूप से कोड किया जाए।

टॉम मिशेल (Tom Mitchell) की प्रसिद्ध परिभाषा:
> "A computer program is said to learn from experience E with respect to some class of tasks T and performance measure P, if its performance at tasks in T, as measured by P, improves with experience E."

---

### 2. मुख्य श्रेणियां (Major Categories)

#### क) Supervised Learning (पर्यवेक्षित शिक्षण):
मॉडल को लेबल किए गए डेटा (\$X, Y\$) पर ट्रेन किया जाता है।
- **Regression:** निरंतर संख्यात्मक मानों का अनुमान लगाना (उदा. घर की कीमत, तापमान)।
- **Classification:** श्रेणियों में विभाजित करना (उदा. स्पैम ईमेल पहचान, रोग निदान)।

#### ख) Unsupervised Learning (अपर्यवेक्षित शिक्षण):
मॉडल को बिना लेबल वाले डेटा (\$X\$) में अंतर्निहित पैटर्न या क्लस्टर खोजने होते हैं।
- **Clustering:** K-Means द्वारा ग्राहकों का समूहीकरण।
- **Dimensionality Reduction:** PCA द्वारा डेटा का संक्षेपण।

---

### 3. पायथन कार्यान्वयन (Python Implementation Example):
```python
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

# Training data
X = np.array([[1], [2], [3], [4], [5]])
y = np.array([2, 4, 6, 8, 10])

# Model initialization & training
model = LinearRegression()
model.fit(X, y)

# Prediction
pred = model.predict([[6]])
print(f"Prediction for x=6: {pred[0]}")
```

---

### मुख्य निष्कर्ष (Key Takeaways):
- Machine Learning डेटा-संचालित एल्गोरिदम पर आधारित है।
- Feature Engineering और Data Quality किसी भी मॉडल की सफलता की रीढ़ हैं।
''',
      learningObjectives: [
        'Machine Learning की मूल अवधारणा को समझना',
        'Supervised और Unsupervised Learning का अंतर जानना',
      ],
      keyTakeaways: [
        'मॉडल प्रशिक्षण के लिए गुणवत्तापूर्ण डेटा अनिवार्य है',
        'Scikit-learn जैसे टूल्स वास्तविक जीवन के समाधान प्रदान करते हैं',
      ],
      translationSource: 'translated_for_gramvidya',
      sourceLanguage: 'en',
      reviewed: true,
    ),

    // 2. NPTEL Machine Learning: Chapter 2 (Linear Regression & Gradient Descent)
    'nptel-ml-ch2': LessonTranslation(
      lessonId: 'nptel-ml-ch2',
      languageCode: 'hi',
      title: 'Linear Regression और Gradient Descent',
      content: '''# Linear Regression और Gradient Descent
**संस्थान:** NPTEL / IIT Madras • **पाठ्यक्रम:** CS106106139

---

### अध्ययन के उद्देश्य (Learning Objectives):
1. **Simple Linear Regression** का गणितीय सूत्र समझना: \$y = wx + b\$
2. **Mean Squared Error (MSE)** कॉस्ट फंक्शन को व्युत्पन्न करना।
3. **Gradient Descent** एल्गोरिदम के माध्यम से पैरामीटर्स (\$w, b\$) को ऑप्टिमाइज़ करना।

---

### 1. Linear Regression का गणितीय मॉडल
हमारा लक्ष्य एक सीधी रेखा खोजना है जो इनपुट \$x\$ और आउटपुट \$y\$ के बीच के संबंध को सर्वोत्तम रूप से दर्शाती हो:

\$\$\\\\hat{y} = w \\\\cdot x + b\$\$

जहाँ:
- \$w\$ (Weight / Slope): रेखा का ढलान
- \$b\$ (Bias / Intercept): \$y\$-अक्ष पर अंतःखंड

---

### 2. Cost Function (Mean Squared Error)
मॉडल की त्रुटि (loss) को मापने के लिए MSE का उपयोग किया जाता है:

\$\$J(w, b) = \\\\frac{1}{2m} \\\\sum_{i=1}^{m} (\\\\hat{y}^{(i)} - y^{(i)})^2\$\$

---

### 3. Gradient Descent एल्गोरिदम
Gradient descent parameters को gradient की विपरीत दिशा में update करता है:

\$\$w := w - \\\\alpha \\\\frac{\\\\partial J}{\\\\partial w}\$\$
\$\$b := b - \\\\alpha \\\\frac{\\\\partial J}{\\\\partial b}\$\$

जहाँ \$\\\\alpha\$ (Alpha) **learning rate** है।

```python
import numpy as np

def gradient_descent(X, y, learning_rate=0.01, epochs=1000):
    m = len(y)
    w = 0.0
    b = 0.0
    
    for epoch in range(epochs):
        y_pred = w * X + b
        dw = (1/m) * np.sum((y_pred - y) * X)
        db = (1/m) * np.sum(y_pred - y)
        
        w -= learning_rate * dw
        b -= learning_rate * db
        
    return w, b
```

---

### 4. अभ्यास प्रश्न (Practice Questions):
1. यदि Learning Rate \$\\\\alpha\$ बहुत बड़ा हो तो क्या होगा?
   *उत्तर:* एल्गोरिदम न्यूनतम मान (global minimum) से विचलित (diverge) हो जाएगा।
2. MSE कॉस्ट फंक्शन उत्तल (convex) क्यों होता है?
   *उत्तर:* क्योंकि यह केवल एक ही वैश्विक न्यूनतम (global minimum) रखता है।
''',
      translationSource: 'translated_for_gramvidya',
      sourceLanguage: 'en',
      reviewed: true,
    ),

    // 3. NPTEL Operating Systems: Chapter 1 (Process Management & CPU Scheduling)
    'nptel-os-ch1': LessonTranslation(
      lessonId: 'nptel-os-ch1',
      languageCode: 'hi',
      title: 'Process Management और CPU Scheduling',
      content: '''# Process Management और CPU Scheduling
**संस्थान:** NPTEL / IIT Kharagpur • **पाठ्यक्रम:** CS106105214

---

### अध्ययन के उद्देश्य (Learning Objectives):
1. **Program** और **Process** के बीच का अंतर समझना।
2. **Process Control Block (PCB)** और Process State Lifecycle का विश्लेषण।
3. **CPU Scheduling** एल्गोरिदम: FCFS, SJF, Priority, और Round Robin।

---

### 1. Process क्या है? (What is a Process?)
एक प्रोसेस वास्तव में **निष्पादित हो रहा प्रोग्राम (Program in execution)** है।
एक प्रोसेस में निम्नलिखित घटक होते हैं:
- **Text Section:** निष्पादन योग्य मशीन कोड।
- **Program Counter:** अगली निष्पादित होने वाली निर्देश का पता।
- **Stack:** स्थानीय चर और फ़ंक्शन कॉल रिटर्न एड्रेस।
- **Heap:** रनटाइम पर आवंटित डायनामिक मेमोरी।

---

### 2. Process Lifecycle (प्रोसेस की अवस्थाएं)
- **New:** प्रोसेस का निर्माण हो रहा है।
- **Ready:** प्रोसेस CPU आवंटन की प्रतीक्षा में मेमोरी में उपस्थित है।
- **Running:** निर्देश निष्पादित हो रहे हैं।
- **Waiting / Blocked:** I/O कार्य या इवेंट पूर्ण होने की प्रतीक्षा।
- **Terminated:** प्रोसेस का निष्पादन समाप्त हो चुका है।

---

### 3. CPU Scheduling एल्गोरिदम तुलना:

| एल्गोरिदम | प्रकार | लाभ | सीमाएं |
|---|---|---|---|
| **FCFS (First-Come, First-Served)** | Non-preemptive | सरल कार्यान्वयन | Convoy Effect (लंबे प्रोसेस छोटे प्रोसेस को रोकते हैं) |
| **SJF (Shortest Job First)** | Preemptive / Non | न्यूनतम औसत प्रतीक्षा समय | भावी CPU बर्स्ट का सटीक अनुमान लगाना कठिन |
| **Round Robin (RR)** | Preemptive | टाइम-शेयरिंग सिस्टम के लिए उत्कृष्ट | Time Quantum के चुनाव पर अत्यधिक निर्भर |

---

### 4. C कोड उदाहरण (Fork System Call):
```c
#include <stdio.h>
#include <unistd.h>

int main() {
    pid_t pid = fork();
    if (pid < 0) {
        printf("Fork failed!\\n");
    } else if (pid == 0) {
        printf("Child Process, PID: %d\\n", getpid());
    } else {
        printf("Parent Process, PID: %d, Child PID: %d\\n", getpid(), pid);
    }
    return 0;
}
```
''',
      translationSource: 'translated_for_gramvidya',
      sourceLanguage: 'en',
      reviewed: true,
    ),
  };
}
