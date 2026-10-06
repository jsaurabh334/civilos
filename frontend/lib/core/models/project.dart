class Project {
  final int id;
  final String name;
  final String description;
  final String location;
  final String projectType;
  final String tenderNo;
  final String tenderDetails;
  final String status;
  final double budget;
  final int tenantId;
  final List<BOQItem> boqItems;
  final String createdAt;
  final String updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    this.location = '',
    this.projectType = 'Private',
    this.tenderNo = '',
    this.tenderDetails = '',
    this.status = 'Active',
    this.budget = 0,
    this.tenantId = 0,
    this.boqItems = const [],
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      projectType: json['project_type']?.toString() ?? 'Private',
      tenderNo: json['tender_no']?.toString() ?? '',
      tenderDetails: json['tender_details']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      budget: (json['budget'] is num) ? (json['budget'] as num).toDouble() : double.tryParse(json['budget']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      boqItems: (json['boq_items'] as List<dynamic>?)
              ?.map((e) => BOQItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at']?.toString() ?? json['CreatedAt']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? json['UpdatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'project_type': projectType,
      'tender_no': tenderNo,
      'tender_details': tenderDetails,
      'status': status,
      'budget': budget,
      'boq_items': boqItems.map((e) => e.toJson()).toList(),
    };
  }
}

class BOQItem {
  final int id;
  final int projectId;
  final String description;
  final String unit;
  final double plannedQuantity;
  final double rate;

  BOQItem({
    this.id = 0,
    this.projectId = 0,
    required this.description,
    this.unit = 'Cum',
    this.plannedQuantity = 0,
    this.rate = 0,
  });

  factory BOQItem.fromJson(Map<String, dynamic> json) {
    return BOQItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      projectId: json['project_id'] is int ? json['project_id'] : int.tryParse(json['project_id']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Cum',
      plannedQuantity: (json['planned_quantity'] is num)
          ? (json['planned_quantity'] as num).toDouble()
          : double.tryParse(json['planned_quantity']?.toString() ?? '0') ?? 0,
      rate: (json['rate'] is num)
          ? (json['rate'] as num).toDouble()
          : double.tryParse(json['rate']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'unit': unit,
      'planned_quantity': plannedQuantity,
      'rate': rate,
    };
  }
}
