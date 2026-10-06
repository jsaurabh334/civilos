import 'dart:convert';

class DiaryEntry {
  final int id;
  final int projectId;
  final int siteEngineerId;
  final String siteEngineerName;
  final String date;
  final String weather;
  final int laborStrength;
  final String completedWork;
  final List<String> imageUrls;
  final bool approved;
  final String createdAt;
  final String updatedAt;

  DiaryEntry({
    this.id = 0,
    this.projectId = 0,
    this.siteEngineerId = 0,
    this.siteEngineerName = '',
    required this.date,
    this.weather = '',
    this.laborStrength = 0,
    this.completedWork = '',
    this.imageUrls = const [],
    this.approved = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['image_urls'] != null) {
      final raw = json['image_urls'];
      if (raw is List) {
        images = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            images = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          images = [];
        }
      }
    }

    String engineerName = '';
    if (json['site_engineer'] is Map) {
      engineerName = json['site_engineer']['name']?.toString() ?? '';
    }

    return DiaryEntry(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      projectId: json['project_id'] is int ? json['project_id'] : int.tryParse(json['project_id']?.toString() ?? '0') ?? 0,
      siteEngineerId: json['site_engineer_id'] is int
          ? json['site_engineer_id']
          : int.tryParse(json['site_engineer_id']?.toString() ?? '0') ?? 0,
      siteEngineerName: engineerName,
      date: json['date']?.toString() ?? '',
      weather: json['weather']?.toString() ?? '',
      laborStrength: json['labor_strength'] is int
          ? json['labor_strength']
          : int.tryParse(json['labor_strength']?.toString() ?? '0') ?? 0,
      completedWork: json['completed_work']?.toString() ?? '',
      imageUrls: images,
      approved: json['approved'] == true,
      createdAt: json['created_at']?.toString() ?? json['CreatedAt']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? json['UpdatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weather': weather,
      'labor_strength': laborStrength,
      'completed_work': completedWork,
      'image_urls': imageUrls,
    };
  }
}
