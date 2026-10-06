class InventoryItem {
  final int id;
  final int tenantId;
  final String itemName;
  final String sku;
  final String barcode;
  final String category;
  final String unit;
  final double quantity;
  final double safetyStock;

  InventoryItem({
    this.id = 0,
    this.tenantId = 0,
    required this.itemName,
    this.sku = '',
    this.barcode = '',
    this.category = '',
    this.unit = '',
    this.quantity = 0,
    this.safetyStock = 0,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      itemName: json['item_name']?.toString() ?? json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      safetyStock: (json['safety_stock'] is num)
          ? (json['safety_stock'] as num).toDouble()
          : double.tryParse(json['safety_stock']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'quantity': quantity,
      'safety_stock': safetyStock,
    };
  }
}

class MaterialTransaction {
  final int id;
  final int inventoryItemId;
  final String type;
  final double quantity;
  final String reference;
  final String notes;
  final String transactionDate;

  MaterialTransaction({
    this.id = 0,
    required this.inventoryItemId,
    required this.type,
    required this.quantity,
    this.reference = '',
    this.notes = '',
    this.transactionDate = '',
  });

  factory MaterialTransaction.fromJson(Map<String, dynamic> json) {
    return MaterialTransaction(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      inventoryItemId: json['inventory_item_id'] is int
          ? json['inventory_item_id']
          : int.tryParse(json['inventory_item_id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      reference: json['reference']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      transactionDate: json['transaction_date']?.toString() ?? '',
    );
  }
}
