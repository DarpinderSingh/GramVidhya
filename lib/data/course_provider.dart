import 'dart:convert';
import '../data/user_store.dart';

/// A single lesson within a course.
class Lesson {
  Lesson({
    required this.id,
    required this.title,
    required this.content,
    this.videoUrl,
    this.durationMinutes,
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String content;
  final String? videoUrl;
  final int? durationMinutes;

  /// External URL (e.g. DIKSHA) to view this lesson online.
  final String? sourceUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'videoUrl': videoUrl,
        'durationMinutes': durationMinutes,
        'sourceUrl': sourceUrl,
      };

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        videoUrl: j['videoUrl'] as String?,
        durationMinutes: j['durationMinutes'] as int?,
        sourceUrl: j['sourceUrl'] as String?,
      );
}

/// A downloadable course containing lessons.
class Course {
  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.lessons,
    this.provider,
    this.version = 1,
    this.sourceId,
    this.thumbnailUrl,
    this.leafCount,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final List<Lesson> lessons;
  final String? provider;
  final int version;
  final String? sourceId;
  final String? thumbnailUrl;
  final int? leafCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'lessons': lessons.map((l) => l.toJson()).toList(),
        'provider': provider,
        'version': version,
        'sourceId': sourceId,
        'thumbnailUrl': thumbnailUrl,
        'leafCount': leafCount,
      };

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        icon: j['icon'] as String? ?? 'book',
        lessons: (j['lessons'] as List?)
                ?.map((l) => Lesson.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        provider: j['provider'] as String?,
        version: j['version'] as int? ?? 1,
        sourceId: j['sourceId'] as String?,
        thumbnailUrl: j['thumbnailUrl'] as String?,
        leafCount: j['leafCount'] as int?,
      );
}

/// Course states for the download manager.
enum CourseState { available, downloading, downloaded, failed, updateAvailable }

CourseState parseCourseState(String s) {
  switch (s) {
    case 'downloaded':
      return CourseState.downloaded;
    case 'downloading':
      return CourseState.downloading;
    case 'failed':
      return CourseState.failed;
    case 'update_available':
      return CourseState.updateAvailable;
    default:
      return CourseState.available;
  }
}

String courseStateToString(CourseState s) {
  switch (s) {
    case CourseState.downloaded:
      return 'downloaded';
    case CourseState.downloading:
      return 'downloading';
    case CourseState.failed:
      return 'failed';
    case CourseState.updateAvailable:
      return 'update_available';
    case CourseState.available:
      return 'available';
  }
}

/// Abstract provider.
abstract class EducationalContentProvider {
  Future<List<Course>> fetchCourses();
  Future<Course?> fetchCourse(String id);
  Future<bool> isAvailable();
}

/// Serves courses from local Hive storage (user-scoped via UserStore).
class LocalContentProvider implements EducationalContentProvider {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<Course>> fetchCourses() async {
    final ids = UserStore.downloadedCourseIds;
    final result = <Course>[];
    for (final id in ids) {
      final data = UserStore.courseData(id);
      if (data != null) {
        result.add(Course.fromJson(jsonDecode(data) as Map<String, dynamic>));
      }
    }
    return result;
  }

  @override
  Future<Course?> fetchCourse(String id) async {
    final data = UserStore.courseData(id);
    if (data == null) return null;
    return Course.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
}

/// Remote provider placeholder.
class RemoteContentProvider implements EducationalContentProvider {
  final String? baseUrl;
  RemoteContentProvider({this.baseUrl});

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<Course>> fetchCourses() async => [];

  @override
  Future<Course?> fetchCourse(String id) async => null;
}

/// Manages course downloads and provides unified access.
class CourseManager {
  final EducationalContentProvider localProvider = LocalContentProvider();
  final EducationalContentProvider remoteProvider = RemoteContentProvider();

  /// Built-in courses bundled with the app — always available offline.
  /// Content is substantially more detailed and educational than stub text.
  static List<Course> get builtInCourses => [
        Course(
          id: 'basic-english',
          title: 'Module 1: Basic English',
          description:
              'Learn alphabets, common words, simple sentences, and practical communication skills.',
          icon: 'abc',
          lessons: [
            Lesson(
              id: 'eng-1',
              title: 'The English Alphabet',
              durationMinutes: 20,
              content: '''# The English Alphabet

## Learning Objectives
By the end of this lesson you will be able to:
- Recognize all 26 letters in upper and lower case
- Pronounce each letter correctly
- Write the alphabet from memory

## The 26 Letters

The English alphabet has **26 letters** divided into:

| Category | Letters |
|----------|---------|
| Vowels   | A, E, I, O, U (and sometimes Y) |
| Consonants | All remaining 21 letters |

### Uppercase (Capital) Letters
A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

### Lowercase (Small) Letters
a b c d e f g h i j k l m n o p q r s t u v w x y z

## Vowels and Consonants

**Vowels** (आ की ध्वनि / স্বরধ্বনি): A, E, I, O, U
Every English word contains at least one vowel.

**Consonants**: All other 21 letters (B, C, D, F, G, H, J, K, L, M, N, P, Q, R, S, T, V, W, X, Y, Z)

## Pronunciation Guide

| Letter | Sounds like | Example Word |
|--------|------------|-------------|
| A      | /eɪ/       | Apple, Ant  |
| B      | /biː/      | Ball, Book  |
| C      | /siː/      | Cat, Car    |
| D      | /diː/      | Dog, Door   |
| E      | /iː/       | Egg, Ear    |
| F      | /ef/       | Fish, Fan   |
| G      | /dʒiː/     | Gate, Girl  |
| H      | /eɪtʃ/     | Hat, House  |

## Common Mistake
❌ Confusing **b** and **d** — the bumps go on opposite sides.
✅ Remember: **b**all bounces **b**efore you throw (bump faces right).

## Practice Exercise
1. Write the alphabet 3 times without looking.
2. Circle all the vowels: a, b, c, d, e, f, g, h, i, j, k
3. Write 2 words for each vowel: A=__, E=__, I=__, O=__, U=__

## Key Takeaways
- 26 total letters: 5 vowels + 21 consonants
- Every word needs at least one vowel
- Capital letters are used at the start of sentences and names''',
            ),
            Lesson(
              id: 'eng-2',
              title: 'Common Greetings & Polite Expressions',
              durationMinutes: 25,
              content: '''# Common Greetings & Polite Expressions

## Learning Objectives
- Use 10+ everyday greetings correctly
- Understand when to use formal vs informal greetings
- Respond politely to common questions

## Time-Based Greetings

| Time of Day | Greeting | When to Use |
|-------------|---------|-------------|
| Before noon | Good morning | 12:00 AM – 11:59 AM |
| Noon to evening | Good afternoon | 12:00 PM – 4:59 PM |
| Evening | Good evening | 5:00 PM – 8:59 PM |
| Parting at night | Good night | When saying goodbye at night |

## Informal Greetings (with friends)
- **Hello / Hi** — most common, always acceptable
- **How are you?** → Reply: *"I'm fine, thank you!"* or *"Very well, thanks!"*
- **What's up?** → Reply: *"Nothing much"* or *"All good"*

## Formal Greetings (with teachers, elders, officials)
- **Good morning, Sir/Ma'am.**
- **How do you do?** → Reply: *"How do you do?"* (same phrase back)
- **It is a pleasure to meet you.**

## Polite Expressions

| Situation | Expression |
|-----------|-----------|
| Asking for something | "Please..." |
| Receiving help | "Thank you" / "Thanks a lot" |
| Apologizing | "Sorry" / "I'm sorry" / "Excuse me" |
| When you don't understand | "Could you please repeat that?" |
| Introducing yourself | "My name is ___. I am from ___." |

## Real-Life Dialogue
**At a shop:**
> A: Good morning! How can I help you?
> B: Good morning! I need 1 kg of sugar, please.
> A: Of course. That will be ₹50.
> B: Thank you very much.
> A: You're welcome. Have a good day!

## Practice
Write a short dialogue (4–6 lines) greeting a teacher you meet in school.

## Key Takeaways
- Use time-based greetings to be specific and respectful
- "Please" and "Thank you" open doors everywhere
- Formal language shows respect for elders and authority figures''',
            ),
            Lesson(
              id: 'eng-3',
              title: 'Numbers 1–100 and Counting',
              durationMinutes: 30,
              content: '''# Numbers 1–100 and Counting

## Learning Objectives
- Read and write numbers 1–100 in English
- Understand patterns in number names
- Use numbers in everyday sentences

## Numbers 1–20 (Irregular — must be memorized)

| Number | Word | Number | Word |
|--------|------|--------|------|
| 1 | One | 11 | Eleven |
| 2 | Two | 12 | Twelve |
| 3 | Three | 13 | Thirteen |
| 4 | Four | 14 | Fourteen |
| 5 | Five | 15 | Fifteen |
| 6 | Six | 16 | Sixteen |
| 7 | Seven | 17 | Seventeen |
| 8 | Eight | 18 | Eighteen |
| 9 | Nine | 19 | Nineteen |
| 10 | Ten | 20 | Twenty |

## The Pattern from 21 onwards
After 20, the pattern is simple: **Tens + Units**

| Tens | 1 | 2 | 3 | 4 | 5 |
|------|---|---|---|---|---|
| Twenty (20) | Twenty-one | Twenty-two | Twenty-three | Twenty-four | Twenty-five |
| Thirty (30) | Thirty-one | Thirty-two | Thirty-three | Thirty-four | Thirty-five |
| Forty (40) | Forty-one | Forty-two | … | … | … |
| Fifty (50) | Fifty-one | … | … | … | … |
| Hundred (100) | **One hundred** | | | | |

**Pattern Rule:** [Tens name] + hyphen + [Units name]
Examples: 63 = Sixty-three, 87 = Eighty-seven, 99 = Ninety-nine

## Using Numbers in Sentences
- "I have **twenty-five** rupees."
- "The bus comes at **seven** o'clock."
- "There are **thirty** students in my class."
- "My house is number **forty-two**."

## Real-World Application
When buying at a market:
> "₹35 please." → "Thirty-five rupees."
> "₹100 please." → "One hundred rupees."

## Practice Exercises
1. Write in words: 17, 38, 55, 72, 94
2. Write as numbers: Forty-six, Sixty-three, Eighty-one
3. Say your phone number digit by digit in English.

## Key Takeaways
- 1–20 must be memorized (irregular names)
- 21–99 follow [Tens] + hyphen + [Units] pattern
- 100 = "One hundred"''',
            ),
            Lesson(
              id: 'eng-4',
              title: 'Simple Sentences: Subject + Verb + Object',
              durationMinutes: 35,
              content: '''# Simple Sentences: Subject + Verb + Object

## Learning Objectives
- Understand the basic sentence structure
- Form 10 correct simple sentences
- Avoid the most common grammar mistakes

## What is a Sentence?
A sentence is a group of words that expresses a **complete thought**.

✅ "The dog barks." — Complete thought
❌ "The dog" — Incomplete (what does it do?)

## Basic Sentence Structure (SVO)

```
Subject → Verb → Object
   Who?   Does what?  To/with what?
```

**Examples:**
| Subject | Verb | Object |
|---------|------|--------|
| I | eat | rice. |
| She | reads | books. |
| They | play | cricket. |
| We | drink | water. |
| He | rides | a bicycle. |

## Subject Pronouns
| Singular | Plural |
|---------|--------|
| I | We |
| You | You |
| He / She / It | They |

## Verb Conjugation (Present Simple)
The verb changes with the subject:

| Subject | Verb "to go" | Example |
|---------|-------------|---------|
| I / You / We / They | go | "I go to school." |
| He / She / It | **goes** | "She goes to school." |

(Add **-s** or **-es** for He/She/It)

## Worked Examples
1. **I** + **drink** + **tea** = "I drink tea."
2. **Ram** + **drives** + **a car** = "Ram drives a car."
3. **The children** + **play** + **football** = "The children play football."

## Common Mistakes
❌ "She go to market." → ✅ "She **goes** to market."
❌ "I eats food." → ✅ "I **eat** food."
❌ "They reads." → ✅ "They **read**."

## Practice
Write 5 sentences about your daily routine:
1. I wake up at __ o'clock.
2. I ___ breakfast.
3. My mother ___ every morning.
4. We ___ to school.
5. My friends and I ___ in the evening.

## Key Takeaways
- Every sentence must have a Subject and a Verb
- Add -s/-es to verbs when the subject is He/She/It
- Object is optional but gives more information''',
            ),
          ],
        ),
        Course(
          id: 'basic-math',
          title: 'Module 2: Mathematics',
          description:
              'Addition, subtraction, multiplication, division, fractions, and real-world mathematics.',
          icon: 'calculate',
          lessons: [
            Lesson(
              id: 'math-1',
              title: 'Addition: Concepts, Methods & Applications',
              durationMinutes: 30,
              content: '''# Addition: Concepts, Methods & Applications

## Learning Objectives
- Understand what addition means conceptually
- Add single-digit, two-digit, and three-digit numbers
- Apply addition to real-life money and measurement problems

## What is Addition?
Addition is the process of **combining two or more quantities** to find the total.

Symbol: **+** (plus sign)
Result called: **Sum**

**Conceptual Example:**
If you have 3 mangoes 🥭🥭🥭 and receive 4 more 🥭🥭🥭🥭, you now have **7 mangoes**.
→ 3 + 4 = **7**

## Properties of Addition

| Property | Rule | Example |
|----------|------|---------|
| Commutative | a + b = b + a | 5 + 3 = 3 + 5 = 8 |
| Associative | (a+b)+c = a+(b+c) | (2+3)+4 = 2+(3+4) = 9 |
| Identity | a + 0 = a | 7 + 0 = 7 |

## Column Addition (Carry Method)

```
  2 5 8
+ 1 3 7
-------
  3 9 5
```

**Step-by-step:**
1. Units: 8 + 7 = 15. Write 5, carry 1.
2. Tens: 5 + 3 + 1(carry) = 9. Write 9.
3. Hundreds: 2 + 1 = 3. Write 3.
**Answer: 395**

## Real-Life Applications

**Market shopping:**
- Rice: ₹45
- Dal: ₹60
- Oil: ₹120

Total = 45 + 60 + 120 = **₹225**

**Time addition:**
- Morning study: 2 hours
- Evening study: 1 hour 30 minutes
- Total: 3 hours 30 minutes

## Practice Problems
1. 47 + 36 = ?
2. 125 + 278 = ?
3. ₹85 + ₹47 + ₹30 = ?
4. You scored 67 in Math and 75 in English. What is your total?

**Answers:** 83 | 403 | ₹162 | 142

## Key Takeaways
- Addition combines quantities; the result is the **sum**
- Use column method for multi-digit numbers (align digits correctly)
- Carrying is required when the sum of a column exceeds 9''',
            ),
            Lesson(
              id: 'math-2',
              title: 'Subtraction: Taking Away and Differences',
              durationMinutes: 30,
              content: '''# Subtraction: Taking Away and Finding Differences

## Learning Objectives
- Understand subtraction as removal and as comparison
- Subtract with and without borrowing
- Solve real-life subtraction problems

## What is Subtraction?
Subtraction means **removing** a quantity from another, or finding the **difference** between two quantities.

Symbol: **−** (minus sign)
Result called: **Difference**

**Two interpretations:**
1. **Take away:** 10 oranges − 4 eaten = 6 remaining
2. **Comparison:** Ravi has ₹80, Meena has ₹50. Difference = 80 − 50 = ₹30 more for Ravi.

## Important Rule
Subtraction is **NOT commutative**:
- 8 − 5 = 3 ✅
- 5 − 8 = −3 (negative — a different concept) 
→ Always subtract the smaller number from the larger in basic arithmetic.

## Subtraction with Borrowing (Regrouping)

```
  5 2 3
- 1 8 7
-------
  3 3 6
```

**Step-by-step:**
1. Units: 3 − 7 impossible → borrow from tens. (13 − 7 = 6). Tens becomes 1.
2. Tens: 1 − 8 impossible → borrow from hundreds. (11 − 8 = 3). Hundreds becomes 4.
3. Hundreds: 4 − 1 = 3.
**Answer: 336**

## Real-Life Applications

**Budget tracking:**
Monthly income: ₹8,000
Expenses: ₹5,500
Savings = 8,000 − 5,500 = **₹2,500**

**Temperature change:**
Morning: 32°C, Evening: 26°C
Drop = 32 − 26 = **6°C**

## Practice Problems
1. 74 − 38 = ?
2. 500 − 263 = ?
3. You have ₹200. You spend ₹135. How much remains?
4. Class has 45 students. 17 are absent. How many are present?

**Answers:** 36 | 237 | ₹65 | 28

## Key Takeaways
- Subtraction finds what remains or the difference between two values
- Borrow from the next column when the digit being subtracted is larger
- Always check: difference + smaller number = larger number''',
            ),
            Lesson(
              id: 'math-3',
              title: 'Multiplication: Repeated Addition and Tables',
              durationMinutes: 35,
              content: '''# Multiplication: Repeated Addition and Tables

## Learning Objectives
- Understand multiplication as repeated addition
- Recall multiplication tables 1–12
- Multiply 2-digit × 1-digit and 2-digit × 2-digit numbers

## What is Multiplication?
Multiplication is **efficient repeated addition**.

Symbol: **×** (times sign)
Result called: **Product**

**Example:** 4 groups of 5 mangoes = 4 × 5 = 20 mangoes
(Same as: 5 + 5 + 5 + 5 = 20)

## Properties of Multiplication

| Property | Rule | Example |
|----------|------|---------|
| Commutative | a × b = b × a | 6 × 4 = 4 × 6 = 24 |
| Associative | (a×b)×c = a×(b×c) | (2×3)×4 = 2×(3×4) = 24 |
| Distributive | a×(b+c) = a×b + a×c | 3×(4+2) = 12+6 = 18 |
| Identity | a × 1 = a | 9 × 1 = 9 |
| Zero | a × 0 = 0 | 7 × 0 = 0 |

## Multiplication Table (7)

| 7 × 1 = 7  | 7 × 7 = 49  |
| 7 × 2 = 14 | 7 × 8 = 56  |
| 7 × 3 = 21 | 7 × 9 = 63  |
| 7 × 4 = 28 | 7 × 10 = 70 |
| 7 × 5 = 35 | 7 × 11 = 77 |
| 7 × 6 = 42 | 7 × 12 = 84 |

## Long Multiplication (2-digit × 2-digit)

```
   3 7
×  2 4
------
  1 4 8   ← 37 × 4
+ 7 4 0   ← 37 × 20
-------
  8 8 8
```

## Real-Life Applications

**Cost calculation:**
If 1 litre of milk = ₹55, then 7 litres = 7 × 55 = **₹385**

**Area of a field:**
Length = 25 metres, Width = 18 metres
Area = 25 × 18 = **450 square metres**

**Work rate:**
A worker makes 12 bricks per hour. In 8 hours: 12 × 8 = **96 bricks**

## Practice Problems
1. 8 × 9 = ?
2. 45 × 6 = ?
3. 23 × 17 = ?
4. If 1 kg rice costs ₹48, what is the cost of 15 kg?

**Answers:** 72 | 270 | 391 | ₹720

## Key Takeaways
- Multiplication is faster than repeated addition
- Memorize tables 1–12 for speed
- Long multiplication: multiply by each digit separately, then add''',
            ),
            Lesson(
              id: 'math-4',
              title: 'Division: Equal Sharing and Grouping',
              durationMinutes: 30,
              content: '''# Division: Equal Sharing and Grouping

## Learning Objectives
- Understand division as equal sharing and repeated subtraction
- Perform long division with remainders
- Apply division to real-world contexts

## What is Division?
Division means **splitting into equal groups** or finding **how many times one number fits into another**.

Symbol: **÷** (obelus) or **/** (slash) or using the division bar
Result called: **Quotient**
Leftover: **Remainder**

**Two interpretations:**
1. **Sharing equally:** ₹100 shared among 4 friends = ₹25 each (100 ÷ 4 = 25)
2. **Grouping:** 20 apples, 5 per bag = 4 bags (20 ÷ 5 = 4)

## Division Vocabulary
```
Dividend ÷ Divisor = Quotient (Remainder R)

Example: 25 ÷ 4 = 6 remainder 1
         25 is Dividend, 4 is Divisor, 6 is Quotient, 1 is Remainder
```

## Check: Division Inverse of Multiplication
**(Quotient × Divisor) + Remainder = Dividend**
→ (6 × 4) + 1 = 24 + 1 = 25 ✅

## Long Division Method

**Example: 847 ÷ 7**

```
    1 2 1
  --------
7 | 8 4 7
    7
   ---
    1 4
    1 4
   ---
      7
      7
   ---
      0
```

**Step-by-step:**
1. 8 ÷ 7 = 1 remainder 1. Bring down 4 → 14.
2. 14 ÷ 7 = 2 remainder 0. Bring down 7 → 7.
3. 7 ÷ 7 = 1 remainder 0.
**Answer: 121**

## Real-Life Applications

**Equal distribution:**
60 kg of grain distributed among 12 families = 60 ÷ 12 = **5 kg each**

**Time planning:**
120 minutes of study, 4 subjects = 120 ÷ 4 = **30 minutes per subject**

**Cost per unit:**
12 pencils cost ₹36. Cost per pencil = 36 ÷ 12 = **₹3 each**

## Practice Problems
1. 72 ÷ 8 = ?
2. 156 ÷ 12 = ?
3. 500 kg of food for 8 days. Per day = ?
4. You have ₹247. Tickets cost ₹30 each. How many can you buy?

**Answers:** 9 | 13 | 62.5 kg | 8 tickets (₹7 remaining)

## Key Takeaways
- Division = sharing equally or grouping
- Always verify: Quotient × Divisor + Remainder = Dividend
- Remainder must always be less than the Divisor''',
            ),
          ],
        ),
        Course(
          id: 'science-nature',
          title: 'Module 3: Science & Nature',
          description:
              'Understanding the natural world through water cycle, photosynthesis, ecosystems, and human biology.',
          icon: 'science',
          lessons: [
            Lesson(
              id: 'sci-1',
              title: 'The Water Cycle',
              durationMinutes: 35,
              content: '''# The Water Cycle (Hydrological Cycle)

## Learning Objectives
- Explain the four main stages of the water cycle
- Understand why the water cycle is essential for life
- Connect the water cycle to local weather patterns

## What is the Water Cycle?
The water cycle is the **continuous movement of water** between the earth's surface and the atmosphere. It has no beginning or end — it is a perpetual natural process.

## The Four Main Stages

### 1. Evaporation
**What happens:** Heat from the Sun converts liquid water from oceans, rivers, and lakes into **water vapour** (invisible gas).

**Key facts:**
- Oceans are the largest source (about 86% of evaporation)
- Warm temperatures speed up evaporation
- This is why puddles disappear on sunny days

**Formula concept:** Water (liquid) + Heat → Water vapour (gas)

### 2. Condensation
**What happens:** As water vapour rises, it cools and converts back into **tiny water droplets**, forming clouds and fog.

**Why it happens:** Cool air holds less water vapour. When warm moist air rises and cools, the vapour condenses around tiny dust particles.

**You see this daily:** Dew drops on leaves in the morning = condensation.

### 3. Precipitation
**What happens:** When water droplets in clouds combine and become heavy enough, they fall as **rain, snow, sleet, or hail**.

**Types of precipitation:**
| Type | Conditions |
|------|-----------|
| Rain | Temperature above 0°C |
| Snow | Very cold air (below 0°C) |
| Hail | Strong thunderstorms with freezing air above |
| Sleet | Mix of rain and snow |

### 4. Collection (Runoff & Infiltration)
**What happens:** Precipitation collects in:
- **Oceans, rivers, lakes** (surface water)
- **Underground** (groundwater via infiltration through soil)

The cycle then **repeats**.

## Why is the Water Cycle Important?
1. **Freshwater supply** — Purifies and redistributes water globally
2. **Temperature regulation** — Evaporation cools the Earth
3. **Weather patterns** — Drives rain, monsoon, and seasons
4. **Agriculture** — Rain replenishes rivers and groundwater used for irrigation

## Local Connection (India)
The **Indian Monsoon** is a large-scale manifestation of the water cycle:
- June–September: Moisture evaporates from Indian Ocean
- Winds carry clouds over land
- Precipitation brings 70–90% of India's annual rainfall

## Practice Questions
1. What is the process that turns liquid water into vapour?
2. Why does dew form on grass in the early morning?
3. List three ways humans benefit from the water cycle.
4. Draw and label all four stages of the water cycle.

## Key Takeaways
- Water constantly cycles: Evaporation → Condensation → Precipitation → Collection
- The Sun provides the energy that drives the entire cycle
- The water cycle purifies water naturally through evaporation''',
            ),
            Lesson(
              id: 'sci-2',
              title: 'Photosynthesis: How Plants Make Food',
              durationMinutes: 40,
              content: '''# Photosynthesis: How Plants Make Food

## Learning Objectives
- Write the photosynthesis equation in words and symbols
- Identify the raw materials and products of photosynthesis
- Explain why photosynthesis is essential for all life on Earth

## What is Photosynthesis?
Photosynthesis is the process by which **green plants use sunlight to convert carbon dioxide and water into glucose (food) and oxygen**.

The word itself: "Photo" = light, "Synthesis" = making something

## The Equation

### Word Equation:
```
Carbon Dioxide + Water  →(Sunlight)→  Glucose + Oxygen
```

### Chemical Equation:
```
6CO₂ + 6H₂O  →(light energy + chlorophyll)→  C₆H₁₂O₆ + 6O₂
```

## Where Does Photosynthesis Happen?

**Location:** Inside plant cells, specifically in the **chloroplasts**.

**Chlorophyll:** The green pigment inside chloroplasts that captures light energy.
→ This is why leaves are GREEN.

## Raw Materials and Products

| What goes IN | What comes OUT |
|-------------|---------------|
| Carbon dioxide (CO₂) from air | Glucose (C₆H₁₂O₆) — plant food |
| Water (H₂O) from roots | Oxygen (O₂) released into air |
| Light energy from Sun | Chemical energy stored in glucose |

## The Two Stages (Simplified)

### Stage 1: Light Reactions (Light-dependent)
- Happens in the presence of light
- Water molecules are split
- Energy from sunlight is captured
- Oxygen is released as a byproduct

### Stage 2: Calvin Cycle / Dark Reactions
- Can happen without direct light
- CO₂ is converted into glucose
- Uses energy captured in Stage 1

## Why is Photosynthesis Important for Everything?
1. **Plants make their own food** (autotrophs) — they don't need to eat other organisms
2. **Oxygen production** — almost all atmospheric oxygen comes from photosynthesis
3. **Food chain foundation** — all animals ultimately depend on plant glucose for energy
4. **Carbon dioxide removal** — helps reduce greenhouse gases

**A single large tree can produce enough oxygen for 4 people per day.**

## Factors Affecting Photosynthesis Rate

| Factor | Effect when Increased |
|--------|----------------------|
| Light intensity | Increases rate (up to a limit) |
| CO₂ concentration | Increases rate (up to a limit) |
| Temperature | Increases rate until ~35°C; drops above that |
| Water | Shortage slows or stops photosynthesis |

## Practice Questions
1. Write the word equation for photosynthesis.
2. What is the role of chlorophyll?
3. Why would a plant in a dark room eventually die?
4. How does photosynthesis affect the air we breathe?
5. If you sealed a plant in a glass jar with sunlight and CO₂, what would happen?

## Key Takeaways
- Plants are the only organisms that make their own food using light
- Raw materials: CO₂ + H₂O | Products: Glucose + O₂
- Chlorophyll (in chloroplasts) captures light energy
- Without photosynthesis, almost no life on Earth would survive''',
            ),
          ],
        ),
        Course(
          id: 'digital-literacy',
          title: 'Module 4: Digital Literacy',
          description:
              'Smartphone skills, internet safety, online payments, and responsible digital citizenship.',
          icon: 'computer',
          lessons: [
            Lesson(
              id: 'dig-1',
              title: 'Using a Smartphone Effectively',
              durationMinutes: 40,
              content: '''# Using a Smartphone Effectively

## Learning Objectives
- Perform 10 essential smartphone tasks confidently
- Understand storage, battery, and app management
- Stay safe while using your phone

## Essential Smartphone Skills

### Turning ON and OFF
- **Power ON:** Hold the power button for 2–3 seconds
- **Power OFF:** Hold power button → slide "Power off"
- **Restart:** Hold power button → tap "Restart"

### Making and Receiving Calls
1. Open the **Phone** app (green icon)
2. Tap the keypad icon
3. Dial the number (include 0 for local, +91 for India from abroad)
4. Tap the green call button
5. **To end:** Tap the red end button

### Sending Messages (SMS / WhatsApp)
- **SMS:** Open Messages → New Message → Type number → Type text → Send
- **WhatsApp:** Open WhatsApp → tap Contact → Type message → tap send arrow

### Taking Photos
1. Open **Camera** app
2. Frame your subject
3. Tap the large circle button to shoot
4. Tap the photo preview to view it

## Battery Management

| Battery Level | Action Recommended |
|--------------|-------------------|
| 80–100% | Normal use |
| 30–79% | Normal use |
| 15–29% | Find charger soon |
| Below 15% | Enable Power Saving mode |
| 0% | Stop using immediately |

**Battery Tips:**
- Reduce screen brightness when possible
- Turn off WiFi/Bluetooth when not needed
- Close apps running in the background

## Managing Storage
- Check storage: Settings → Storage
- Delete photos you no longer need
- Uninstall apps you never use
- Move photos to Google Photos or cloud backup

## Essential Apps for Students

| App | Purpose | Free? |
|-----|---------|-------|
| Google Translate | Language translation | Yes |
| Dictionary.com | Word meanings | Yes |
| Khan Academy | Free learning videos | Yes |
| YouTube | Educational videos | Yes |
| Google Maps | Navigation | Yes |
| DIKSHA | Government education | Yes |

## Practice Tasks
1. Find your phone's storage status in Settings.
2. Take 3 photos and delete 1 from your gallery.
3. Send a test message to yourself.
4. Install one educational app from the list above.

## Key Takeaways
- Smartphones are powerful learning tools when used wisely
- Battery and storage management extend your phone's useful life
- Free apps like Khan Academy and DIKSHA offer quality education offline''',
            ),
            Lesson(
              id: 'dig-2',
              title: 'Internet Safety and Digital Citizenship',
              durationMinutes: 35,
              content: '''# Internet Safety and Digital Citizenship

## Learning Objectives
- Identify 5 types of online threats
- Create and manage strong passwords
- Recognize and avoid online scams
- Understand digital footprint

## The 5 Main Online Threats

### 1. Phishing
**What it is:** Fake messages (email/SMS/WhatsApp) pretending to be a bank, government, or company, asking you to click a link or share details.

**Real example:**
> "Your bank account will be blocked. Click here immediately: www.fakebanksite.com"

**Red flags:** Urgency, suspicious links, requests for OTP/password, bad spelling.

### 2. Malware
Harmful software downloaded accidentally. Can steal data, slow your phone, or display spam ads.

**Prevention:** Only install apps from Google Play Store or Apple App Store.

### 3. Online Scams
Fake prizes, fake job offers, fake loan apps that charge hidden fees.

**Rule:** If it sounds too good to be true, it is a scam.

### 4. Privacy Violations
Sharing photos, location, or personal info publicly that can be misused.

**Rule:** Never share your home address, school name, or daily routine publicly.

### 5. Cyberbullying
Harassment, threats, or humiliation through digital channels.

**Action:** Block the person, don't respond, save evidence (screenshot), tell a trusted adult.

## Creating Strong Passwords

### Weak Passwords (NEVER use these):
- 123456, password, abcd, your birthday, your name

### Strong Password Formula:
Mix: **UPPERCASE + lowercase + Numbers + Symbols**

Example: `SunFlower@2024!` (14 characters — very strong)

### Password Best Practices:
1. Use different passwords for each account
2. Change passwords every 3–6 months
3. Never share passwords with anyone, even friends
4. Use a password manager app if possible

## Safe UPI/Online Payment Practices

| DO ✅ | DON'T ❌ |
|-------|--------|
| Check the recipient name before paying | Share your UPI PIN with anyone |
| Use official apps (PhonePe, GPay, BHIM) | Click payment links in messages |
| Verify the amount before confirming | Accept unsolicited "refund" requests |
| Check bank balance after transactions | Use public WiFi for banking |

## Your Digital Footprint
Everything you do online leaves a trace. This includes:
- Photos and comments you post
- Websites you visit
- Apps you use

**Think before you post:** Employers, teachers, and colleges may search your name online.

## Practice
1. Check: Is your social media profile public or private?
2. Test your password strength at: haveibeenpwned.com
3. List 3 pieces of information you should NEVER share online.

## Key Takeaways
- Never share OTP, PIN, or passwords — not even with "bank officials"
- Phishing attacks look real; always verify before clicking
- Strong passwords = long + mixed characters
- Your digital footprint is permanent — think before you post''',
            ),
          ],
        ),
        Course(
          id: 'financial-literacy',
          title: 'Module 5: Financial Literacy',
          description:
              'Banking basics, saving strategies, UPI payments, loans, insurance, and managing household finances.',
          icon: 'account_balance',
          lessons: [
            Lesson(
              id: 'fin-1',
              title: 'Opening and Using a Bank Account',
              durationMinutes: 40,
              content: '''# Opening and Using a Bank Account

## Learning Objectives
- Understand the different types of bank accounts
- Know the documents required to open an account
- Perform basic banking transactions confidently

## Why Have a Bank Account?

| Without a bank account | With a bank account |
|-----------------------|-------------------|
| Cash unsafe at home | Money safe (insured up to ₹5 lakh) |
| No interest earned | Earn 3–4% annual interest |
| Cannot receive government benefits | Direct DBT (govt benefits) to account |
| No financial history | Builds credit history for loans |
| Cash theft risk | Debit card / UPI for safer payments |

## Types of Bank Accounts

### 1. Savings Account (Most Common)
- For keeping personal savings
- Earns 3–4% annual interest
- Can withdraw anytime
- Minimum balance: ₹0 to ₹10,000 (varies by bank)

### 2. Jan Dhan Account (Government Scheme)
- **Zero minimum balance required**
- Overdraft facility up to ₹10,000
- Free RuPay debit card
- Life insurance cover of ₹2 lakh included
- Open at any government bank

### 3. Current Account
- For business transactions
- Higher transaction limits
- No interest earned
- Higher minimum balance required

## Documents Required

| Document | Acceptable Examples |
|----------|-------------------|
| Photo ID Proof | Aadhaar card, Voter ID, Passport, Driving License |
| Address Proof | Aadhaar, Electricity bill, Ration card |
| Photographs | 2 passport-size photos |
| Initial deposit | ₹0 for Jan Dhan, ₹100–₹1000 for others |

## How to Use Your Account

### ATM / Debit Card
1. Insert card into ATM
2. Enter 4-digit PIN (secret — never share)
3. Select transaction: Balance inquiry, Cash withdrawal, etc.
4. Collect cash and card

### Passbook Update
A physical record of all transactions. Update at the bank counter monthly.

### Cheque
- Written instruction to bank to pay a specific person a specific amount
- Sign the cheque exactly as on the account

## Bank Safety Rules
1. **Never share ATM PIN** — not with bank staff, not with family (unless emergency)
2. **Check your passbook/statement** monthly for unauthorized transactions
3. **Report lost card** immediately: Call the bank's 24-hour toll-free number
4. **Never write your PIN on the card**

## Practice
1. Visit the nearest bank and ask for a Jan Dhan Account form.
2. Identify all the documents you currently have.
3. What is the current interest rate of SBI Savings Account? (Check online or ask at bank)

## Key Takeaways
- Jan Dhan account: zero balance, free insurance, government benefit eligible
- Never share ATM PIN or OTP with anyone
- Check your bank statement monthly to spot errors or fraud''',
            ),
            Lesson(
              id: 'fin-2',
              title: 'UPI Payments: Sending and Receiving Money Safely',
              durationMinutes: 35,
              content: '''# UPI Payments: Sending and Receiving Money Safely

## Learning Objectives
- Understand how UPI (Unified Payments Interface) works
- Set up and use a UPI account safely
- Identify and avoid UPI scams

## What is UPI?
UPI (Unified Payments Interface) is India's **real-time digital payment system** created by the National Payments Corporation of India (NPCI).

- Works 24/7, 365 days a year
- Transfers happen within seconds
- Free for individuals (banks do not charge for UPI transfers)
- Works over mobile internet (even 2G)

## Popular UPI Apps

| App | Creator | Special Features |
|-----|---------|-----------------|
| PhonePe | Walmart/Flipkart | Insurance, investments |
| Google Pay (GPay) | Google | Rewards, bill payments |
| BHIM | NPCI (Govt) | Simple, minimal, official |
| Paytm | Paytm | Wallet + UPI combo |
| Amazon Pay | Amazon | Shopping integration |

## How UPI Works

### Setting Up (One-time)
1. Download a UPI app
2. Register with your mobile number (linked to bank account)
3. Add your bank account
4. Set a **UPI PIN** (4 or 6 digits — used to authorize payments)

### Your UPI ID (VPA - Virtual Payment Address)
Format: `yourname@bankname` (e.g., ravi123@sbi, meena@paytm)
→ This is your "payment address" — share it to receive money

### Sending Money
1. Open UPI app → tap "Send"
2. Enter recipient's UPI ID, phone number, or scan QR code
3. Enter amount
4. Enter your UPI PIN to confirm
5. Money reaches within seconds

### Receiving Money
Share your UPI ID or show your QR code.
You do NOT need a PIN to receive money.

## Common UPI Transactions

| Purpose | How |
|---------|-----|
| Pay at shops | Scan shopkeeper's QR code |
| Send to friend | Enter their UPI ID or phone number |
| Pay electricity bill | Search "Electricity" in app |
| Buy bus/train ticket | IRCTC + UPI |
| Receive salary | Share your UPI ID with employer |

## UPI Scam Patterns to Know

### Scam 1: "Collect Request" Trick
You receive a money "collect request" that says "Approve ₹500 to RECEIVE ₹5000."
**Reality:** Approving means YOU send ₹500. You never receive anything.
**Rule: ENTERING YOUR UPI PIN = SENDING MONEY. NEVER enter PIN to "receive".**

### Scam 2: Fake Customer Care
Scammer calls pretending to be PhonePe/GPay support. Asks for UPI PIN or OTP.
**Rule: Real UPI companies NEVER ask for your PIN.**

### Scam 3: Screen Sharing Fraud
Scammer asks you to install "AnyDesk" or "TeamViewer" to "help" you.
**Rule: Never share your screen with strangers. Uninstall these apps.**

## Practice Tasks
1. Download BHIM app (official government UPI app)
2. Find your UPI ID in the app
3. Send ₹1 to a family member to test the system
4. Ask a shopkeeper if they accept UPI, and practice scanning their QR code

## Key Takeaways
- UPI = instant, free, 24/7 bank-to-bank transfers
- You ONLY need your PIN to SEND money — never to receive
- Never share UPI PIN or OTP with anyone, ever
- BHIM is the official government app — always safe to use''',
            ),
          ],
        ),
      ];

  /// Get all courses (downloads + built-in).
  Future<List<Course>> allCourses() async => builtInCourses;

  /// Download a course to user-scoped local storage.
  Future<void> downloadCourse(Course course) async {
    await UserStore.setCourseState(
        course.id, courseStateToString(CourseState.downloading));
    try {
      await UserStore.setCourseData(course.id, jsonEncode(course.toJson()));
      await UserStore.setCourseState(
          course.id, courseStateToString(CourseState.downloaded));
      await UserStore.setCourseProgress(course.id, 0.0);
    } catch (_) {
      await UserStore.setCourseState(
          course.id, courseStateToString(CourseState.failed));
      rethrow;
    }
  }

  /// Delete a downloaded course for the current user.
  Future<void> removeCourse(String courseId) async {
    await UserStore.deleteCourse(courseId);
  }

  /// Get the current download state of a course for this user.
  CourseState getState(String courseId) =>
      parseCourseState(UserStore.courseState(courseId));

  /// Get real learning progress (0.0–1.0) for a course.
  /// Computed from actual lesson completion — never hardcoded.
  double getProgress(String courseId) =>
      UserStore.courseProgress(courseId);
}
