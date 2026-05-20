class Course {
  String code;
  String name;
  double credit;
  String grade;

  Course({
    required this.code,
    required this.name,
    required this.credit,
    required this.grade,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: json['code'],
      name: json['name'],
      credit: double.tryParse(json['credit'].toString()) ?? 0.0,
      grade: json['grade'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'credit': credit.toString(),
      'grade': grade,
    };
  }

  Course copyWith({
    String? code,
    String? name,
    double? credit,
    String? grade,
  }) {
    return Course(
      code: code ?? this.code,
      name: name ?? this.name,
      credit: credit ?? this.credit,
      grade: grade ?? this.grade,
    );
  }
}
