import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const GanoAppMobile(),
    ),
  );
}

class GanoAppMobile extends StatelessWidget {
  const GanoAppMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'Gano App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(appState.currentTheme),
          home: const HomeScreen(),
        );
      },
    );
  }
}
