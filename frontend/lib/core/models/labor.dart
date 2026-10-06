class LaborWorker {
  final int id;
  final int tenantId;
  final String name;
  final String skillCategory;
  final double dailyRate;
  final String contactNumber;

  LaborWorker({
    this.id = 0,
    this.tenantId = 0,
    required this.name,
    this.skillCategory = '',
    this.dailyRate = 0,
    this.contactNumber = '',
  });

  factory LaborWorker.fromJson(Map<String, dynamic> json) {
    return LaborWorker(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      skillCategory: json['skill_category']?.toString() ?? '',
      dailyRate: (json['daily_rate'] is num)
          ? (json['daily_rate'] as num).toDouble()
          : double.tryParse(json['daily_rate']?.toString() ?? '0') ?? 0,
      contactNumber: json['contact_number']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'skill_category': skillCategory,
      'daily_rate': dailyRate,
    };
  }
}

class AttendanceLog {
  final int id;
  final int laborWorkerId;
  final String date;
  final String status;
  final double overtimeHours;

  AttendanceLog({
    this.id = 0,
    required this.laborWorkerId,
    required this.date,
    this.status = 'Present',
    this.overtimeHours = 0,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      laborWorkerId: json['labor_worker_id'] is int
          ? json['labor_worker_id']
          : int.tryParse(json['labor_worker_id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Present',
      overtimeHours: (json['overtime_hours'] is num)
          ? (json['overtime_hours'] as num).toDouble()
          : double.tryParse(json['overtime_hours']?.toString() ?? '0') ?? 0,
    );
  }
}

class PayrollRecord {
  final int id;
  final int laborWorkerId;
  final String month;
  final double wagesEarned;
  final String status;

  PayrollRecord({
    this.id = 0,
    required this.laborWorkerId,
    required this.month,
    this.wagesEarned = 0,
    this.status = 'Unpaid',
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      laborWorkerId: json['labor_worker_id'] is int
          ? json['labor_worker_id']
          : int.tryParse(json['labor_worker_id']?.toString() ?? '0') ?? 0,
      month: json['month']?.toString() ?? '',
      wagesEarned: (json['wages_earned'] is num)
          ? (json['wages_earned'] as num).toDouble()
          : double.tryParse(json['wages_earned']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'Unpaid',
    );
  }
}
