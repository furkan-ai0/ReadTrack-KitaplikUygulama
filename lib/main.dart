import 'package:flutter/material.dart';
import 'screens/giris_ekrani.dart';

// --- GLOBAL TEMA YÖNETİCİSİ ---
// Uygulama genelinde karanlık/aydınlık mod geçişini anlık olarak sağlar
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kitaplığım',
          theme: ThemeData(
            primarySwatch: Colors.grey,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.grey,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: currentMode,
          // Uygulama açılış ekranımız
          home: const GirisEkrani(),
        );
      },
    );
  }
}