import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/member_session_provider.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/directory_screen.dart';
import 'screens/thanks_note_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/face_to_face_form_screen.dart';
import 'screens/splash_screen.dart';

import 'screens/visitor_form_screen.dart';
import 'screens/attendance_bylaw_screen.dart';
import 'language_service.dart';

import 'services/member_service.dart';
import 'widgets/special_events_popup.dart';
import 'models/member.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'special_events',
  'Special Events Notifications',
  description: 'Notifications for Birthdays, Weddings, and Business Open Days',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize local notifications for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _triggerSpecialEventsPopup();
      },
    );
  } catch (e) {
    debugPrint('Local notification initialization error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => MemberSessionProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _triggerSpecialEventsPopup() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_special_events_date');

    await Future.delayed(const Duration(milliseconds: 500));
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final members = await MemberService().streamActiveMembers().first;
    
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentDay = now.day;

    List<Member> birthdays = [];
    List<Member> anniversaries = [];
    List<Member> companyDays = [];

    bool isToday(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return false;
      try {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return month == currentMonth && day == currentDay;
        }
      } catch (_) {}
      return false;
    }

    for (var member in members) {
      if (isToday(member.dateOfBirth)) birthdays.add(member);
      if (isToday(member.wedding)) anniversaries.add(member);
      if (isToday(member.businessStartDate)) companyDays.add(member);
    }

    if (birthdays.isNotEmpty || anniversaries.isNotEmpty || companyDays.isNotEmpty) {
      await SpecialEventsPopup.show(
        context,
        birthdays: birthdays,
        anniversaries: anniversaries,
        companyDays: companyDays,
      );
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('last_special_events_date', todayStr);
    }
  } catch (e) {
    debugPrint('Error triggering popup: $e');
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final ValueNotifier<double> textScaleFactor = ValueNotifier<double>(1.0);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _splashElapsed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final startTime = DateTime.now();
    await context.read<MemberSessionProvider>().restoreSession();

    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 2000) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (mounted) {
      setState(() => _splashElapsed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<MemberSessionProvider>();

    if (!_splashElapsed || (authProvider.isLoading && authProvider.currentMember == null)) {
      return MaterialApp(
        title: 'Boreo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: AppScrollBehavior(),
        home: const SplashScreen(),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: MyApp.textScaleFactor,
      builder: (context, scale, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Boreo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          scrollBehavior: AppScrollBehavior(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            );
          },
          home: authProvider.isLoggedIn
              ? MainShell(
                  onLogout: () {
                    context.read<MemberSessionProvider>().logout();
                  },
                )
              : const LoginScreen(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isVisitor {
    return context.read<MemberSessionProvider>().currentMember?.docId.startsWith('v_') ?? false;
  }

  List<Widget> get _pages => [
    HomeScreen(onNavigateToThanks: () {
      setState(() {
        _currentIndex = 2;
      });
    }),
    const DirectoryScreen(),
    const ThanksNoteScreen(),
    ProfileScreen(onLogout: widget.onLogout),
  ];

  Future<bool?> _showExitConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Exit App",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          content: const Text("Are you sure you want to exit?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "No",
                style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Yes", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return t("Dashboard");
      case 1:
        return t("Member Directory");
      case 2:
        return t("REF / Thanksnote");
      case 3:
        return t("My Member Profile");
      default:
        return "Boreo";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<MemberSessionProvider>().currentMember;

    return ListenableBuilder(
      listenable: LanguageService.currentLanguage,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
            } else {
              final shouldExit = await _showExitConfirmationDialog();
              if (shouldExit == true) {
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            onDrawerChanged: (isOpened) => FocusManager.instance.primaryFocus?.unfocus(),
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
              ),
              title: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_getAppBarTitle()),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(color: Colors.white24, height: 1.0),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.format_size, color: Colors.white),
                  tooltip: 'Font Size',
                  onSelected: (String action) {
                    double current = MyApp.textScaleFactor.value;
                    if (action == 'increase') {
                      if (current < 1.4) {
                        MyApp.textScaleFactor.value = double.parse((current + 0.1).toStringAsFixed(1));
                      }
                    } else if (action == 'decrease') {
                      if (current > 0.8) {
                        MyApp.textScaleFactor.value = double.parse((current - 0.1).toStringAsFixed(1));
                      }
                    } else if (action == 'reset') {
                      MyApp.textScaleFactor.value = 1.0;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final int percentage = (MyApp.textScaleFactor.value * 100).round();
                    return [
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          "${t("Font Size")}: $percentage%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'increase',
                        enabled: MyApp.textScaleFactor.value < 1.4,
                        child: Row(
                          children: [
                            const Icon(Icons.zoom_in, size: 20, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(t("Increase Font")),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'decrease',
                        enabled: MyApp.textScaleFactor.value > 0.8,
                        child: Row(
                          children: [
                            const Icon(Icons.zoom_out, size: 20, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(t("Decrease Font")),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'reset',
                        enabled: MyApp.textScaleFactor.value != 1.0,
                        child: Row(
                          children: [
                            const Icon(Icons.restart_alt, size: 20, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(t("Reset to Default")),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.translate, color: Colors.white),
                  onSelected: (String lang) {
                    LanguageService.currentLanguage.lang = lang;
                  },
                  itemBuilder: (BuildContext context) {
                    return ['English', 'Tamil'].map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice,
                          style: TextStyle(
                            fontWeight: LanguageService.currentLanguage.lang == choice
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            drawer: Drawer(
              elevation: 16,
              child: Container(
                color: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                      color: AppTheme.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/slidebar.png',
                              height: 68,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              MemberAvatar(
                                name: user?.fullName ?? "",
                                radius: 24,
                                profileImage: user?.profileImage,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isVisitor 
                                          ? (user?.companyName ?? "") 
                                          : (user?.powerTeam ?? ""),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          if (!_isVisitor) ...[
                            _buildDrawerItem(
                              icon: Icons.handshake_outlined,
                              title: "Face to Face Form",
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FaceToFaceFormScreen()),
                                );
                              },
                            ),
                            _buildDrawerItem(
                              icon: Icons.person_add_alt_1_outlined,
                              title: "Visitor Form",
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const VisitorFormScreen()),
                                );
                              },
                            ),
                            _buildDrawerItem(
                              icon: Icons.gavel_outlined,
                              title: "Attendance By-Law",
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AttendanceByLawScreen()),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onLogout();
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: Text(
                            t("Logout"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: FadeIndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_outlined, Icons.home, "Home"),
                      _buildNavItem(1, Icons.people_outline, Icons.people, "Directory"),
                      if (!_isVisitor) ...[
                        _buildNavItem(2, Icons.handshake_outlined, Icons.handshake, "REF / Thanks"),
                        _buildNavItem(3, Icons.person_outline, Icons.person, "Profile"),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.secondary, size: 20),
        title: Text(
          t(title),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected ? AppTheme.orangeGradient : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.secondary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                child: Center(
                  child: Icon(
                    isSelected ? solidIcon : outlineIcon,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t(label),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeIndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(children.length, (idx) {
        final isSelected = idx == index;
        return TickerMode(
          enabled: isSelected,
          child: Offstage(
            offstage: !isSelected,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: duration,
              curve: Curves.easeInOut,
              child: children[idx],
            ),
          ),
        );
      }),
    );
  }
}
