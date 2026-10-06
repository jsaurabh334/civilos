class WorkOrder {
  final int id;
  final int tenantId;
  final int projectId;
  final String title;
  final String description;
  final String assignedTo;
  final String dueDate;
  final String priority;
  final String status;

  WorkOrder({
    this.id = 0,
    this.tenantId = 0,
    this.projectId = 0,
    required this.title,
    this.description = '',
    this.assignedTo = '',
    this.dueDate = '',
    this.priority = 'Medium',
    this.status = 'Open',
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      projectId: json['project_id'] is int ? json['project_id'] : int.tryParse(json['project_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      assignedTo: json['assigned_to']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'project_id': projectId,
      'assigned_to': assignedTo,
      'due_date': dueDate,
      'priority': priority,
      'status': status,
    };
  }
}
