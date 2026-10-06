import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth_provider.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/theme.dart';
import 'package:frontend/core/providers/notification_provider.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/dashboard/dashboard_screen.dart';
import 'package:frontend/features/projects/project_screen.dart';
import 'package:frontend/features/site_diary/diary_screen.dart';
import 'package:frontend/features/marketplace/marketplace_screen.dart';
import 'package:frontend/features/tenders/tenders_screen.dart';
import 'package:frontend/features/billing/billing_screen.dart';
import 'package:frontend/features/inventory/inventory_screen.dart';
import 'package:frontend/features/machinery/machinery_screen.dart';
import 'package:frontend/features/labor/labor_screen.dart';
import 'package:frontend/features/expenses/expenses_screen.dart';
import 'package:frontend/features/purchase_orders/purchase_orders_screen.dart';
import 'package:frontend/features/work_orders/work_orders_screen.dart';
import 'package:frontend/features/chat/chat_screen.dart';
import 'package:frontend/features/notifications/notifications_screen.dart';
import 'package:frontend/features/settings/settings_screen.dart';
import 'package:frontend/features/admin/admin_screen.dart';
import 'package:frontend/features/admin/user_management_screen.dart';

final String _screenshotDir = '${Directory.systemTemp.path}/civilos_screenshots';

// ───── Mock API Client ─────

class MockApiClient extends ApiClient {
  final Map<String, dynamic> _responses;

  MockApiClient(this._responses) {
    setToken('mock-token');
  }

  @override
  Future<dynamic> get(String path,
      {Map<String, String>? params, bool forceRefresh = false}) async {
    await Future.delayed(const Duration(milliseconds: 30));
    if (path.contains('?')) {
      final base = path.split('?').first;
      if (_responses.containsKey(base)) return _responses[base];
    }
    if (_responses.containsKey(path)) return _responses[path];
    return [];
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return {};
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return {};
  }

  @override
  Future<dynamic> delete(String path) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return {};
  }
}

// ───── Mock Auth ─────

AuthState mockAuthState() => AuthState(
      isLoading: false,
      currentUser: _mockUser,
      currentTenant: _mockUser['tenant'] as Map<String, dynamic>?,
      token: 'mock-token',
    );

class _MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => mockAuthState();
}

// ───── Mock Data ─────

final _mockUser = {
  'id': 1,
  'name': 'Test User',
  'email': 'test@civilos.com',
  'role': 'SuperAdmin',
  'phone': '+91-9876543210',
  'tenant_id': null,
  'tenant': {
    'id': 1,
    'name': 'Acme Construction',
    'slug': 'acme',
    'is_active': true,
    'feature_flags':
        '{"site_diary":true,"inventory":true,"marketplace":true,"tenders":true,"billing":true,"machinery":true,"labor":true,"expenses":true,"purchase_orders":true,"work_orders":true,"chat":true,"notifications":true}',
  },
};

final _mockProjects = [
  {
    'id': 1,
    'name': 'Metro Line Extension',
    'description': 'City Metro Line 3 expansion project - Phase 1',
    'location': 'Sector 62, Noida',
    'status': 'Active',
    'created_at': '2026-01-15T00:00:00Z',
    'boq_items': [
      {'id': 1, 'description': 'Excavation', 'unit': 'Cum', 'planned_quantity': 5000, 'rate': 120},
      {'id': 2, 'description': 'RCC M25', 'unit': 'Cum', 'planned_quantity': 1200, 'rate': 4500},
    ],
  },
];

final _mockDiaries = [
  {
    'id': 1,
    'project_id': 1,
    'date': '2026-06-26',
    'weather': 'Sunny',
    'labor_strength': 45,
    'completed_work': 'Excavation completed for section A-B. Steel reinforcement started.',
    'status': 'Submitted',
    'created_at': '2026-06-26T18:00:00Z',
  },
];

final _mockDashboardStats = {
  'active_projects': 1,
  'total_workers': 3,
  'workers_present_today': 2,
  'outstanding_receivables': 75000.0,
  'low_stock_items': 1,
  'active_machinery': 1,
  'monthly_expenses': 23500.0,
  'unpaid_payroll_count': 1,
};

final _mockListings = [
  {
    'id': 1,
    'category': 'RentMachinery',
    'title': 'Excavator JCB 3DX',
    'description': 'Available for rent with experienced operator',
    'quantity': 1,
    'price': 15000,
    'unit': 'Day',
    'status': 'Open',
    'posted_by': 'Acme Construction',
    'tenant_id': 1,
    'created_at': '2026-06-01T00:00:00Z',
  },
];

final _mockPartners = [
  {
    'id': 1,
    'company_name': 'BuildRight Suppliers',
    'contact_person': 'Rajesh Kumar',
    'phone': '+91-9876543211',
    'email': 'rajesh@buildright.com',
    'type': 'Supplier',
    'status': 'Active',
    'rating': 4.5,
  },
];

final _mockTenders = [
  {
    'id': 1,
    'title': 'Highway Widening Project',
    'description': '4-lane expansion of NH-24 from km 45 to km 78',
    'client_name': 'PWD Uttar Pradesh',
    'budget': 8500000,
    'closing_date': '2026-09-30T00:00:00Z',
    'status': 'Open',
    'created_by_id': 1,
  },
];

final _mockInvoices = [
  {
    'id': 1,
    'invoice_number': 'INV-2026-001',
    'client_name': 'Noida Metro Rail Corp',
    'project_id': 1,
    'total_amount': 75000.0,
    'status': 'Unpaid',
    'issue_date': '2026-06-01',
    'due_date': '2026-07-01',
    'payments': [],
  },
  {
    'id': 2,
    'invoice_number': 'INV-2026-002',
    'client_name': 'PWD Division 3',
    'project_id': 1,
    'total_amount': 120000.0,
    'status': 'Paid',
    'issue_date': '2026-05-01',
    'due_date': '2026-06-01',
    'payments': [
      {'id': 1, 'amount': 120000.0, 'payment_date': '2026-05-28', 'method': 'Bank Transfer'},
    ],
  },
];

final _mockInventory = [
  {
    'id': 1,
    'item_name': 'OPC 43 Grade Cement',
    'sku': 'CEM-001',
    'category': 'Material',
    'unit': 'Bags',
    'quantity': 250,
    'safety_stock': 100,
    'rate': 380,
  },
  {
    'id': 2,
    'item_name': 'TMT Steel Bars 12mm',
    'sku': 'STL-001',
    'category': 'Material',
    'unit': 'Tons',
    'quantity': 15,
    'safety_stock': 5,
    'rate': 72000,
  },
];

final _mockMachinery = [
  {
    'id': 1,
    'name': 'CAT 320 Excavator',
    'model_number': 'CAT-320D2',
    'hourly_rate': 2500,
    'total_hours_run': 1240.5,
    'status': 'Active',
    'tenant_id': 1,
  },
];

final _mockWorkers = [
  {'id': 1, 'name': 'Ram Singh', 'skill_category': 'Mason', 'daily_rate': 600, 'tenant_id': 1},
  {'id': 2, 'name': 'Lakhan Lal', 'skill_category': 'Helper', 'daily_rate': 400, 'tenant_id': 1},
  {'id': 3, 'name': 'Suresh Yadav', 'skill_category': 'Welder', 'daily_rate': 700, 'tenant_id': 1},
];

final _mockPayroll = [
  {'id': 1, 'worker_id': 1, 'worker_name': 'Ram Singh', 'total_days': 26, 'total_amount': 15600, 'status': 'Unpaid', 'period': 'June 2026'},
  {'id': 2, 'worker_id': 2, 'worker_name': 'Lakhan Lal', 'total_days': 26, 'total_amount': 10400, 'status': 'Paid', 'period': 'June 2026'},
];

final _mockExpenses = [
  {'id': 1, 'category': 'Fuel', 'amount': 15000, 'description': 'Diesel for excavator (500 litres)', 'expense_date': '2026-06-15', 'tenant_id': 1},
  {'id': 2, 'category': 'Consumables', 'amount': 8500, 'description': 'Welding electrodes & grinding wheels', 'expense_date': '2026-06-14', 'tenant_id': 1},
];

final _mockPurchaseOrders = [
  {'id': 1, 'vendor_name': 'UltraTech Cement', 'item_name': 'OPC 43 Grade Cement', 'quantity': 100, 'unit': 'Bags', 'unit_price': 380, 'total_cost': 38000, 'status': 'Pending', 'order_date': '2026-06-20', 'tenant_id': 1},
];

final _mockWorkOrders = [
  {'id': 1, 'title': 'Foundation Pouring', 'description': 'M25 concrete pour for columns A1-A6', 'priority': 'High', 'status': 'InProgress', 'assigned_to': 'Site Engineer', 'created_at': '2026-06-25', 'tenant_id': 1},
];

final _mockChatMessages = [
  {'id': 1, 'sender_id': 1, 'receiver_id': 2, 'content': 'Welcome to CivilOS! The project site is ready for inspection.', 'created_at': '2026-06-26T10:00:00Z', 'sender': {'id': 1, 'name': 'Test User'}, 'receiver': {'id': 2, 'name': 'Acme Owner'}},
  {'id': 2, 'sender_id': 2, 'receiver_id': 1, 'content': 'Thanks! I will visit the site tomorrow with the quality team to review the progress.', 'created_at': '2026-06-26T11:00:00Z', 'sender': {'id': 2, 'name': 'Acme Owner'}, 'receiver': {'id': 1, 'name': 'Test User'}},
];

final _mockUsers = [
  {'id': 1, 'name': 'Test User', 'email': 'test@civilos.com', 'role': 'SuperAdmin', 'tenant_id': null},
  {'id': 2, 'name': 'Owner Acme', 'email': 'owner@acme.com', 'role': 'ContractorOwner', 'tenant_id': 1},
  {'id': 3, 'name': 'Site Engineer', 'email': 'engineer@acme.com', 'role': 'SiteEngineer', 'tenant_id': 1},
];

final _mockTenants = [
  {'id': 1, 'name': 'Acme Construction Ltd.', 'slug': 'acme', 'is_active': true, 'feature_flags': '{}'},
  {'id': 2, 'name': 'BuildRight Corp', 'slug': 'buildright', 'is_active': true, 'feature_flags': '{}'},
];

final _mockNotifications = [
  {'message': 'Daily diary submitted for Metro Project', 'type': 'info'},
  {'message': 'Invoice INV-2026-001 is now overdue', 'type': 'warning'},
];

// ───── Screenshot Helpers ─────

Future<void> captureScreenshot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final RenderRepaintBoundary? boundary = tester.renderObject(
    find.byKey(const Key('screenshot-boundary')),
  ) as RenderRepaintBoundary?;
  if (boundary == null) {
    debugPrint('WARNING: No RepaintBoundary found for $name');
    return;
  }
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    await File('$_screenshotDir/$name').writeAsBytes(byteData.buffer.asUint8List());
    debugPrint('Captured: $name (${byteData.lengthInBytes} bytes)');
  }
}

Widget _boundaryApp(Widget screen) {
  return RepaintBoundary(
    key: const Key('screenshot-boundary'),
    child: MaterialApp(theme: CivilTheme.darkTheme, home: screen),
  );
}

Widget _makeApp(Widget screen,
    {Map<String, dynamic>? apiData, bool withAuth = true}) {
  final overrides = <Override>[];
  if (apiData != null) {
    overrides.add(apiClientProvider.overrideWithValue(MockApiClient(apiData)));
  }
  if (withAuth) {
    overrides.add(authProvider.overrideWith(() => _MockAuthNotifier()));
  }
  return ProviderScope(
    overrides: overrides,
    child: _boundaryApp(screen),
  );
}

// ───── Tests ─────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory(_screenshotDir);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  });

  Future<void> pumpAndCapture(WidgetTester tester, String name) async {
    // Pump initial frame, then process microtasks (for mock API delay)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await captureScreenshot(tester, name);
  }

  testWidgets('01 - Login Screen', (tester) async {
    await tester.pumpWidget(_makeApp(const LoginScreen(), withAuth: false));
    await pumpAndCapture(tester, 'login.png');
  });

  testWidgets('02 - Dashboard Home', (tester) async {
    await tester.pumpWidget(_makeApp(
      const DashboardHomeView(),
      apiData: {
        '/dashboard/stats': _mockDashboardStats,
        '/projects': _mockProjects,
      },
    ));
    await pumpAndCapture(tester, 'dashboard.png');
  });

  testWidgets('03 - Projects Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const ProjectScreen(),
      apiData: {'/projects': _mockProjects},
    ));
    await pumpAndCapture(tester, 'projects_screen.png');
  });

  testWidgets('04 - Daily Diary Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const DiaryScreen(),
      apiData: {
        '/projects': _mockProjects,
        '/projects/1/diaries': _mockDiaries,
      },
    ));
    await pumpAndCapture(tester, 'diary_screen.png');
  });

  testWidgets('05 - Marketplace Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const MarketplaceScreen(),
      apiData: {
        '/marketplace': _mockListings,
        '/marketplace/partners': _mockPartners,
      },
    ));
    await pumpAndCapture(tester, 'marketplace_screen.png');
  });

  testWidgets('06 - Tenders Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const TendersScreen(),
      apiData: {'/tenders': _mockTenders},
    ));
    await pumpAndCapture(tester, 'tenders_screen.png');
  });

  testWidgets('07 - Billing Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const BillingScreen(),
      apiData: {'/invoices': _mockInvoices},
    ));
    await pumpAndCapture(tester, 'billing_screen.png');
  });

  testWidgets('08 - Inventory Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const InventoryScreen(),
      apiData: {'/inventory': _mockInventory},
    ));
    await pumpAndCapture(tester, 'inventory_screen.png');
  });

  testWidgets('09 - Machinery Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const MachineryScreen(),
      apiData: {'/machinery': _mockMachinery},
    ));
    await pumpAndCapture(tester, 'machinery_screen.png');
  });

  testWidgets('10 - Labor Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const LaborScreen(),
      apiData: {
        '/labor': _mockWorkers,
        '/labor/payroll': _mockPayroll,
      },
    ));
    await pumpAndCapture(tester, 'labor_screen.png');
  });

  testWidgets('11 - Expenses Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const ExpensesScreen(),
      apiData: {'/expenses': _mockExpenses},
    ));
    await pumpAndCapture(tester, 'expenses_screen.png');
  });

  testWidgets('12 - Purchase Orders Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const PurchaseOrdersScreen(),
      apiData: {'/purchase-orders': _mockPurchaseOrders},
    ));
    await pumpAndCapture(tester, 'purchase_orders_screen.png');
  });

  testWidgets('13 - Work Orders Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const WorkOrdersScreen(),
      apiData: {'/work-orders': _mockWorkOrders},
    ));
    await pumpAndCapture(tester, 'work_orders_screen.png');
  });

  testWidgets('14 - Chat Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const ChatScreen(),
      apiData: {'/chat/2': _mockChatMessages},
    ));
    await pumpAndCapture(tester, 'chat_screen.png');
  });

  testWidgets('15 - Notifications Screen', (tester) async {
    // Pre-seed notifications via ProviderContainer
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
      ],
    );
    for (final n in _mockNotifications) {
      container.read(notificationProvider.notifier).addLocalNotification(n);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _boundaryApp(const NotificationsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await captureScreenshot(tester, 'notifications_screen.png');
    container.dispose();
  });

  testWidgets('16 - Settings Screen', (tester) async {
    await tester.pumpWidget(_makeApp(const SettingsScreen()));
    await pumpAndCapture(tester, 'settings_screen.png');
  });

  testWidgets('17 - Admin Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const AdminScreen(),
      apiData: {'/admin/tenants': _mockTenants},
    ));
    await pumpAndCapture(tester, 'admin_screen.png');
  });

  testWidgets('18 - User Management Screen', (tester) async {
    await tester.pumpWidget(_makeApp(
      const UserManagementScreen(),
      apiData: {'/users': _mockUsers},
    ));
    await pumpAndCapture(tester, 'user_management_screen.png');
  });
}
