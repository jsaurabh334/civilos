import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/work_order_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';
import '../../core/empty_state.dart';

class WorkOrdersScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const WorkOrdersScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends ConsumerState<WorkOrdersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Open', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workOrderProvider.notifier).fetchWorkOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredOrders(List<dynamic> orders) {
    var filtered = orders.cast<Map<String, dynamic>>();
    if (_selectedStatus != 'All') {
      final statusMap = {
        'Open': 'open',
        'In Progress': 'in_progress',
        'Completed': 'completed'
      };
      filtered = filtered
          .where((wo) => (wo['status']?.toString().toLowerCase() ==
              statusMap[_selectedStatus]))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((wo) =>
              (wo['title']?.toString().toLowerCase().contains(query) ??
                  false) ||
              (wo['description']?.toString().toLowerCase().contains(query) ??
                  false))
          .toList();
    }
    return filtered;
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.lightBlueAccent;
      case 'medium':
        return Colors.amber;
      case 'high':
        return Colors.orangeAccent;
      case 'critical':
        return Colors.redAccent;
      default:
        return CivilTheme.textSecondary;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.amber;
      case 'inprogress':
      case 'in_progress':
        return Colors.blueAccent;
      case 'completed':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return CivilTheme.textSecondary;
    }
  }

  void _showCreateDialog() {
    showDialog(
        context: context,
        builder: (context) => _CreateWorkOrderDialog(ref: ref));
  }

  Future<void> _updateStatus(Map<String, dynamic> wo) async {
    final currentStatus = (wo['status'] as String?)?.toLowerCase() ?? 'open';
    final statusFlow = ['open', 'in_progress', 'completed', 'cancelled'];
    final currentIndex = statusFlow.indexOf(currentStatus);
    if (currentIndex < 0) return;
    if (currentStatus == 'completed' || currentStatus == 'cancelled') return;

    final nextStatus = statusFlow[currentIndex + 1];
    final confirm = await showConfirmDialog(context,
        title: 'Update Status', message: 'Change status to $nextStatus?');
    if (!confirm) return;

    try {
      await ref
          .read(workOrderProvider.notifier)
          .updateWorkOrderStatus(wo['id'] as int, nextStatus);
      if (mounted) showToast(context, 'Status updated to $nextStatus');
    } catch (e) {
      if (mounted) showToast(context, 'Failed to update: $e', isError: true);
    }
  }

  Future<void> _deleteWorkOrder(Map<String, dynamic> wo) async {
    final confirm = await showConfirmDialog(context,
        title: 'Delete Work Order',
        message: 'Are you sure you want to delete this work order?');
    if (!confirm) return;

    try {
      await ref
          .read(workOrderProvider.notifier)
          .deleteWorkOrder(wo['id'] as int);
      if (mounted) showToast(context, 'Work order deleted successfully');
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed to delete work order: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final woProv = ref.watch(workOrderProvider);
    final orders = _filteredOrders(woProv.workOrders);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return Stack(
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
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 600 : 1000),
                child: Column(
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                if (!widget.isEmbedded)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: CivilTheme.surface.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: GestureDetector(
                                      onTap: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                      child: const Icon(Icons.menu,
                                          color: CivilTheme.textSecondary,
                                          size: 20),
                                    ),
                                  ),
                                  if (!widget.isEmbedded) const Spacer(),
                                const Text('Work Orders',
                                    style: TextStyle(
                                        color: CivilTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _showCreateDialog,
                                  icon: const Icon(Icons.add,
                                      color: CivilTheme.background, size: 18),
                                  label: const Text('Create WO',
                                      style: TextStyle(
                                          color: CivilTheme.background)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CivilTheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color:
                                          CivilTheme.surface.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: CivilTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.search,
                                            color: CivilTheme.textSecondary,
                                            size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            style: const TextStyle(
                                                color: CivilTheme.textPrimary,
                                                fontSize: 14),
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Search work orders...',
                                              hintStyle: TextStyle(
                                                  color: CivilTheme
                                                      .textSecondary),
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                            onChanged: (v) => setState(
                                                () => _searchQuery = v),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _statuses.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final status = _statuses[index];
                                  final isSelected =
                                      status == _selectedStatus;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedStatus = status),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? CivilTheme.primary
                                            : CivilTheme.surface
                                                .withValues(alpha: 0.6),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: isSelected
                                                ? CivilTheme.primary
                                                : CivilTheme.border),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: isSelected
                                              ? CivilTheme.background
                                              : CivilTheme.textSecondary,
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: woProv.isLoading && orders.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : orders.isEmpty
                              ? EmptyState(
                                  icon: Icons.assignment,
                                  title: 'No work orders',
                                  actionLabel: 'Create Work Order',
                                  onAction: _showCreateDialog,
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: orders.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final wo = orders[index];
                                    return _buildWorkOrderCard(wo);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: content,
    );
  }

  Widget _buildWorkOrderCard(Map<String, dynamic> wo) {
    final status = (wo['status'] as String?) ?? 'open';
    final priority = (wo['priority'] as String?) ?? 'medium';
    final statusColor = _statusColor(status);
    final priorityColor = _priorityColor(priority);

    return Container(
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: statusColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: -5)
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  wo['title'] ?? 'Untitled',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: CivilTheme.textPrimary),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: priorityColor, size: 10),
                        const SizedBox(width: 4),
                        Text(priority.toUpperCase(),
                            style: TextStyle(
                                color: priorityColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (wo['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              wo['description'],
              style: const TextStyle(
                  color: CivilTheme.textSecondary, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: CivilTheme.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              if (wo['assigned_to'] != null)
                _infoChip('Assigned To', wo['assigned_to']),
              const Spacer(),
              if (wo['due_date'] != null)
                Row(
                  children: [
                    const Icon(Icons.event,
                        color: CivilTheme.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(wo['due_date'],
                        style: const TextStyle(
                            color: CivilTheme.textSecondary, fontSize: 12)),
                  ],
                ),
            ],
          ),
          if (status != 'completed' && status != 'cancelled')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _updateStatus(wo),
                    icon: Icon(Icons.check_circle_outline,
                        color: statusColor, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _deleteWorkOrder(wo),
                    icon: const Icon(Icons.delete_outline,
                        color: CivilTheme.error, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Row(
      children: [
        Text('$label: ',
            style:
                const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: CivilTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ],
    );
  }
}

class _CreateWorkOrderDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CreateWorkOrderDialog({required this.ref});
  @override
  ConsumerState<_CreateWorkOrderDialog> createState() =>
      _CreateWorkOrderDialogState();
}

class _CreateWorkOrderDialogState
    extends ConsumerState<_CreateWorkOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _dueDateController = TextEditingController();
  String _priority = 'medium';
  int? _selectedProjectId;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await widget.ref.read(workOrderProvider.notifier).createWorkOrder({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'project_id': _selectedProjectId,
        'assigned_to': _assigneeController.text.trim(),
        'due_date': _dueDateController.text.trim(),
        'priority': _priority,
      });
      if (mounted) {
        Navigator.pop(context);
        showToast(context, 'Work order created successfully');
      }
    } catch (e) {
      if (mounted) showToast(context, 'Failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CivilTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create Work Order',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _assigneeController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Assigned To',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dueDateController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Due Date (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    dropdownColor: CivilTheme.surface,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Priority',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    items: ['low', 'medium', 'high', 'critical']
                        .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p[0].toUpperCase() + p.substring(1))))
                        .toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: CivilTheme.textSecondary))),
                      const SizedBox(width: 16),
                      ElevatedButton(
                          onPressed: _submit, child: const Text('Create')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
