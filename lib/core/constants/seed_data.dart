class SeedSubject {
  const SeedSubject({
    required this.name,
    required this.code,
    this.isElective = false,
  });

  final String name;
  final String code;
  final bool isElective;
}

class SeedData {
  static const universities = [
    'IIT Bombay',
    'University of Delhi',
    'BHU Varanasi',
    'Osmania University',
    'Dr Manmohan Singh Bengaluru City University',
    'Jadavpur University',
    'University of Mysore',
    'Other',
  ];

  static const semesters = [1, 2, 3, 4];

  static const mscChemistrySubjects = [
    SeedSubject(name: 'Organic Reaction Mechanisms', code: 'CH 301 OC'),
    SeedSubject(name: 'Organic Synthesis', code: 'CH 302 OC'),
    SeedSubject(name: 'Organic Spectroscopy', code: 'CH 303 OC'),
    SeedSubject(name: 'Inorganic Reaction Mechanisms', code: 'CH 301 IC'),
    SeedSubject(name: 'Open Elective', code: 'OE', isElective: true),
  ];
}
