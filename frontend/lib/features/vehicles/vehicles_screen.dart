import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/civil_scaffold.dart';
import '../../core/theme.dart';
import '../../core/providers/machinery_provider.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(machineryProvider.notifier).fetchMachinery());
  }

  void _showAddVehicleDialog() {
    final nameController = TextEditingController();
    final modelController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CivilTheme.surface,
        title: const Text('Add Vehicle', style: TextStyle(color: CivilTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Vehicle Name (e.g. Dump Truck)', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              style: const TextStyle(color: CivilTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'Registration/Model No.', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              style: const TextStyle(color: CivilTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(labelText: 'Hourly Rate (₹)', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              style: const TextStyle(color: CivilTheme.textPrimary),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final rate = double.tryParse(rateController.text) ?? 0.0;
                await ref.read(machineryProvider.notifier).createMachinery(nameController.text, modelController.text, rate);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CivilTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(machineryProvider);
    // In a real app we'd filter by type, here we just show all "machinery" as vehicles since they're closely related.
    final vehicles = state.machinery; 

    return CivilScaffold(
      title: 'Fleet Command Center',
      actions: [
        ElevatedButton.icon(
          onPressed: _showAddVehicleDialog,
          icon: const Icon(Icons.directions_car),
          label: const Text('Add Vehicle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CivilTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
      ],
      body: state.isLoading && vehicles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: CivilTheme.error),
                  const SizedBox(height: 16),
                  Text('Error: ${state.error}', style: const TextStyle(color: CivilTheme.error)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(machineryProvider.notifier).fetchMachinery(),
                    style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildStatsCards(vehicles),
                const SizedBox(height: 32),
                _buildVehiclesTable(vehicles),
              ],
            ),
    );
  }

  Widget _buildStatsCards(List<dynamic> vehicles) {
    int active = vehicles.where((v) => v['status'] == 'Active').length;
    int maintenance = vehicles.where((v) => v['status'] == 'Maintenance').length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Vehicles', vehicles.length.toString(), Colors.white)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Active', active.toString(), Colors.greenAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('In Maintenance', maintenance.toString(), Colors.orangeAccent)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: valueColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVehiclesTable(List<dynamic> vehicles) {
    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping, size: 64, color: CivilTheme.textSecondary),
            const SizedBox(height: 16),
            const Text('No vehicles found.', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Add a vehicle to get started.', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivilTheme.border),
      ),
      child: DataTable(
        headingTextStyle: const TextStyle(color: CivilTheme.textSecondary, fontWeight: FontWeight.w600),
        dataTextStyle: const TextStyle(color: CivilTheme.textPrimary),
        columns: const [
          DataColumn(label: Text('Vehicle Name')),
          DataColumn(label: Text('Reg / Model')),
          DataColumn(label: Text('Hourly Rate')),
          DataColumn(label: Text('Status')),
        ],
        rows: vehicles.map((v) {
          final isMaintenance = v['status'] == 'Maintenance';
          return DataRow(
            cells: [
              DataCell(Text(v['name'] ?? 'Unknown')),
              DataCell(Text(v['model_number'] ?? '-')),
              DataCell(Text('₹${v['hourly_rate'] ?? 0.0}')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMaintenance ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isMaintenance ? Colors.orangeAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    v['status'] ?? 'Active',
                    style: TextStyle(
                      color: isMaintenance ? Colors.orangeAccent : Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
