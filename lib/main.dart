// Jeevan Sutra - Living Intelligence Production Application Entry Point
// Integrating Google AI Studio Design System with Firebase, AI Services & Local Storage
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'data/sample_data.dart';
import 'models/wellness_models.dart';
import 'screens/about_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/breathwork_session_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/dinacharya_screen.dart';
import 'screens/dosha_assessment_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/knowledge_library_screen.dart';
import 'screens/medicinal_plants_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ritucharya_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/yoga_screen.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'splash/jeevan_sutra_splash.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bar_and_drawer.dart';
import 'widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with current platform configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(providerWeb: WebDebugProvider());
    } else {
      const siteKey = String.fromEnvironment('APP_CHECK_RECAPTCHA_V3_SITE_KEY');
      if (siteKey.isEmpty) {
        throw StateError(
          'Set APP_CHECK_RECAPTCHA_V3_SITE_KEY for production web builds.',
        );
      }
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(siteKey),
      );
    }
  } else {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  }

  // Initialize local notifications channel
  await NotificationService.instance.init();

  runApp(const JeevanSutraApp());
}

class JeevanSutraApp extends StatefulWidget {
  const JeevanSutraApp({super.key});

  @override
  State<JeevanSutraApp> createState() => _JeevanSutraAppState();
}

class _JeevanSutraAppState extends State<JeevanSutraApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jeevan Sutra',
      theme: JeevanSutraTheme.lightTheme,
      darkTheme: JeevanSutraTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _StartupScreen(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class _StartupScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const _StartupScreen({required this.isDarkMode, required this.onToggleTheme});

  @override
  State<_StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<_StartupScreen> {
  bool _showHome = false;

  void _finishSplash() {
    if (!mounted) return;
    setState(() {
      _showHome = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return MainNavigationContainer(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      );
    }

    return JeevanSutraSplash(onComplete: _finishSplash);
  }
}

class MainNavigationContainer extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainNavigationContainer({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String _currentRoute = 'home';
  late UserProfile _userProfile;
  int _profileRefreshToken = 0;

  List<Widget> get _screens => [
    const HomeScreen(),
    const ExploreScreen(),
    const ScannerScreen(),
    const AiScreen(),
    ProfileScreen(
      refreshToken: _profileRefreshToken,
      onProfileChanged: _syncUserProfile,
    ),
  ];

  String get _selectedRoute => const [
    'home',
    'explore',
    'scanner',
    'ai_assistant',
    'profile',
  ][_selectedIndex];

  @override
  void initState() {
    super.initState();
    _userProfile = SampleData.defaultProfile.copyWith();
    _syncUserProfile();
  }

  Future<void> _syncUserProfile() async {
    final name = await LocalStorageService.instance.getProfileName();
    final dosha = await LocalStorageService.instance.getDosha();
    if (mounted) {
      setState(() {
        _userProfile = _userProfile.copyWith(
          name: name,
          dominantPrakriti: dosha != null && dosha.isNotEmpty
              ? dosha
              : SampleData.defaultProfile.dominantPrakriti,
        );
      });
    }
  }

  void _onBottomNavTap(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() {
      _selectedIndex = index;
      _currentRoute = _selectedRoute;
      if (index == 4) _profileRefreshToken++;
    });
    _syncUserProfile();
  }

  void _onSelectDrawerDestination(String route) {
    // Close drawer
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    setState(() {
      _currentRoute = route;
    });

    switch (route) {
      case 'home':
        _onBottomNavTap(0);
        break;
      case 'explore':
        _onBottomNavTap(1);
        break;
      case 'scanner':
        _onBottomNavTap(2);
        break;
      case 'ai_assistant':
        _onBottomNavTap(3);
        break;
      case 'profile':
      case 'saved':
      case 'progress':
        _onBottomNavTap(4);
        break;
      case 'diet':
        _pushScreen(const DietScreen());
        break;
      case 'yoga':
        _pushScreen(const YogaScreen());
        break;
      case 'breathwork':
        _pushScreen(const BreathworkSessionScreen());
        break;
      case 'dinacharya':
        _pushScreen(const DinacharyaScreen());
        break;
      case 'ritucharya':
        _pushScreen(const RitucharyaScreen());
        break;
      case 'plants':
        _pushScreen(const MedicinalPlantsScreen());
        break;
      case 'library':
        _pushScreen(const KnowledgeLibraryScreen());
        break;
      case 'settings':
        _pushScreen(const SettingsScreen());
        break;
      case 'about':
        _pushScreen(const AboutScreen());
        break;
      case 'dosha_assessment':
        _pushScreen(
          DoshaAssessmentScreen(
            onBack: () => Navigator.pop(context),
            onDoshaDetermined: (prakriti) {
              if (!mounted) return;
              setState(() {
                _userProfile.dominantPrakriti = prakriti;
              });
            },
          ),
        );
        break;
      case 'auth':
        _pushScreen(
          Builder(
            builder: (authContext) => AuthScreen(
              onAuthenticated: (newProfile) async {
                await LocalStorageService.instance.saveProfileName(
                  newProfile.name,
                );
                await LocalStorageService.instance.saveDosha(
                  newProfile.dominantPrakriti,
                );
                if (!mounted) return;
                setState(() {
                  _userProfile = newProfile;
                });
                if (authContext.mounted &&
                    ModalRoute.of(authContext)?.isCurrent == true) {
                  Navigator.of(authContext).pop();
                }
              },
            ),
          ),
        );
        break;
      default:
        _onBottomNavTap(0);
    }
  }

  Future<void> _pushScreen(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    setState(() {
      _currentRoute = _selectedRoute;
      _profileRefreshToken++;
    });
    await _syncUserProfile();
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Jeevan Sutra';
      case 1:
        return 'Explore Wellness';
      case 2:
        return 'Plant Scanner';
      case 3:
        return 'AI Wellness Guide';
      case 4:
        return 'Health Profile';
      default:
        return 'Jeevan Sutra';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    return Scaffold(
      key: _scaffoldKey,
      appBar: JeevanSutraAppBar(
        title: _getTitle(),
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onSearchPressed: () => _onBottomNavTap(1),
        onProfilePressed: () => _onBottomNavTap(4),
      ),
      drawer: JeevanSutraDrawer(
        currentRoute: _currentRoute,
        onSelectDestination: _onSelectDrawerDestination,
        profile: _userProfile,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var index = 0; index < screens.length; index++)
            TickerMode(enabled: index == _selectedIndex, child: screens[index]),
        ],
      ),
      bottomNavigationBar: JeevanSutraBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
