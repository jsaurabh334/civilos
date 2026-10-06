import 'dart:io';

void main() {
  final screens = [
    {'name': 'DocumentsScreen', 'file': 'documents_screen.dart', 'dir': 'documents'},
    {'name': 'DrawingsScreen', 'file': 'drawings_screen.dart', 'dir': 'drawings'},
    {'name': 'InspectionsScreen', 'file': 'inspections_screen.dart', 'dir': 'inspections'},
    {'name': 'ChecklistsScreen', 'file': 'checklists_screen.dart', 'dir': 'checklists'},
    {'name': 'PhotosScreen', 'file': 'photos_screen.dart', 'dir': 'photos'},
    {'name': 'VehiclesScreen', 'file': 'vehicles_screen.dart', 'dir': 'vehicles'},
    {'name': 'VendorsScreen', 'file': 'vendors_screen.dart', 'dir': 'vendors'},
    {'name': 'PaymentsScreen', 'file': 'payments_screen.dart', 'dir': 'payments'},
    {'name': 'ReportsScreen', 'file': 'reports_screen.dart', 'dir': 'reports'},
  ];

  for (var screen in screens) {
    final dir = Directory('lib/features/${screen['dir']}');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    
    final file = File('lib/features/${screen['dir']}/${screen['file']}');
    file.writeAsStringSync('''
import 'package:flutter/material.dart';
import '../../shared/widgets/civil_scaffold.dart';
import '../../core/theme.dart';

class ${screen['name']} extends StatelessWidget {
  const ${screen['name']}({super.key});

  @override
  Widget build(BuildContext context) {
    return CivilScaffold(
      title: '${screen['name'].toString().replaceAll('Screen', '')}',
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: CivilTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Under Construction',
              style: TextStyle(color: CivilTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This module will be available soon.',
              style: TextStyle(color: CivilTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
''');
  }
  // ignore: avoid_print
  print('Screens generated successfully.');
}
