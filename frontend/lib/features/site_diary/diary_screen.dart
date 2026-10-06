import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme.dart';
import '../../core/models/diary.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../core/refresh_wrapper.dart';
import '../../core/utils/geofence_service.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const DiaryScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  List<DiaryEntry> _diaries = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedProjectId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaries({bool forceRefresh = false}) async {
    if (_selectedProjectId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get(
        '/projects/$_selectedProjectId/diaries',
        forceRefresh: forceRefresh,
      );
      final list = response is List ? response : [];
      setState(() {
        _diaries = list.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showCreateDiaryDialog() {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first')),
      );
      return;
    }

    final dateController = TextEditingController(
      text: DateTime.now().toString().substring(0, 10),
    );
    final weatherController = TextEditingController();
    final workController = TextEditingController();
    int laborStrength = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Create Daily Diary Entry',
            style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weatherController,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Weather',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Labor Strength',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary),
                  ),
                  onChanged: (v) => laborStrength = int.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: workController,
                  maxLines: 3,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Completed Work',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dateController.text.isEmpty) return;
                  final scaffold = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  try {
                    // Geofencing Check
                    final projects = ref.read(projectProvider).projects;
                    final proj = projects.firstWhere((p) => p['id'] == _selectedProjectId, orElse: () => {});
                    if (proj.isNotEmpty) {
                      final double? lat = proj['latitude'] != null ? double.tryParse(proj['latitude'].toString()) : null;
                      final double? lng = proj['longitude'] != null ? double.tryParse(proj['longitude'].toString()) : null;
                      
                      if (lat != null && lng != null && lat != 0 && lng != 0) {
                        try {
                          final isWithin = await GeofenceService.isWithinGeofence(targetLat: lat, targetLng: lng);
                          if (!isWithin) {
                            if (scaffold.mounted) {
                              scaffold.showSnackBar(const SnackBar(
                                content: Text('Geofence error: You are not within the 500m radius of the site.'),
                                backgroundColor: CivilTheme.error,
                              ));
                            }
                            return;
                          }
                        } catch (geoErr) {
                           if (scaffold.mounted) {
                              scaffold.showSnackBar(SnackBar(
                                content: Text('Geofence check failed: ${geoErr.toString()}'),
                                backgroundColor: CivilTheme.error,
                              ));
                            }
                            return;
                        }
                      }
                    }

                    await ref.read(projectProvider.notifier).submitDiary(
                    _selectedProjectId!,
                    dateController.text.trim(),
                    weatherController.text.trim(),
                    laborStrength,
                    workController.text.trim(),
                  );
                  if (navigator.mounted) navigator.pop();
                  await _loadDiaries(forceRefresh: true);
                  if (scaffold.mounted) {
                    scaffold.showSnackBar(
                      const SnackBar(content: Text('Diary entry created successfully'),
                        backgroundColor: CivilTheme.secondary),
                    );
                  }
                } catch (e) {
                  if (scaffold.mounted) {
                    scaffold.showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: CivilTheme.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDiary(int diaryId) async {
    try {
      await ref.read(projectProvider.notifier).approveDiary(diaryId);
      await _loadDiaries(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary approved successfully'),
            backgroundColor: CivilTheme.secondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: CivilTheme.error),
        );
      }
    }
  }

  void _showDeleteDiary(int diaryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CivilTheme.surface,
        title: const Text('Delete Diary Entry',
          style: TextStyle(color: CivilTheme.textPrimary)),
        content: const Text('Are you sure? This action cannot be undone.',
          style: TextStyle(color: CivilTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(projectProvider.notifier).deleteDiary(_selectedProjectId!, diaryId);
      await _loadDiaries(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary deleted'),
            backgroundColor: CivilTheme.secondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: CivilTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proj = ref.watch(projectProvider);
    final projects = proj.projects;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final filteredDiaries = _searchQuery.isEmpty
        ? _diaries
        : _diaries.where((d) =>
            d.date.contains(_searchQuery) ||
            d.weather.toLowerCase().contains(_searchQuery) ||
            d.completedWork.toLowerCase().contains(_searchQuery)
          ).toList();

    final content = Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF222B38), Color(0xFF161F2E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      if (!isDesktop && !widget.isEmbedded)
                        IconButton(
                          icon: const Icon(Icons.menu, color: CivilTheme.textSecondary),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      const Text('Site Diary',
                        style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (projects.isNotEmpty)
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedProjectId,
                            dropdownColor: CivilTheme.surface,
                            style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: 'Select Project',
                              hintStyle: const TextStyle(color: CivilTheme.textSecondary, fontSize: 13),
                              filled: true,
                              fillColor: CivilTheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: CivilTheme.border),
                              ),
                            ),
                            items: projects.map((p) => DropdownMenuItem(
                              value: p['id'] as int,
                              child: Text(p['name']?.toString() ?? 'Unnamed', overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              setState(() => _selectedProjectId = val);
                              _loadDiaries();
                            },
                          ),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _selectedProjectId != null ? _showCreateDiaryDialog : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Log'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CivilTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedProjectId != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                        style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search diary entries...',
                          hintStyle: const TextStyle(color: CivilTheme.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: CivilTheme.textSecondary, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: CivilTheme.textSecondary, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: CivilTheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: CivilTheme.border),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Expanded(
                  child: _buildContent(projects, isDesktop, filteredDiaries),
                ),
              ],
            ),
          ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: content,
    );
  }

  Widget _buildContent(List<dynamic> projects, bool isDesktop, List<DiaryEntry> filteredDiaries) {
    if (_selectedProjectId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: CivilTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Select a project to view diary entries',
              style: TextStyle(color: CivilTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Choose a project from the dropdown above',
              style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: SkeletonList(count: 3, itemHeight: 120),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: CivilTheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: CivilTheme.error, fontSize: 14),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDiaries(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredDiaries.isEmpty) {
      return EmptyStateView(
        icon: Icons.book_outlined,
        title: _searchQuery.isNotEmpty ? 'No matching entries' : 'No diary entries yet',
        description: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Create your first diary entry for this project',
        actionLabel: _searchQuery.isNotEmpty ? null : 'Create Entry',
        onAction: _searchQuery.isNotEmpty ? null : _showCreateDiaryDialog,
      );
    }

    return RefreshWrapper(
      onRefresh: () => _loadDiaries(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: filteredDiaries.length,
        itemBuilder: (context, index) {
          final diary = filteredDiaries[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CivilTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CivilTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CivilTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(diary.date,
                        style: const TextStyle(color: CivilTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    if (diary.weather.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            diary.weather.toLowerCase().contains('rain') ? Icons.water_drop :
                            diary.weather.toLowerCase().contains('cloud') ? Icons.cloud :
                            diary.weather.toLowerCase().contains('sun') ? Icons.wb_sunny :
                            Icons.wb_cloudy,
                            size: 14, color: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(diary.weather,
                            style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    const Spacer(),
                    if (diary.approved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CivilTheme.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('APPROVED',
                          style: TextStyle(color: CivilTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('PENDING',
                          style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (diary.completedWork.isNotEmpty) ...[
                  Text(diary.completedWork,
                    style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 13)),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: CivilTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('${diary.laborStrength} workers',
                      style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
                    if (diary.siteEngineerName.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, size: 14, color: CivilTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(diary.siteEngineerName,
                        style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
                    ],
                    const Spacer(),
                    if (!diary.approved)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, size: 18, color: CivilTheme.secondary),
                            onPressed: () => _showApproveDiary(diary.id),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: CivilTheme.error),
                            onPressed: () => _showDeleteDiary(diary.id),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
