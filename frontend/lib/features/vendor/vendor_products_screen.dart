import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';

class VendorProductsScreen extends ConsumerStatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  ConsumerState<VendorProductsScreen> createState() =>
      _VendorProductsScreenState();
}

class _VendorProductsScreenState extends ConsumerState<VendorProductsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get('/marketplace');
      final list = response is List
          ? response.cast<Map<String, dynamic>>()
          : response is Map && response['data'] is List
              ? (response['data'] as List).cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
      setState(() => _products = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    String category = 'Cement';
    bool isSubmitting = false;

    final List<String> categories = [
      'Cement', 'Steel', 'Bricks', 'Sand', 'Aggregate', 'Wood', 'Electrical', 'Plumbing', 'Other'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: CivilTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Add Product',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CivilTheme.textPrimary)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        dropdownColor: CivilTheme.surface,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => category = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: CivilTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Price (₹)',
                                labelStyle: TextStyle(
                                    color: CivilTheme.textSecondary),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: unitController,
                              style: const TextStyle(
                                  color: CivilTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                hintText: 'e.g. Kg, Bag',
                                labelStyle: TextStyle(
                                    color: CivilTheme.textSecondary),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: CivilTheme.textSecondary)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDialogState(() => isSubmitting = true);
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .post('/marketplace', {
                                        'name': nameController.text.trim(),
                                        'category': category,
                                        'price': double.tryParse(
                                                priceController.text) ??
                                            0,
                                        'unit': unitController.text.trim(),
                                        'stock': int.tryParse(
                                                stockController.text) ??
                                            0,
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        showToast(context,
                                            'Product added successfully');
                                        _fetchData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        showToast(context,
                                            'Failed: $e',
                                            isError: true);
                                      }
                                    } finally {
                                      if (mounted) {
                                        setDialogState(
                                            () => isSubmitting = false);
                                      }
                                    }
                                  },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> product) {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: product['name']?.toString() ?? '');
    final priceController =
        TextEditingController(text: product['price']?.toString() ?? '');
    final stockController =
        TextEditingController(text: product['stock']?.toString() ?? '');
    final unitController =
        TextEditingController(text: product['unit']?.toString() ?? '');
    String category = product['category']?.toString() ?? 'Cement';
    bool isSubmitting = false;
    final productId = product['id'];

    final List<String> categories = [
      'Cement', 'Steel', 'Bricks', 'Sand', 'Aggregate', 'Wood', 'Electrical', 'Plumbing', 'Other'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: CivilTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Edit Product',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CivilTheme.textPrimary)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        dropdownColor: CivilTheme.surface,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => category = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: CivilTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Price (₹)',
                                labelStyle: TextStyle(
                                    color: CivilTheme.textSecondary),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: unitController,
                              style: const TextStyle(
                                  color: CivilTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                hintText: 'e.g. Kg, Bag',
                                labelStyle: TextStyle(
                                    color: CivilTheme.textSecondary),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: CivilTheme.textSecondary)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDialogState(() => isSubmitting = true);
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .put('/marketplace/$productId', {
                                        'name': nameController.text.trim(),
                                        'category': category,
                                        'price': double.tryParse(
                                                priceController.text) ??
                                            0,
                                        'unit': unitController.text.trim(),
                                        'stock': int.tryParse(
                                                stockController.text) ??
                                            0,
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        showToast(context,
                                            'Product updated successfully');
                                        _fetchData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        showToast(context,
                                            'Failed: $e',
                                            isError: true);
                                      }
                                    } finally {
                                      if (mounted) {
                                        setDialogState(
                                            () => isSubmitting = false);
                                      }
                                    }
                                  },
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Catalog')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $_error',
                          style: const TextStyle(color: CivilTheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? const Center(child: Text("No products added yet."))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    CivilTheme.primary.withOpacity(0.1),
                                child: const Icon(Icons.inventory_2,
                                    color: CivilTheme.primary),
                              ),
                              title: Text(
                                  product['name']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      "Category: ${product['category'] ?? 'N/A'}"),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Price: ₹${(product['price'] ?? 0).toStringAsFixed(2)} per ${product['unit'] ?? 'unit'}"),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Stock: ${product['stock'] ?? 0} ${product['unit'] ?? ''}",
                                      style: const TextStyle(
                                          color: Colors.green)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () =>
                                    _showEditDialog(product),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CivilTheme.primary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
