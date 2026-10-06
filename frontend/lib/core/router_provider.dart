import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/dashboard_mobile_view.dart';
import '../features/projects/project_screen.dart';
import '../features/projects/project_detail_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/tenders/tenders_screen.dart';
import '../features/tenders/tender_detail_screen.dart';
import '../features/map/map_screen.dart';
import '../features/map/live_tracking_screen.dart';
import '../features/documents/documents_screen.dart';
import '../features/drawings/drawings_screen.dart';
import '../features/site_diary/diary_screen.dart';
import '../features/labor/labor_screen.dart';
import '../features/machinery/machinery_screen.dart';
import '../features/inspections/inspections_screen.dart';
import '../features/checklists/checklists_screen.dart';
import '../features/work_orders/work_orders_screen.dart';
import '../features/vehicles/vehicles_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/purchase_orders/purchase_orders_screen.dart';
import '../features/vendors/vendors_screen.dart';
import '../features/billing/billing_screen.dart';
import '../features/payments/payments_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/chat/b2b_chat_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/copilot/copilot_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/admin_vendors_screen.dart';
import '../features/admin/admin_settings_screen.dart';
import '../features/marketplace/vendor_directory_screen.dart';
import '../features/bills/bills_screen.dart';
import '../features/bills/payments_screen.dart' as bill_payments;
import '../features/issues/issues_screen.dart';
import '../features/vendor/vendor_products_screen.dart';
import '../features/vendor/vendor_profile_screen.dart';
import '../features/vendor/vendor_payments_screen.dart';
import '../features/vendor/vendor_dashboard.dart';
import '../features/vendor/vendor_orders_screen.dart';
import '../features/vendor/vendor_invoicing_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/otp_login_screen.dart';
import '../features/auth/profile_screen.dart';
import '../features/settings/activity_log_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/search/global_search_screen.dart';
import '../features/inventory/material_price_history_screen.dart';
import 'fcm_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Check for FCM deep link
      final pendingRoute = FcmService.pendingRoute;
      if (pendingRoute != null && state.matchedLocation != pendingRoute) {
        FcmService.pendingRoute = null;
        return pendingRoute;
      }
      if (authState.isLoading) return null; // Don't redirect while loading
      
      final isAuth = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }
      
      if (isAuth && isGoingToLogin) {
        if (authState.isSuperAdmin) return '/admin';
        if (authState.isVendor) return '/vendor/dashboard';
        return '/';
      }

      // Default redirects based on role
      if (state.matchedLocation == '/') {
        if (authState.isSuperAdmin) {
          return '/admin';
        } else if (authState.isVendor) {
          return '/vendor/dashboard';
        } else {
          return '/dashboard'; // Contractor & Supervisor
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-login',
        builder: (context, state) => const OtpLoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/activity-log',
        builder: (context, state) => const ActivityLogScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/vendors',
        builder: (context, state) => const AdminVendorsScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/vendor',
        builder: (context, state) => const VendorDashboardScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final isDesktop = MediaQuery.of(context).size.width > 800;
              if (isDesktop) {
                return const DashboardHomeView();
              } else {
                return DashboardMobileView(
                  onOpenDrawer: () => Scaffold.of(context).openDrawer(),
                );
              }
            },
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final project = state.extra as Map<String, dynamic>? ?? {};
                  return ProjectDetailScreen(project: project);
                },
              ),
            ],
          ),
          GoRoute(path: '/schedule', builder: (context, state) => const ScheduleScreen()),
          GoRoute(
            path: '/tenders',
            builder: (context, state) => const TendersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final tender = state.extra as Map<String, dynamic>? ?? {};
                  return TenderDetailScreen(tender: tender);
                },
              ),
            ],
          ),
          GoRoute(path: '/documents', builder: (context, state) => const DocumentsScreen()),
          GoRoute(path: '/drawings', builder: (context, state) => const DrawingsScreen()),
          GoRoute(path: '/diary', builder: (context, state) => const DiaryScreen()),
          GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
          GoRoute(path: '/material-price-history', builder: (context, state) => const MaterialPriceHistoryScreen()),
          GoRoute(path: '/machinery', builder: (context, state) => const MachineryScreen()),
          GoRoute(path: '/labor', builder: (context, state) => const LaborScreen()),
          GoRoute(path: '/location', builder: (context, state) => const LiveTrackingScreen()),
          GoRoute(path: '/issues', builder: (context, state) => const IssuesScreen()),
          GoRoute(path: '/vendors', builder: (context, state) => const VendorDirectoryScreen()),
          GoRoute(path: '/bills', builder: (context, state) => const BillsScreen()),
          GoRoute(path: '/bill-payments', builder: (context, state) => const bill_payments.PaymentsScreen()),
          GoRoute(path: '/vendor/products', builder: (context, state) => const VendorProductsScreen()),
          GoRoute(path: '/vendor/profile', builder: (context, state) => const VendorProfileScreen()),
          GoRoute(path: '/vendor/payments', builder: (context, state) => const VendorPaymentsScreen()),
          GoRoute(path: '/vendor/dashboard', builder: (context, state) => const VendorDashboardScreen()),
          GoRoute(path: '/vendor/orders', builder: (context, state) => const VendorOrdersScreen()),
          GoRoute(path: '/vendor/invoicing', builder: (context, state) => const VendorInvoicingScreen()),

          GoRoute(path: '/checklists', builder: (context, state) => const ChecklistsScreen()),
          GoRoute(path: '/work_orders', builder: (context, state) => const WorkOrdersScreen()),
          GoRoute(path: '/vehicles', builder: (context, state) => const VehiclesScreen()),
          GoRoute(path: '/purchase_orders', builder: (context, state) => const PurchaseOrdersScreen()),

          GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
          GoRoute(path: '/expenses', builder: (context, state) => const ExpensesScreen()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: '/chat', builder: (context, state) => const B2BChatScreen()),
          GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: '/copilot', builder: (context, state) => const CopilotScreen()),
        ],
      ),
    ],
  );
});
