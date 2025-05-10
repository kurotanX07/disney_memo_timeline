import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/memo_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Disney Memo Timeline',
            theme: themeProvider.theme,
            home: const MapScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
