class Inspection {
  final int id;
  final int tenantId;
  final int projectId;
  final String title;
  final String description;
  final int inspectorId;
  final String date;
  final String status;

  Inspection({
    this.id = 0,
    this.tenantId = 0,
    this.projectId = 0,
    required this.title,
    this.description = '',
    this.inspectorId = 0,
    this.date = '',
    this.status = 'Pending',
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      projectId: json['project_id'] is int ? json['project_id'] : int.tryParse(json['project_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      inspectorId: json['inspector_id'] is int
          ? json['inspector_id']
          : int.tryParse(json['inspector_id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'project_id': projectId,
      'inspector_id': inspectorId,
      'date': date,
      'status': status,
    };
  }
}

class Checklist {
  final int id;
  final int tenantId;
  final int projectId;
  final String title;
  final String category;
  final bool completed;

  Checklist({
    this.id = 0,
    this.tenantId = 0,
    this.projectId = 0,
    required this.title,
    this.category = '',
    this.completed = false,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      projectId: json['project_id'] is int ? json['project_id'] : int.tryParse(json['project_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'project_id': projectId,
      'completed': completed,
    };
  }
}
