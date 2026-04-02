import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/messenger_service.dart';
import 'screens/chat_list_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final svc = MessengerService();
  await svc.init();

  runApp(
    ChangeNotifierProvider.value(
      value: svc,
      child: const PrivMsgApp(),
    ),
  );
}

class PrivMsgApp extends StatelessWidget {
  const PrivMsgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrivMsg',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Splash(),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pushReplacement(context, _fadeRoute(const ChatListScreen()));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                    color: AppTheme.accent.withOpacity(0.4),
                    blurRadius: 30, spreadRadius: 0, offset: const Offset(0, 8),
                  )],
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 46),
              ),
              const SizedBox(height: 20),
              const Text('PrivMsg', style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary, letterSpacing: -1,
              )),
              const SizedBox(height: 6),
              const Text('Anonim · Shifrlangan · Serversiz', style: TextStyle(
                fontSize: 13, color: AppTheme.textHint, letterSpacing: 0.3,
              )),
            ]),
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  );
}
