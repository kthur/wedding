import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/wedding_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/preparation_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/more_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed (running in fallback local mode): $e');
  }
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WeddingPlannerApp(),
    ),
  );
}

class WeddingPlannerApp extends ConsumerWidget {
  const WeddingPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget homeWidget;
    if (authState.isLoading && authState.currentUser == null) {
      homeWidget = const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5271)),
          ),
        ),
      );
    } else if (authState.currentUser == null) {
      homeWidget = const LoginScreen();
    } else if (authState.currentUser!.name.isEmpty || authState.currentUser!.gender.isEmpty) {
      homeWidget = const ProfileSetupScreen();
    } else {
      homeWidget = const MainNavigationScreen();
    }

    return MaterialApp(
      title: 'Wedding Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5271)),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: homeWidget,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PreparationScreen(),
    ScheduleScreen(),
    BudgetScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF5271),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: '준비'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: '일정'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: '예산'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined), activeIcon: Icon(Icons.more_horiz), label: '더보기'),
        ],
      ),
    );
  }
}
