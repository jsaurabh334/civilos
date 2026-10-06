import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';

class VendorDirectoryScreen extends ConsumerStatefulWidget {
  const VendorDirectoryScreen({super.key});

  @override
  ConsumerState<VendorDirectoryScreen> createState() => _VendorDirectoryScreenState();
}

class _VendorDirectoryScreenState extends ConsumerState<VendorDirectoryScreen> {
  List<dynamic> _vendors = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/vendors');
      
      if (mounted) {
        setState(() {
          _vendors = response ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateVendorRelation(int vendorId, bool isFavorite, bool isBlocked) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/my-vendors/$vendorId', {
        'is_favorite': isFavorite,
        'is_blocked': isBlocked,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor relation updated.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Directory'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_vendors.isEmpty) {
      return const Center(child: Text('No verified vendors available on the platform yet.'));
    }

    return ListView.builder(
      itemCount: _vendors.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final vendor = _vendors[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.store)),
            title: Text(vendor['name'] ?? 'Unknown'),
            subtitle: Text(vendor['email'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () => _updateVendorRelation(vendor['id'], true, false),
                  tooltip: 'Favorite',
                ),
                IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () => _updateVendorRelation(vendor['id'], false, true),
                  tooltip: 'Block',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
