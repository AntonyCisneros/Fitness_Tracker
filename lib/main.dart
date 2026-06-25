import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/data/datasources/biometric_datasource.dart';
import 'features/auth/domain/usecases/authenticate_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/history/domain/entities/activity_record.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/steps/presentation/widgets/step_counter_widget.dart';
import 'features/tracking/presentation/widgets/route_map_widget.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final biometricDataSource = BiometricDataSourceImpl();
    final authenticateUser = AuthenticateUser(biometricDataSource);

    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: BlocProvider(
        create: (_) => AuthBloc(authenticateUser),
        child: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;

  void _onAuthSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return const HomePage();
    }
    return LoginPage(onAuthSuccess: _onAuthSuccess);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final HistoryBloc _historyBloc;

  @override
  void initState() {
    super.initState();
    _historyBloc = HistoryBloc();
    _historyBloc.add(LoadHistory());
  }

  @override
  void dispose() {
    _historyBloc.close();
    super.dispose();
  }

  void _onStepTrackingStop(
      int stepCount, String activityType, double estimatedCalories) {
    final record = ActivityRecord(
      date: DateTime.now(),
      stepCount: stepCount,
      activityType: activityType,
      estimatedCalories: estimatedCalories,
      distanceKm: 0,
      durationMinutes: 0,
    );
    _historyBloc.add(AddRecord(record));
  }

  void _onGpsTrackingStop(
      double distanceKm, int durationMinutes, double estimatedCalories) {
    final record = ActivityRecord(
      date: DateTime.now(),
      stepCount: 0,
      activityType: 'GPS',
      estimatedCalories: estimatedCalories,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
    _historyBloc.add(AddRecord(record));
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final hPadding = Responsive.safePaddingHorizontal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboard(hPadding),
              HistoryPage(bloc: _historyBloc),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.9),
          border: const Border(
            top: BorderSide(color: AppColors.glassBorder, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(4).clamp(16, 32),
              vertical: Responsive.h(0.8).clamp(6, 10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
                _buildNavItem(Icons.history_rounded, 'Historial', 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(4.5).clamp(16, 24),
          vertical: Responsive.h(1).clamp(8, 12),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.15 : 1.0,
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                size: Responsive.w(5.5).clamp(20, 24),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: Responsive.sp(12).clamp(11, 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(double hPadding) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 8),
            child: Row(
              children: [
                Container(
                  width: Responsive.w(11).clamp(40, 50),
                  height: Responsive.w(11).clamp(40, 50),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: Responsive.w(5.5).clamp(20, 26),
                  ),
                ),
                SizedBox(width: Responsive.w(3).clamp(10, 16)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitness Tracker',
                      style: TextStyle(
                        fontSize: Responsive.sp(19).clamp(16, 22),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Bienvenido de vuelta',
                      style: TextStyle(
                        fontSize: Responsive.sp(12).clamp(11, 14),
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(hPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              StepCounterWidget(onStop: _onStepTrackingStop),
              SizedBox(height: Responsive.h(2).clamp(14, 22)),
              RouteMapWidget(onStop: _onGpsTrackingStop),
              SizedBox(height: Responsive.h(2).clamp(14, 22)),
            ]),
          ),
        ),
      ],
    );
  }
}
