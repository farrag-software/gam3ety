class Payment {
  final int? id;
  final int employeeId;
  final String monthLabel; // e.g. "يناير ٢٠٢٤"
  final int month; // 1–12
  final int year;
  final double amount;
  final bool received;
  final String date; // ISO date string

  const Payment({
    this.id,
    required this.employeeId,
    required this.monthLabel,
    required this.month,
    required this.year,
    required this.amount,
    required this.received,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'employee_id': employeeId,
    'month_label': monthLabel,
    'month': month,
    'year': year,
    'amount': amount,
    'received': received ? 1 : 0,
    'date': date,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'] as int?,
    employeeId: map['employee_id'] as int,
    monthLabel: map['month_label'] as String,
    month: map['month'] as int,
    year: map['year'] as int,
    amount: (map['amount'] as num).toDouble(),
    received: (map['received'] as int) == 1,
    date: map['date'] as String,
  );

  Payment copyWith({
    int? id,
    int? employeeId,
    String? monthLabel,
    int? month,
    int? year,
    double? amount,
    bool? received,
    String? date,
  }) => Payment(
    id: id ?? this.id,
    employeeId: employeeId ?? this.employeeId,
    monthLabel: monthLabel ?? this.monthLabel,
    month: month ?? this.month,
    year: year ?? this.year,
    amount: amount ?? this.amount,
    received: received ?? this.received,
    date: date ?? this.date,
  );
}
