import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/bindings/initial_binding.dart';
import 'app/controllers/settings_controller.dart';
import 'app/theme/app_colors.dart';
import 'app/ui/pages/chat_page.dart';

final Color kBackground = const Color(0xFFF7F8FA);
final Color kAccent = const Color(0xFF4F8CFF);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.put(SettingsController());
    return Obx(() {
      final mode = settings.themeMode.value;
      return GetMaterialApp(
        title: 'AI Assistent - Coderok',
        debugShowCheckedModeBanner: false,
        initialBinding: InitialBinding(),
        getPages: AppPages.pages,
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'SF Pro',
          scaffoldBackgroundColor: AppColors.lightBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.lightAccent,
            background: AppColors.lightBackground,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.lightAppBar,
            elevation: 0,
            foregroundColor: AppColors.lightText,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              borderSide: BorderSide(color: AppColors.lightBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              borderSide: BorderSide(color: AppColors.lightBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              borderSide: BorderSide(color: AppColors.lightBorderFocused, width: 1.2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightAccent,
              shape: const StadiumBorder(),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'SF Pro',
          scaffoldBackgroundColor: AppColors.darkBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.darkAccent,
            background: AppColors.darkBackground,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.darkAppBar,
            elevation: 0,
            foregroundColor: AppColors.darkText,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: AppColors.darkUserBubble,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              borderSide: BorderSide(color: AppColors.darkBorderFocused, width: 1.2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkAccent,
              shape: const StadiumBorder(),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
        themeMode: mode == 'light'
            ? ThemeMode.light
            : mode == 'dark'
                ? ThemeMode.dark
                : ThemeMode.system,
        home: const SplashScreen(),
      );
    });
  }
}

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!_navigated) {
        _navigated = true;
        Get.offAll(() => const ChatPage());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/main.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'AI Assistent - Coderok',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
