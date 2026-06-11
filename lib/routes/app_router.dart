import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/booking/screens/booking_screen.dart';
import '../features/booking/screens/success_booking_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/create_profile_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/medical_record/screens/medical_record_screen.dart';
import '../features/blog/screens/blog_list_screen.dart';
import '../features/blog/screens/blog_detail_screen.dart';
import '../features/lab_staff/screens/lab_staff_landing.dart';
import '../features/lab_staff/screens/lab_staff_dashboard.dart';
import '../features/lab_staff/screens/appointment_schedule_screen.dart';
import '../shared/widgets/main_scaffold.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) async {
        final isAuth = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        final isRegister = state.matchedLocation == '/register';
        final isForgotPass = state.matchedLocation == '/forgot-password';
        final isPublic = isLoggingIn || isRegister || isForgotPass;

        // Auth required routes
        final protectedRoutes = [
          '/booking',
          '/history',
          '/profile',
          '/create-profile',
          '/change-password',
          '/medical-record',
          '/lab-staff',
        ];

        final needsAuth = protectedRoutes
            .any((r) => state.matchedLocation.startsWith(r));

        if (needsAuth && !isAuth) {
          return '/login';
        }

        // Lab staff routes need specific role
        if (state.matchedLocation.startsWith('/lab-staff') && isAuth) {
          final role = authProvider.role;
          final canAccess = role == 'Admin' ||
              role == 'Manager' ||
              role == 'LabUser' ||
              role == 'Receptionist' ||
              role == 'LabBlogger' ||
              role == 'Technician';
          if (!canAccess) return '/';
        }

        return null;
      },
      routes: [
        // ─── Main Shell (Bottom Nav) ────────────────────────
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (c, s) =>
                  _noTransition(c, s, const HomeScreen()),
            ),
            GoRoute(
              path: '/history',
              pageBuilder: (c, s) =>
                  _noTransition(c, s, const HistoryScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (c, s) =>
                  _noTransition(c, s, const ProfileScreen()),
            ),
          ],
        ),

        // ─── Auth routes ─────────────────────────────────────
        GoRoute(
          path: '/login',
          pageBuilder: (c, s) => _slide(c, s, const LoginScreen()),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (c, s) => _slide(c, s, const RegisterScreen()),
        ),
        GoRoute(
          path: '/forgot-password',
          pageBuilder: (c, s) =>
              _slide(c, s, const ForgotPasswordScreen()),
        ),

        // ─── Booking routes ───────────────────────────────────
        GoRoute(
          path: '/booking',
          pageBuilder: (c, s) => _slide(c, s, const BookingScreen()),
        ),
        GoRoute(
          path: '/booking/success',
          pageBuilder: (c, s) {
            final bookingId = s.uri.queryParameters['bookingId'];
            return _slide(
                c, s, SuccessBookingScreen(bookingId: bookingId));
          },
        ),

        // ─── Profile sub-routes ───────────────────────────────
        GoRoute(
          path: '/create-profile',
          pageBuilder: (c, s) =>
              _slide(c, s, const CreateProfileScreen()),
        ),
        GoRoute(
          path: '/change-password',
          pageBuilder: (c, s) =>
              _slide(c, s, const ChangePasswordScreen()),
        ),

        // ─── Medical Record ───────────────────────────────────
        GoRoute(
          path: '/medical-record',
          pageBuilder: (c, s) =>
              _slide(c, s, const MedicalRecordScreen()),
        ),

        // ─── Blog routes ──────────────────────────────────────
        GoRoute(
          path: '/blog',
          pageBuilder: (c, s) => _slide(c, s, const BlogListScreen()),
        ),
        GoRoute(
          path: '/blog/:id',
          pageBuilder: (c, s) {
            final id = s.pathParameters['id']!;
            return _slide(c, s, BlogDetailScreen(postId: id));
          },
        ),

        // ─── Lab Staff routes ─────────────────────────────────
        GoRoute(
          path: '/lab-staff',
          pageBuilder: (c, s) =>
              _slide(c, s, const LabStaffLanding()),
        ),
        GoRoute(
          path: '/lab-staff/dashboard',
          pageBuilder: (c, s) =>
              _slide(c, s, const LabStaffDashboard()),
        ),
        GoRoute(
          path: '/lab-staff/appointment-schedule',
          pageBuilder: (c, s) =>
              _slide(c, s, const AppointmentScheduleScreen()),
        ),
      ],
    );
  }

  static CustomTransitionPage _noTransition(
      BuildContext c, GoRouterState s, Widget child) {
    return CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionsBuilder: (_, __, ___, w) => w,
    );
  }

  static CustomTransitionPage _slide(
      BuildContext c, GoRouterState s, Widget child) {
    return CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, w) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: w,
      ),
    );
  }
}
