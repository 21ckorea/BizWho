class Employee {
  final int? id;
  final String department;
  final String name;
  final String rank;
  final String position;
  final String email;
  final String phoneNumber;
  final String officePhone;

  Employee({
    this.id,
    required this.department,
    required this.name,
    required this.rank,
    required this.position,
    required this.email,
    required this.phoneNumber,
    required this.officePhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department': department,
      'name': name,
      'rank': rank,
      'position': position,
      'email': email,
      'phone_number': phoneNumber,
      'office_phone': officePhone,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      department: map['department'] ?? '',
      name: map['name'] ?? '',
      rank: map['rank'] ?? '',
      position: map['position'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      officePhone: map['office_phone'] ?? '',
    );
  }
}
