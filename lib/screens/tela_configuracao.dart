import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/auth_manager.dart';
import 'tela_log_erro.dart';
import '../utils/backup_service.dart';
import '../utils/database_helper.dart';
import '../utils/theme_manager.dart';
import '../utils/error_logger.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeNotifier _themeNotifier;
  String _currency = 'BRL';
  bool _autoBackupEnabled = false;
  bool _useNativeAuth = false;
  bool _usePinAuth = false;
  String? _currentPin; // Armazena o PIN atual
  final LocalAuthentication _localAuth = LocalAuthentication();
  final List<String> _currencies = ['BRL', 'USD', 'EUR'];

  String _backupFrequency = 'Semanal';
  String _backupDestination = 'Local';
  final List<String> _backupFrequencies = ['Diário', 'Semanal', 'Mensal'];
  final List<String> _backupDestinations = ['Local', 'Google Drive'];

  @override
  void initState() {
    super.initState();
    _themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    _loadCurrencyPreference();
    _loadAuthPreferences();
    _loadBackupPreferences();
  }

  Future<void> _loadCurrencyPreference() async {
    try {
      final currency = await ThemeManager.instance.getCurrencyPreference();
      setState(() {
        _currency = currency;
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar moeda: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar moeda')));
    }
  }

  Future<void> _loadBackupPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _backupFrequency = prefs.getString('backupFrequency') ?? 'Semanal';
        _backupDestination = prefs.getString('backupDestination') ?? 'Local';
        _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar preferências de backup: $e', stackTrace);
    }
  }

  Future<void> _loadAuthPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _useNativeAuth = prefs.getBool('useNativeAuth') ?? false;
        _usePinAuth = prefs.getBool('usePinAuth') ?? false;
        _currentPin = prefs.getString('pinCode');
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar preferências de autenticação: $e', stackTrace);
    }
  }

  Future<void> _savePin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pinCode', newPin);
    setState(() {
      _currentPin = newPin;
    });
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedTheme = _themeNotifier.themeMode;
        Color primaryColor = _themeNotifier.customPrimaryColor ?? Colors.blue;
        Color secondaryColor =
            _themeNotifier.customSecondaryColor ?? Colors.blueAccent;
        bool isDark = _themeNotifier.customIsDark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Selecionar Tema'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedTheme,
                      items: [
                        DropdownMenuItem(value: 'system', child: Text('Sistema')),
                        DropdownMenuItem(value: 'default', child: Text('Padrão')),
                        DropdownMenuItem(value: 'light', child: Text('Claro')),
                        DropdownMenuItem(value: 'dark', child: Text('Escuro')),
                        DropdownMenuItem(value: 'amoled', child: Text('AMOLED')),
                        DropdownMenuItem(value: 'purple', child: Text('Roxo')),
                        DropdownMenuItem(value: 'orange', child: Text('Laranja')),
                        DropdownMenuItem(value: 'pastel', child: Text('Pastel')),
                        DropdownMenuItem(value: 'mono', child: Text('Monocromático')),
                        DropdownMenuItem(value: 'red', child: Text('Vermelho')),
                        DropdownMenuItem(value: 'yellow', child: Text('Amarelo')),
                        DropdownMenuItem(value: 'custom', child: Text('Personalizado')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTheme = value!;
                        });
                      },
                    ),
                    if (selectedTheme == 'custom') ...[
                      SizedBox(height: 16),
                      Text('Cor Primária'),
                      ColorPicker(
                        pickerColor: primaryColor,
                        onColorChanged: (color) {
                          setDialogState(() {
                            primaryColor = color;
                          });
                        },
                        showLabel: false,
                        enableAlpha: false,
                        pickerAreaHeightPercent: 0.5,
                      ),
                      SizedBox(height: 16),
                      Text('Cor Secundária'),
                      ColorPicker(
                        pickerColor: secondaryColor,
                        onColorChanged: (color) {
                          setDialogState(() {
                            secondaryColor = color;
                          });
                        },
                        showLabel: false,
                        enableAlpha: false,
                        pickerAreaHeightPercent: 0.5,
                      ),
                      SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('Modo Escuro'),
                        value: isDark,
                        onChanged: (value) {
                          setDialogState(() {
                            isDark = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    _themeNotifier.setTheme(
                      selectedTheme,
                      primaryColor: selectedTheme == 'custom' ? primaryColor : null,
                      secondaryColor:
                      selectedTheme == 'custom' ? secondaryColor : null,
                      isDark: selectedTheme == 'custom' ? isDark : null,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportDatabase() async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Exportar Banco de Dados'),
          content: Text('Deseja exportar o banco de dados para um arquivo?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Exportar')),
          ],
        ),
      );

      if (confirm ?? false) {
        final dbBytes = await File(dbPath).readAsBytes();
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar backup do banco de dados',
          fileName: 'financa_backup_${DateTime.now().toIso8601String()}.db',
          bytes: dbBytes,
          type: FileType.any,
        );
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Backup salvo em: $result')));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Exportação cancelada')));
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao exportar banco de dados: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao exportar banco: $e')));
    }
  }

  Future<void> _importDatabase() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Importar Banco de Dados'),
          content: Text(
              'Isso substituirá o banco de dados atual. Deseja continuar?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Importar')),
          ],
        ),
      );

      if (confirm ?? false) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: 'Selecione o arquivo de backup',
        );
        if (result != null && result.files.single.path != null) {
          final newDbPath = result.files.single.path!;
          final dbPath = await DatabaseHelper.instance.getDatabasePath();
          await DatabaseHelper.instance.close();
          await File(newDbPath).copy(dbPath);
          await DatabaseHelper.instance.database;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Banco de dados importado com sucesso')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Importação cancelada')));
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao importar banco de dados: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao importar banco: $e')));
    }
  }

  Future<void> _clearOldTransactions() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Limpar Transações Antigas'),
          content: Text(
              'Deseja excluir todas as transações com mais de 1 ano? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Excluir')),
          ],
        ),
      );
      if (confirm ?? false) {
        await DatabaseHelper.instance.deleteOldTransactions();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transações antigas excluídas')));
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao limpar transações antigas: $e', stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar transações')));
    }
  }

  Future<void> _changePin() async {
    TextEditingController currentPinController = TextEditingController();
    TextEditingController newPinController = TextEditingController();
    TextEditingController confirmPinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alterar PIN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentPin != null) ...[
                TextField(
                  controller: currentPinController,
                  decoration: InputDecoration(labelText: 'PIN Atual'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                ),
              ],
              TextField(
                controller: newPinController,
                decoration: InputDecoration(labelText: 'Novo PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
              TextField(
                controller: confirmPinController,
                decoration: InputDecoration(labelText: 'Confirmar Novo PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final currentPin = currentPinController.text;
              final newPin = newPinController.text;
              final confirmPin = confirmPinController.text;

              if (_currentPin != null && currentPin != _currentPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PIN atual incorreto')));
                return;
              }
              if (newPin.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('O PIN deve ter 6 dígitos')));
                return;
              }
              if (newPin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Os PINs não coincidem')));
                return;
              }

              await _savePin(newPin);
              Navigator.pop(context, true);
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('PIN alterado com sucesso')));
    }
  }

  Future<bool> _verifyPin(String message) async {
    if (_currentPin == null) return true;

    TextEditingController pinController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Digite o PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            TextField(
              controller: pinController,
              decoration: InputDecoration(labelText: 'PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text == _currentPin) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PIN incorreto')));
              }
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _toggleNativeAuth(bool value) async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Autenticação nativa não disponível neste dispositivo')));
        return;
      }

      if (value && !_useNativeAuth) {
        bool authenticated = false;
        try {
          authenticated = await _localAuth.authenticate(
            localizedReason: 'Confirme sua identidade para ativar a autenticação nativa',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: false,
              useErrorDialogs: true,
            ),
          );
        } catch (e, stackTrace) {
          ErrorLogger.logError('Erro na autenticação nativa: $e', stackTrace);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao autenticar: $e')));
          return;
        }

        if (authenticated) {
          setState(() {
            _useNativeAuth = true;
            _usePinAuth = false;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('useNativeAuth', true);
          await prefs.setBool('usePinAuth', false);
          await ThemeManager.instance.setAuthEnabled(true);
          Provider.of<AuthManager>(context, listen: false).setAuthenticated(true); // Mantém autenticado
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Autenticação não concluída')));
        }
      } else if (!value) {
        setState(() => _useNativeAuth = false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('useNativeAuth', false);
        if (!_usePinAuth) {
          await ThemeManager.instance.setAuthEnabled(false);
          Provider.of<AuthManager>(context, listen: false).setAuthenticated(false); // Reseta apenas se necessário
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao alternar autenticação nativa: $e', stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao configurar autenticação')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('Tema'),
            subtitle: Text(
                'Atual: ${_themeNotifier.themeMode == 'system' ? 'Sistema' : _themeNotifier.themeMode}'),
            onTap: _showThemeDialog,
          ),
          ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('Moeda'),
            trailing: DropdownButton<String>(
              value: _currency,
              items: _currencies
                  .map((currency) =>
                  DropdownMenuItem(value: currency, child: Text(currency)))
                  .toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    _currency = value;
                  });
                  await ThemeManager.instance.setCurrencyPreference(value);
                }
              },
            ),
          ),
          ExpansionTile(
            title: Text('Backup Automático'),
            leading: Icon(Icons.backup),
            children: [
              SwitchListTile(
                title: Text('Ativar Backup Automático'),
                value: _autoBackupEnabled,
                onChanged: (value) async {
                  setState(() {
                    _autoBackupEnabled = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('autoBackupEnabled', value);
                  initializeBackupService();
                },
              ),
              ListTile(
                title: Text('Frequência do Backup'),
                trailing: DropdownButton<String>(
                  value: _backupFrequency,
                  items: _backupFrequencies
                      .map((freq) => DropdownMenuItem(
                    value: freq,
                    child: Text(freq),
                  ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _backupFrequency = value;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('backupFrequency', value);
                      if (_autoBackupEnabled) {
                        initializeBackupService();
                      }
                    }
                  },
                ),
              ),
              ListTile(
                title: Text('Destino do Backup'),
                trailing: DropdownButton<String>(
                  value: _backupDestination,
                  items: _backupDestinations
                      .map((dest) => DropdownMenuItem(
                    value: dest,
                    child: Text(dest),
                  ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _backupDestination = value;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('backupDestination', value);
                      // TODO: Implementar lógica para mudar o destino (ex.: Google Drive)
                    }
                  },
                ),
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.fingerprint),
            title: Text('Autenticação Nativa'),
            subtitle: Text('Usar biometria ou PIN do dispositivo'),
            trailing: Switch(
              value: _useNativeAuth,
              onChanged: (value) => _toggleNativeAuth(value),
            ),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Autenticação por PIN'),
            subtitle: Text('Usar PIN interno de 6 dígitos'),
            trailing: Switch(
              value: _usePinAuth,
              onChanged: (value) async {
                if (value) {
                  await _changePin();
                  if (_currentPin != null) {
                    setState(() {
                      _usePinAuth = true;
                      _useNativeAuth = false;
                    });
                    ThemeManager.instance.setAuthEnabled(true);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('usePinAuth', true);
                    await prefs.setBool('useNativeAuth', false);
                  }
                } else {
                  final confirmed =
                  await _verifyPin('Digite o PIN atual para desativar');
                  if (confirmed) {
                    setState(() {
                      _usePinAuth = false;
                    });
                    ThemeManager.instance.setAuthEnabled(false);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('usePinAuth', false);
                  }
                }
              },
            ),
          ),
          if (_usePinAuth)
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Alterar PIN'),
              onTap: _changePin,
            ),
          ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('Exportar Banco de Dados'),
            onTap: _exportDatabase,
          ),
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Importar Banco de Dados'),
            onTap: _importDatabase,
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep),
            title: Text('Limpar Transações Antigas'),
            subtitle: Text('Excluir transações com mais de 1 ano'),
            onTap: _clearOldTransactions,
          ),
          ListTile(
            leading: Icon(Icons.bug_report),
            title: Text('Visualizar Logs de Erro'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => ErrorLogScreen())),
          ),
        ],
      ),
    );
  }
}