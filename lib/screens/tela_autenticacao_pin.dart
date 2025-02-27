import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/error_logger.dart';

class PinAuthScreen extends StatefulWidget {
  final Widget child;

  const PinAuthScreen({required this.child});

  @override
  _PinAuthScreenState createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
    _pinController.addListener(
        _validatePin); // Adiciona listener para validar automaticamente
  }

  @override
  void dispose() {
    _pinController.removeListener(_validatePin); // Remove listener ao descartar
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString('appPin');
      if (storedPin == null) {
        setState(() => _isAuthenticated = true);
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao verificar PIN armazenado: $e', stackTrace);
      setState(() => _isAuthenticated = false);
    }
  }

  void _validatePin() {
    if (_pinController.text.length == 6) {
      _authenticatePin();
    }
  }

  Future<void> _authenticatePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString('appPin');
      if (_pinController.text == storedPin) {
        setState(() => _isAuthenticated = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN incorreto')),
        );
        _pinController.clear();
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao autenticar PIN: $e', stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao autenticar PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticated
        ? widget.child
        : Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Digite o PIN',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _pinController,
                        decoration: InputDecoration(
                          hintText: '------',
                          border: OutlineInputBorder(),
                          counterText: '', // Remove o contador de caracteres
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, letterSpacing: 4),
                        autofocus: true, // Foco automático ao abrir
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
