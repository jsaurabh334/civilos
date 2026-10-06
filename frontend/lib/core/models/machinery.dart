class Machinery {
  final int id;
  final int tenantId;
  final String name;
  final String modelNumber;
  final double hourlyRate;
  final double totalHoursRun;
  final String status;

  Machinery({
    this.id = 0,
    this.tenantId = 0,
    required this.name,
    this.modelNumber = '',
    this.hourlyRate = 0,
    this.totalHoursRun = 0,
    this.status = 'Active',
  });

  factory Machinery.fromJson(Map<String, dynamic> json) {
    return Machinery(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      modelNumber: json['model_number']?.toString() ?? '',
      hourlyRate: (json['hourly_rate'] is num)
          ? (json['hourly_rate'] as num).toDouble()
          : double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0,
      totalHoursRun: (json['total_hours_run'] is num)
          ? (json['total_hours_run'] as num).toDouble()
          : double.tryParse(json['total_hours_run']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'model_number': modelNumber,
      'hourly_rate': hourlyRate,
      'status': status,
    };
  }
}

class MachineryLog {
  final int id;
  final int machineryId;
  final String date;
  final double hoursRun;
  final double fuelUsed;
  final int operatorId;
  final String notes;

  MachineryLog({
    this.id = 0,
    required this.machineryId,
    required this.date,
    this.hoursRun = 0,
    this.fuelUsed = 0,
    this.operatorId = 0,
    this.notes = '',
  });

  factory MachineryLog.fromJson(Map<String, dynamic> json) {
    return MachineryLog(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      machineryId: json['machinery_id'] is int
          ? json['machinery_id']
          : int.tryParse(json['machinery_id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      hoursRun: (json['hours_run'] is num)
          ? (json['hours_run'] as num).toDouble()
          : double.tryParse(json['hours_run']?.toString() ?? '0') ?? 0,
      fuelUsed: (json['fuel_used'] is num)
          ? (json['fuel_used'] as num).toDouble()
          : double.tryParse(json['fuel_used']?.toString() ?? '0') ?? 0,
      operatorId: json['operator_id'] is int
          ? json['operator_id']
          : int.tryParse(json['operator_id']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString() ?? '',
    );
  }
}
