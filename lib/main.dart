import 'package:flutter/material.dart';
import 'routes.dart';
import 'features/bfbank/data/services/global_tts_manager.dart';
import 'features/bfbank/data/services/dev_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 개발 환경 설정 정보 출력
  DevConfig.printDevInfo();
  
  // 앱 시작 시 전역 TTS 매니저 초기화
  await GlobalTtsManager().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.detached:
        // 앱이 완전히 종료될 때만 GlobalTtsManager 정리
        GlobalTtsManager().dispose();
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 가면 TTS 일시 정지
        GlobalTtsManager().pause();
        break;
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아와도 TTS는 자동으로 재개되지 않음
        // 사용자가 명시적으로 TTS를 요청해야 함
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BFBANK',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
