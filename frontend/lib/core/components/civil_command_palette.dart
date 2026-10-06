import 'package:flutter/material.dart';
import '../theme.dart';

class CivilCommandPalette extends StatefulWidget {
  const CivilCommandPalette({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const CivilCommandPalette(),
    );
  }

  @override
  State<CivilCommandPalette> createState() => _CivilCommandPaletteState();
}

class _CivilCommandPaletteState extends State<CivilCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 600,
        height: 400,
        decoration: BoxDecoration(
          color: CivilTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CivilTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.search, color: CivilTheme.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                          color: CivilTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Search projects, commands, or settings...',
                        hintStyle: TextStyle(
                            color: CivilTheme.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      onSubmitted: (_) => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CivilTheme.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: CivilTheme.border),
                    ),
                    child: const Text('ESC', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(color: CivilTheme.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSectionHeader('QUICK ACTIONS'),
                  _buildCommandItem(Icons.add, 'Create New Project', () {}),
                  _buildCommandItem(Icons.receipt, 'Raise Purchase Order', () {}),
                  _buildCommandItem(Icons.group_add, 'Add Labor Attendance', () {}),
                  const SizedBox(height: 8),
                  _buildSectionHeader('RECENT NAVIGATION'),
                  _buildCommandItem(Icons.foundation, 'Project: Alpha Towers', () {}),
                  _buildCommandItem(Icons.fire_truck, 'Fleet Machinery', () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: CivilTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCommandItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: CivilTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
