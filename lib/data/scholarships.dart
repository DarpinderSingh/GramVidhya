/// SAMPLE DATA for demonstration. Verify amounts, caps and eligibility on scholarships.gov.in and update this list each year.
class Scheme {
  const Scheme(this.name, this.body, this.levels, this.note,
      {this.groups = const {},
      this.incomeCapLakh,
      this.girlsOnly = false,
      this.pwdOnly = false,
      this.amount,
      this.documents = const [],
      this.applicationProcess,
      this.deadline,
      this.eligibility,
      this.website});
  final String name, body, note;
  final Set<String> levels, groups; // empty groups = open to all
  final double? incomeCapLakh;
  final bool girlsOnly, pwdOnly;
  final String? amount;
  final List<String> documents;
  final String? applicationProcess;
  final String? deadline;
  final String? eligibility;
  final String? website;
}

const schemes = <Scheme>[
  Scheme(
    'Post Matric Scholarship for ST',
    'Ministry of Tribal Affairs (NSP)',
    {'UG', 'PG', 'Diploma'},
    'Course fees and maintenance for Scheduled Tribe students.',
    groups: {'ST'},
    incomeCapLakh: 2.5,
    amount: 'Full tuition fees + maintenance allowance (₹380-1200/month depending on hosteller/day scholar)',
    documents: ['Caste certificate (ST)', 'Income certificate', 'Previous year marksheet', 'Bank account details', 'Aadhaar card', 'Institute bonafide certificate'],
    applicationProcess: '1. Register on National Scholarship Portal (scholarships.gov.in)\n2. Fill application form with personal and academic details\n3. Upload required documents\n4. Submit to institute for verification\n5. Institute verifies and forwards to district/state nodal officer\n6. Renewal required each year with updated marksheets',
    eligibility: 'Must belong to Scheduled Tribe category. Family annual income must not exceed ₹2.5 lakh. Must have passed matric/Class 10. Must be enrolled in a recognized institution for post-matric course.',
    deadline: 'Usually October-November each year (check NSP for current year)',
    website: 'scholarships.gov.in',
  ),
  Scheme(
    'Post Matric Scholarship for SC',
    'Ministry of Social Justice (NSP)',
    {'UG', 'PG', 'Diploma'},
    'Fees and maintenance for Scheduled Caste students.',
    groups: {'SC'},
    incomeCapLakh: 2.5,
    amount: 'Full tuition fees + maintenance allowance (₹380-1200/month depending on hosteller/day scholar)',
    documents: ['Caste certificate (SC)', 'Income certificate', 'Previous year marksheet', 'Bank account details', 'Aadhaar card', 'Institute bonafide certificate'],
    applicationProcess: '1. Register on National Scholarship Portal\n2. Fill application form\n3. Upload documents\n4. Institute verification\n5. District/State officer approval\n6. Amount disbursed to bank account',
    eligibility: 'Must belong to Scheduled Caste category. Family annual income must not exceed ₹2.5 lakh. Must have passed Class 10.',
    deadline: 'Usually October-November each year (check NSP for current year)',
    website: 'scholarships.gov.in',
  ),
  Scheme(
    'PM YASASVI',
    'Ministry of Social Justice (NSP)',
    {'UG', 'PG', 'Diploma'},
    'For OBC, EBC and DNT students.',
    groups: {'OBC'},
    incomeCapLakh: 2.5,
    amount: '₹75,000/year for top class schools; ₹1,25,000/year for professional courses',
    documents: ['OBC/EBC/DNT certificate', 'Income certificate', 'Marksheets', 'Bank account details', 'Aadhaar card'],
    applicationProcess: '1. Register on NSP\n2. Apply under PM-YASASVI scheme\n3. May require entrance test (YASASVI Entrance Test)\n4. Score-based selection\n5. Document verification\n6. Scholarship disbursement',
    eligibility: 'Must belong to OBC, EBC, or DNT category. Family income must not exceed ₹2.5 lakh/year. Age 18-25 for UG courses.',
    deadline: 'Check NSP annually, usually July-August for entrance test',
    website: 'scholarships.gov.in',
  ),
  Scheme(
    'Merit-cum-Means Scholarship',
    'Ministry of Minority Affairs (NSP)',
    {'UG', 'PG', 'Diploma'},
    'Professional and technical courses for notified minorities.',
    groups: {'Minority'},
    incomeCapLakh: 2.5,
    amount: 'Course fee or ₹20,000 per annum (whichever is less) + ₹1,000/month maintenance',
    documents: ['Minority community certificate', 'Income certificate', 'Marksheets', 'Fee receipt', 'Bank account details', 'Aadhaar card'],
    applicationProcess: '1. Register on NSP\n2. Fill application under Minority Affairs schemes\n3. Upload documents\n4. Institute verification\n5. State nodal agency verification\n6. Scholarship disbursement to bank',
    eligibility: 'Must belong to notified minority community. Family income not exceeding ₹2.5 lakh/year. Minimum 50% marks in previous exam.',
    deadline: 'Usually September-October each year',
    website: 'scholarships.gov.in',
  ),
  Scheme(
    'Central Sector Scholarship for College Students',
    'Dept. of Higher Education (NSP)',
    {'UG', 'PG'},
    'Needs a high Class 12 board percentile.',
    incomeCapLakh: 4.5,
    amount: '₹10,000/year for first 3 years of UG; ₹20,000/year for PG',
    documents: ['Class 12 marksheet', 'Income certificate', 'Bank account details', 'Aadhaar card', 'College admission proof'],
    applicationProcess: '1. Register on NSP\n2. Apply under Central Sector Scheme\n3. Must be in top 20th percentile of Class 12 board exam\n4. Document verification\n5. Merit-based selection\n6. Disbursement to bank account',
    eligibility: 'Must be in top 20th percentile of successful candidates in Class 12 board exam. Family income not exceeding ₹4.5 lakh/year. Must not be receiving other scholarships.',
    deadline: 'Usually October-November each year',
    website: 'scholarships.gov.in',
  ),
  Scheme(
    'AICTE Pragati',
    'AICTE',
    {'UG', 'Diploma'},
    'Girls in AICTE-approved technical programmes.',
    incomeCapLakh: 8,
    girlsOnly: true,
    amount: '₹50,000 per year (max 2 years for Diploma, 4 years for Degree)',
    documents: ['AICTE approval letter of institute', 'Income certificate', 'Marksheets', 'Aadhaar card', 'Bank account', 'Fee receipt'],
    applicationProcess: '1. Apply through AICTE portal\n2. Institute must be AICTE-approved\n3. Must be admitted to first year of technical programme\n4. Upload documents\n5. Institute verification\n6. AICTE selection and disbursement',
    eligibility: 'Girl students only. Admitted in first year of AICTE-approved technical institution. Family income not exceeding ₹8 lakh/year. Only 2 girl children per family eligible.',
    deadline: 'Usually December-January',
    website: 'aicte-india.org',
  ),
  Scheme(
    'AICTE Saksham',
    'AICTE',
    {'UG', 'Diploma'},
    'Students with disabilities in technical programmes.',
    incomeCapLakh: 8,
    pwdOnly: true,
    amount: '₹50,000 per year (max 2 years for Diploma, 4 years for Degree)',
    documents: ['Disability certificate (40%+)', 'AICTE approval letter of institute', 'Income certificate', 'Marksheets', 'Aadhaar card', 'Bank account'],
    applicationProcess: '1. Apply through AICTE portal\n2. Must have disability certificate (40% or more)\n3. Institute must be AICTE-approved\n4. Upload documents\n5. Verification and selection by AICTE',
    eligibility: 'Students with 40%+ disability. Admitted to AICTE-approved institution. Family income not exceeding ₹8 lakh/year.',
    deadline: 'Usually December-January',
    website: 'aicte-india.org',
  ),
];

List<Scheme> matchSchemes({required String group, required String level, required double incomeLakh, bool girl = false, bool pwd = false}) =>
    schemes
        .where((s) =>
            s.levels.contains(level) &&
            (s.groups.isEmpty || s.groups.contains(group)) &&
            (s.incomeCapLakh == null || incomeLakh <= s.incomeCapLakh!) &&
            (!s.girlsOnly || girl) &&
            (!s.pwdOnly || pwd))
        .toList();
