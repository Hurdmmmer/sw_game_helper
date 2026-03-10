import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/frb_generated.dart';
import 'package:sw_game_helper/platforms/windows/third_sdk/scrcpy_rust_third_party_api.dart';
import 'package:sw_game_helper/platforms/windows/ui/screens/home_page.dart';
import 'package:sw_game_helper/platforms/windows/ui/window/window_util.dart';
import 'package:sw_game_helper/style/app_theme.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

Future<void> main() async {
  // 1) Flutter 框架初始化必须最先完成。
  WidgetsFlutterBinding.ensureInitialized();

  // 2) 全局日志初始化。
  Log.init(level: Level.debug);

  // 3) Windows 窗口初始化（融合标题栏方案）。
  await WindowUtil.initializeMainWindow(title: 'SW Game Helper');
  // 4) 启动后显式设置为可缩放，避免历史窗口状态残留。
  await WindowUtil.setResizable(true);

  // 5) 原生 Rust 模块初始化。
  try {
    await RustLib.init();
    await ScrcpyRustThirdPartyApi.instance.initLogger();
  } catch (e, st) {
    Log.e('App bootstrap failed: $e', e, st);
  }

  runApp(const ProviderScope(child: SwHelper()));
}

class SwHelper extends ConsumerStatefulWidget {
  const SwHelper({super.key});

  @override
  ConsumerState<SwHelper> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<SwHelper> {
  // 默认亮色，符合当前产品视觉方向。
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SW Game Helper',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HomePage(onThemeToggle: _toggleTheme),
    );
  }
}
