import 'dart:async';
import 'dart:io' show exit; // Para sair do app
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/tela_transacao.dart';
import 'screens/tela_principal.dart';
import 'screens/tela_graficos.dart';
import 'screens/tela_configuracao.dart';
import 'screens/tela_autenticacao_pin.dart';
import 'screens/tela_metas.dart';
import 'utils/auth_manager.dart';
import 'utils/goals_provider.dart';
import 'utils/theme_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/notification_service.dart';
import 'utils/backup_service.dart';
import 'utils/error_logger.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Tema Padrão (Material You - Azul, Claro)
final ThemeData defaultTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
    primary: Colors.blue,
    secondary: Colors.blueAccent,
    surface: Colors.grey[100]!,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: Colors.grey[100],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.blue, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Claro (Material You - Verde)
final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
    primary: Colors.green,
    secondary: Colors.teal,
    surface: Colors.grey[50]!,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: Colors.grey[50],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.green, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Escuro (Material You - Azul Acinzentado)
final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
    brightness: Brightness.dark,
    primary: Colors.blueGrey,
    secondary: Colors.tealAccent,
    surface: Colors.grey[850]!,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white70,
  ),
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.blueGrey, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema AMOLED (Personalizado - Preto com Teal)
final ThemeData amoledTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.tealAccent,
    onPrimary: Colors.white,
    secondary: Colors.teal,
    onSecondary: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white70,
    background: Colors.black,
    onBackground: Colors.white70,
    error: Colors.redAccent,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.tealAccent, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Roxo (Material You - Roxo Claro)
final ThemeData purpleTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.purple,
    brightness: Brightness.light,
    primary: Colors.purple,
    secondary: Colors.purpleAccent,
    surface: Colors.grey[100]!,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: Colors.grey[100],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.purple, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Laranja (Material You - Laranja Escuro)
final ThemeData orangeTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: Brightness.dark,
    primary: Colors.orange,
    secondary: Colors.deepOrangeAccent,
    surface: Colors.grey[850]!,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white70,
  ),
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.orange, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Pastel (Personalizado - Tons Suaves)
final ThemeData pastelTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF80DEEA),
    onPrimary: Colors.black,
    secondary: Color(0xFFFFCCBC),
    onSecondary: Colors.black,
    surface: Color(0xFFF5F5F5),
    onSurface: Colors.black87,
    background: Color(0xFFECEFF1),
    onBackground: Colors.black87,
    error: Colors.redAccent,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Color(0xFFECEFF1),
  appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF80DEEA),
      foregroundColor: Colors.black,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54)),
  buttonTheme: ButtonThemeData(
      buttonColor: Color(0xFF80DEEA), textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Monocromático (Personalizado - Tons de Cinza)
final ThemeData monoTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.grey[400]!,
    onPrimary: Colors.black,
    secondary: Colors.grey[600]!,
    onSecondary: Colors.black,
    surface: Colors.grey[900]!,
    onSurface: Colors.white70,
    background: Colors.grey[800]!,
    onBackground: Colors.white70,
    error: Colors.redAccent,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.grey[800],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white60)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.grey[400], textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Vermelho (Material You - Vermelho Claro)
final ThemeData redTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.light,
    primary: Colors.red,
    secondary: Colors.redAccent,
    surface: Colors.grey[100]!,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: Colors.grey[100],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.red, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

// Tema Amarelo (Material You - Amarelo Claro)
final ThemeData yellowTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.yellow,
    brightness: Brightness.light,
    primary: Colors.yellow,
    secondary: Colors.amber,
    surface: Colors.grey[100]!,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: Colors.grey[100],
  appBarTheme: AppBarTheme(
      backgroundColor: Colors.yellow,
      foregroundColor: Colors.black,
      elevation: 0),
  textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54)),
  buttonTheme: ButtonThemeData(
      buttonColor: Colors.yellow, textTheme: ButtonTextTheme.primary),
  useMaterial3: true,
);

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.logError(details.exception.toString(), details.stack);
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(MyAppInitializer());
}

class MyAppInitializer extends StatefulWidget {
  @override
  _MyAppInitializerState createState() => _MyAppInitializerState();
}

class _MyAppInitializerState extends State<MyAppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final themePreference = await ThemeManager.instance.getThemePreference();
      final isAuthEnabled = await ThemeManager.instance.isAuthEnabled();

      setState(() {
        _isInitialized = true;
      });

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeNotifier(themePreference)),
            ChangeNotifierProvider(create: (_) => ThemeManager.instance),
            ChangeNotifierProvider(create: (_) => GoalsProvider()),
            ChangeNotifierProvider(create: (_) => AuthManager()),
          ],
          child: MyApp(isAuthEnabled: isAuthEnabled),
        ),
      );
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao inicializar o app: $e', stackTrace);
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.grey[200], // Fundo mais suave
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 80,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Oops! Algo deu errado',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Erro ao iniciar o aplicativo:\n$_errorMessage',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isInitialized = false;
                      });
                      _initializeApp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Tentar Novamente',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      exit(0); // Sai do app
                    },
                    child: Text(
                      'Sair do Aplicativo',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Iniciando o aplicativo...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container();
  }
}

class ThemeNotifier extends ChangeNotifier {
  String _themeMode;
  Color? _customPrimaryColor;
  Color? _customSecondaryColor;
  bool _customIsDark;

  ThemeNotifier(this._themeMode)
      : _customPrimaryColor = ThemeManager.instance.getCustomPrimaryColor(),
        _customSecondaryColor = ThemeManager.instance.getCustomSecondaryColor(),
        _customIsDark = ThemeManager.instance.getCustomIsDark() ?? false;

  String get themeMode => _themeMode;
  Color? get customPrimaryColor => _customPrimaryColor;
  Color? get customSecondaryColor => _customSecondaryColor;
  bool get customIsDark => _customIsDark;

  ThemeData get currentTheme {
    switch (_themeMode) {
      case 'system':
        return defaultTheme;
      case 'default':
        return defaultTheme;
      case 'light':
        return lightTheme;
      case 'dark':
        return darkTheme;
      case 'amoled':
        return amoledTheme;
      case 'purple':
        return purpleTheme;
      case 'orange':
        return orangeTheme;
      case 'pastel':
        return pastelTheme;
      case 'mono':
        return monoTheme;
      case 'red':
        return redTheme;
      case 'yellow':
        return yellowTheme;
      case 'custom':
        return ThemeData(
          colorScheme: ColorScheme(
            brightness: _customIsDark ? Brightness.dark : Brightness.light,
            primary: _customPrimaryColor ?? Colors.blue,
            onPrimary: _customIsDark ? Colors.white : Colors.white,
            secondary: _customSecondaryColor ?? Colors.blueAccent,
            onSecondary: _customIsDark ? Colors.white : Colors.black,
            surface: _customIsDark ? Colors.grey[850]! : Colors.grey[100]!,
            onSurface: _customIsDark ? Colors.white70 : Colors.black87,
            background: _customIsDark ? Colors.grey[900]! : Colors.grey[100]!,
            onBackground: _customIsDark ? Colors.white70 : Colors.black87,
            error: Colors.redAccent,
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: _customIsDark ? Colors.grey[900] : Colors.grey[100],
          appBarTheme: AppBarTheme(
            backgroundColor: _customPrimaryColor ?? Colors.blue,
            foregroundColor: _customIsDark ? Colors.white : Colors.white,
            elevation: 0,
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: _customIsDark ? Colors.white70 : Colors.black87),
            bodyMedium: TextStyle(color: _customIsDark ? Colors.white60 : Colors.black54),
          ),
          buttonTheme: ButtonThemeData(
            buttonColor: _customPrimaryColor ?? Colors.blue,
            textTheme: ButtonTextTheme.primary,
          ),
          useMaterial3: true,
        );
      default:
        return defaultTheme;
    }
  }

  void setTheme(String themeMode, {Color? primaryColor, Color? secondaryColor, bool? isDark}) async {
    try {
      _themeMode = themeMode;
      if (themeMode == 'custom') {
        _customPrimaryColor = primaryColor;
        _customSecondaryColor = secondaryColor;
        _customIsDark = isDark ?? false;
        await ThemeManager.instance.setCustomColors(primaryColor, secondaryColor);
        await ThemeManager.instance.setCustomIsDark(isDark ?? false);
      }
      await ThemeManager.instance.setThemePreference(themeMode);
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao definir tema: $e', stackTrace);
    }
  }
}

class AuthScreen extends StatefulWidget {
  final Widget child;

  const AuthScreen({required this.child});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        _authenticate();
      }
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    final authManager = Provider.of<AuthManager>(context, listen: false);
    if (authManager.isAuthenticated) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        authManager.setAuthenticated(true);
        setState(() => _isAuthenticating = false);
        return;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar o aplicativo',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );

      if (mounted) {
        authManager.setAuthenticated(authenticated);
        setState(() {
          _isAuthenticating = false;
          _errorMessage = authenticated ? null : 'Autenticação falhou';
        });
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro na autenticação: $e', stackTrace);
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Erro ao autenticar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = Provider.of<AuthManager>(context);

    if (authManager.isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Autenticação Necessária',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            if (_isAuthenticating)
              CircularProgressIndicator()
            else if (_errorMessage == null)
              Text(
                'Preparando autenticação...',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: _authenticate,
                  child: Text('Tentar Novamente'),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isAuthEnabled;

  const MyApp({required this.isAuthEnabled});

  Future<void> _initializeNotifications() async {
    await NotificationService.initialize();
  }

  Future<void> _initializeBackupService() async {
    await initializeBackupService();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final authManager = Provider.of<AuthManager>(context);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ThemeData theme;
        if (themeNotifier.themeMode == 'system') {
          final brightness = MediaQuery.of(context).platformBrightness;
          final isDarkMode = brightness == Brightness.dark;
          theme = ThemeData(
            colorScheme: isDarkMode
                ? (darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark))
                : (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light)),
            scaffoldBackgroundColor: isDarkMode ? (darkDynamic?.background ?? Colors.grey[900]) : (lightDynamic?.background ?? Colors.grey[100]),
            appBarTheme: AppBarTheme(
              backgroundColor: isDarkMode ? (darkDynamic?.primary ?? Colors.blueGrey) : (lightDynamic?.primary ?? Colors.blue),
              foregroundColor: isDarkMode ? Colors.white : Colors.white,
              elevation: 0,
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                  color: isDarkMode ? (darkDynamic?.onSurface ?? Colors.white70) : (lightDynamic?.onSurface ?? Colors.black87)),
              bodyMedium: TextStyle(
                  color: isDarkMode
                      ? (darkDynamic?.onSurface?.withOpacity(0.6) ?? Colors.white60)
                      : (lightDynamic?.onSurface?.withOpacity(0.6) ?? Colors.black54)),
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: isDarkMode ? (darkDynamic?.primary ?? Colors.blueGrey) : (lightDynamic?.primary ?? Colors.blue),
              textTheme: ButtonTextTheme.primary,
            ),
            useMaterial3: true,
          );
        } else {
          theme = themeNotifier.currentTheme;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Consumer<AuthManager>(
            builder: (context, authManager, child) {
              if (!isAuthEnabled || authManager.isAuthenticated) {
                if (themeNotifier.themeMode.contains('custom')) {
                  _initializeNotifications();
                  _initializeBackupService();
                }
                return HomeScreen();
              }
              return FutureBuilder<Map<String, bool>>(
                future: SharedPreferences.getInstance().then((prefs) => {
                  'usePinAuth': prefs.getBool('usePinAuth') ?? false,
                  'useNativeAuth': prefs.getBool('useNativeAuth') ?? false,
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  final usePinAuth = snapshot.data?['usePinAuth'] ?? false;
                  final useNativeAuth = snapshot.data?['useNativeAuth'] ?? false;

                  if (usePinAuth) {
                    return PinAuthScreen(child: HomeScreen());
                  } else if (useNativeAuth) {
                    return AuthScreen(child: HomeScreen());
                  } else {
                    return HomeScreen();
                  }
                },
              );
            },
          ),
          routes: {
            '/add-transaction': (context) => AddTransactionScreen(currentBalance: 0),
            '/reports': (context) => ReportsScreen(),
            '/settings': (context) => SettingsScreen(),
            '/goals': (context) => GoalsScreen(),
          },
        );
      },
    );
  }
}
