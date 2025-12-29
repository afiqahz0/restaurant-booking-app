// lib/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:restaurantbooking/pages/user/my_reservations.dart';

// ================= GUEST =================
import 'pages/guest/guest_landing_page.dart';
import 'pages/guest/package_detail.dart';

// ================= AUTH =================
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/admin_login.dart';

// ================= USER =================
import 'pages/user/user_dashboard.dart';
import 'pages/user/user_browse.dart';
import 'pages/user/booking_form.dart';
import 'pages/user/booking_success.dart';
import 'pages/user/my_reservations.dart';
import 'pages/user/view_reservation_user.dart';
import 'pages/user/update_reservation.dart';
import 'pages/user/package_detail_user.dart';

// ================= ADMIN =================
import 'pages/admin/admin_dashboard.dart';
import 'pages/admin/manage_packages.dart';
import 'pages/admin/add_package.dart';
import 'pages/admin/edit_package.dart';
import 'pages/admin/manage_users.dart';
import 'pages/admin/manage_reservations.dart';
import 'pages/admin/add_reservation.dart';
import 'pages/admin/view_reservation.dart';
import 'pages/admin/edit_reservation.dart';
import 'pages/admin/cancel_reservation.dart';

final router = GoRouter(
  routes: [

    // 🔥 START PAGE (GUEST)
    GoRoute(
      path: '/',
      builder: (context, state) => const GuestLandingPage(),
    ),

    // ================= GUEST =================
    GoRoute(
      path: '/package/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PackageDetailPage(packageId: id);
      },
    ),

    // ================= AUTH =================
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginPage(),
    ),

    // ================= USER =================
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const UserDashboardPage(),
    ),

    GoRoute(
      path: '/browse',
      builder: (context, state) => const UserBrowsePage(),
    ),

    GoRoute(
      path: '/booking/:packageId',
      builder: (context, state) {
        final id = state.pathParameters['packageId']!;
        return BookingFormPage(packageId: id);
      },
    ),

    GoRoute(
      path: '/booking/success/:id', // ✅ Pass ID in the URL
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BookingSuccessPage(reservationId: id); // ✅ Pass only the ID
      },
    ),

    GoRoute(
      path: '/reservations',
      builder: (context, state) => const MyReservationPage(),
    ),

    GoRoute(
      path: '/reservations/edit/:id',
      builder: (context, state) {
        return UpdateReservationPage(
          reservationId: state.pathParameters['id']!,
        );
      },
    ),

    GoRoute(
      path: '/user/reservations/view/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UserViewReservationPage(reservationId: id);
      },
    ),


    GoRoute(
      path: '/user/package/:id',
      builder: (context, state) {
        return UserPackageDetailPage(
          packageId: state.pathParameters['id']!,
        );
      },
    ),


    // ================= ADMIN =================
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),

    GoRoute(
      path: '/admin/packages',
      builder: (context, state) => const ManagePackagesPage(),
    ),

    GoRoute(
      path: '/admin/packages/add',
      builder: (context, state) => const AddPackagePage(),
    ),

    GoRoute(
      path: '/admin/packages/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditPackagePage(packageId: id);
      },
    ),

    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const ManageUsersPage(),
    ),

    GoRoute(
      path: '/admin/reservations',
      builder: (context, state) => const ManageReservationsPage(),
    ),

    GoRoute(
      path: '/admin/reservations/add',
      builder: (context, state) => const AddReservationPage(),
    ),

    GoRoute(
      path: '/admin/reservations/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditReservationPage(reservationId: id);
      },
    ),

    GoRoute(
      path: '/admin/reservations/view/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ViewReservationPage(reservationId: id);
      },
    ),

    GoRoute(
      path: '/admin/reservations/cancel/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CancelReservationPage(reservationId: id);
      },
    ),
  ],
);
