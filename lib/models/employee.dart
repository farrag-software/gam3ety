class Employee {
  final int? id;
  final String name;
  final String nationalId;
  final String phone;
  final int familyMembers;
  final double monthlySalary;
  final String notes;
  final String createdAt;

  const Employee({
    this.id,
    required this.name,
    required this.nationalId,
    required this.phone,
    required this.familyMembers,
    required this.monthlySalary,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'national_id': nationalId,
    'phone': phone,
    'family_members': familyMembers,
    'monthly_salary': monthlySalary,
    'notes': notes,
    'created_at': createdAt,
  };

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: map['id'] as int?,
    name: map['name'] as String,
    nationalId: map['national_id'] as String,
    phone: map['phone'] as String,
    familyMembers: map['family_members'] as int,
    monthlySalary: (map['monthly_salary'] as num).toDouble(),
    notes: map['notes'] as String,
    createdAt: map['created_at'] as String,
  );

  Employee copyWith({
    int? id,
    String? name,
    String? nationalId,
    String? phone,
    int? familyMembers,
    double? monthlySalary,
    String? notes,
    String? createdAt,
  }) => Employee(
    id: id ?? this.id,
    name: name ?? this.name,
    nationalId: nationalId ?? this.nationalId,
    phone: phone ?? this.phone,
    familyMembers: familyMembers ?? this.familyMembers,
    monthlySalary: monthlySalary ?? this.monthlySalary,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
}
