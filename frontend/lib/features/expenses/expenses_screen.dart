import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';
import '../../core/download_helper.dart';
import '../../core/components/civil_data_table.dart';


class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();
  final String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fuel',
    'Labour',
    'Material',
    'Equipment',
    'Misc'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseProvider.notifier).fetchExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredExpenses(List<dynamic> expenses) {
    var filtered = expenses.cast<Map<String, dynamic>>();
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((e) =>
              (e['category']?.toString() ?? '').toLowerCase() ==
              _selectedCategory.toLowerCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((e) =>
              (e['category']?.toString().toLowerCase().contains(query) ??
                  false) ||
              (e['description']?.toString().toLowerCase().contains(query) ??
                  false))
          .toList();
    }
    return filtered;
  }

  double _totalExpenses(List<dynamic> expenses) {
    double total = 0;
    for (final e in expenses) {
      total += (e['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  void _showCreateDialog() {
    showDialog(
        context: context, builder: (context) => const _CreateExpenseDialog());
  }

  void _editExpense(Map<String, dynamic> expense) {
    showDialog(
        context: context,
        builder: (context) => _EditExpenseDialog(expense: expense));
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete Expense',
      message: 'Are you sure you want to delete this expense?',
    );
    if (!confirm) return;
    try {
      await ref
          .read(expenseProvider.notifier)
          .deleteExpense(expense['id'] as int);
      if (mounted) showToast(context, 'Expense deleted successfully');
    } catch (e) {
      if (mounted) showToast(context, 'Failed to delete: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exp = ref.watch(expenseProvider);
    final expenses = _filteredExpenses(exp.expenses);
    final total = _totalExpenses(exp.expenses);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: Stack(
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header
                  Row(
                    children: [
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(Icons.menu, color: CivilTheme.textSecondary),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      const Text('Finance Command Center',
                          style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.download, color: CivilTheme.secondary),
                        tooltip: 'Export CSV',
                        onPressed: () => downloadExport('/export/expenses/csv', 'expenses.csv'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CivilTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // KPI Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Monthly Spend', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Outstanding Approvals', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('4 Pending', style: TextStyle(color: Colors.orange, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash Burn Rate', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('- 12% vs last month', style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                            backgroundColor: CivilTheme.surface,
                            selectedColor: CivilTheme.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: isSelected ? CivilTheme.primary : CivilTheme.textSecondary),
                            side: BorderSide(color: isSelected ? CivilTheme.primary : CivilTheme.border),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Table
                  Expanded(
                    child: exp.isLoading && expenses.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : expenses.isEmpty
                            ? const Center(child: Text('No expenses found.', style: TextStyle(color: CivilTheme.textSecondary)))
                            : CivilDataTable(
                                columns: const ['Date', 'Category', 'Amount', 'Description', 'Actions'],
                                rows: expenses.map((e) {
                                  return <Widget>[
                                    Text(e['expense_date'] ?? 'N/A', style: const TextStyle(color: CivilTheme.textPrimary)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(e['category'] ?? 'Misc', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
                                    ),
                                    Text('\$${(e['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    Text(e['description'] ?? '', style: const TextStyle(color: CivilTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 16, color: CivilTheme.primary),
                                          onPressed: () => _editExpense(e),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 16, color: CivilTheme.error),
                                          onPressed: () => _deleteExpense(e),
                                        ),
                                      ],
                                    ),
                                  ];
                                }).toList(),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _CreateExpenseDialog extends ConsumerStatefulWidget {
  const _CreateExpenseDialog();
  @override
  ConsumerState<_CreateExpenseDialog> createState() =>
      _CreateExpenseDialogState();
}

class _CreateExpenseDialogState extends ConsumerState<_CreateExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  String _category = 'Fuel';
  int? _selectedProjectId;
  final List<String> _categories = [
    'Fuel',
    'Labour',
    'Material',
    'Equipment',
    'Misc'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(expenseProvider.notifier).createExpense({
        'category': _category,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'description': _descController.text.trim(),
        'expense_date': _dateController.text.trim(),
        'project_id': _selectedProjectId,
      });
      if (mounted) {
        Navigator.pop(context);
        showToast(context, 'Expense added successfully');
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
                  const Text('Add Expense',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    dropdownColor: CivilTheme.surface,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Amount',
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
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
                          onPressed: _submit, child: const Text('Save')),
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

class _EditExpenseDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> expense;
  const _EditExpenseDialog({required this.expense});
  @override
  ConsumerState<_EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<_EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  late String _category;
  int? _selectedProjectId;
  final List<String> _categories = [
    'Fuel',
    'Labour',
    'Material',
    'Equipment',
    'Misc'
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.expense['category'] ?? 'Fuel';
    _amountController.text = widget.expense['amount']?.toString() ?? '';
    _descController.text = widget.expense['description'] ?? '';
    _dateController.text = widget.expense['expense_date'] ?? '';
    _selectedProjectId = widget.expense['project_id'] as int?;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(expenseProvider.notifier)
          .updateExpense(widget.expense['id'] as int, {
        'category': _category,
        'amount': double.tryParse(_amountController.text) ?? 0,
        'description': _descController.text.trim(),
        'expense_date': _dateController.text.trim(),
        'project_id': _selectedProjectId,
      });
      if (mounted) {
        Navigator.pop(context);
        showToast(context, 'Expense updated successfully');
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
                  const Text('Edit Expense',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    dropdownColor: CivilTheme.surface,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Amount',
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
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
                          onPressed: _submit, child: const Text('Update')),
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
