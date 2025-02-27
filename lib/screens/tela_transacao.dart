import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../utils/database_helper.dart';
import 'tela_gerenciar_categorias.dart';
import '../utils/theme_manager.dart';
import '../utils/notification_service.dart';
import '../utils/error_logger.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  final double currentBalance;

  AddTransactionScreen({this.transaction, required this.currentBalance});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late MoneyMaskedTextController _amountController;
  late TextEditingController _customCategoryController;
  late TextEditingController _installmentsController;
  late TextEditingController _categoryController;
  late ValueNotifier<String?> _categoryNotifier;
  DateTime? _selectedDate;
  bool _isIncome = true;
  bool _isRecurring = false;
  String? _frequency;
  String _currency = 'BRL';
  String? _titleError;
  String? _amountError;
  String? _installmentsError;
  List<Map<String, dynamic>> _installments = [];
  final List<String> _frequencies = ['Diário', 'Semanal', 'Mensal', 'Anual'];
  final List<String> _incomeCategories = ['Salário', 'Freelance', 'Investimentos', 'Presentes', 'Reembolsos'];
  final List<String> _expenseCategories = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Vestuário',
    'Contas',
    'Impostos',
    'Outros'
  ];
  List<String> _customIncomeCategories = [];
  List<String> _customExpenseCategories = [];
  final Map<String, double> _categoryLimits = {
    'Alimentação': 5000.0,
    'Transporte': 2000.0,
    'Moradia': 10000.0,
    'Saúde': 3000.0,
    'Educação': 5000.0,
    'Lazer': 2000.0,
    'Vestuário': 1500.0,
    'Contas': 3000.0,
    'Impostos': 5000.0,
    'Outros': 10000.0,
    'Salário': 20000.0,
    'Freelance': 10000.0,
    'Investimentos': 50000.0,
    'Presentes': 1000.0,
    'Reembolsos': 5000.0,
  };
  final Map<String, String> _categorySuggestions = {
    'supermercado': 'Alimentação',
    'mercado': 'Alimentação',
    'restaurante': 'Alimentação',
    'uber': 'Transporte',
    'gasolina': 'Transporte',
    'onibus': 'Transporte',
    'aluguel': 'Moradia',
    'agua': 'Moradia',
    'luz': 'Moradia',
    ' medico': 'Saúde',
    'remedio': 'Saúde',
    'escola': 'Educação',
    'curso': 'Educação',
    'cinema': 'Lazer',
    'viagem': 'Lazer',
    'roupa': 'Vestuário',
    'telefone': 'Contas',
    'internet': 'Contas',
    'salario': 'Salário',
    'freela': 'Freelance',
    'investimento': 'Investimentos',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction?['title'] ?? '');
    _amountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: '',
      initialValue: widget.transaction?['amount']?.toDouble().abs() ?? 0.0,
    );
    _customCategoryController = TextEditingController();
    _installmentsController = TextEditingController(text: '1');
    _categoryController = TextEditingController();

    _selectedDate = widget.transaction?['date'] != null
        ? DateTime.parse(widget.transaction!['date'])
        : DateTime.now();
    _isIncome = widget.transaction?['type'] == 1 ?? true;
    _isRecurring = widget.transaction?['isRecurring'] == 1 ?? false;
    _frequency = widget.transaction?['frequency'] ?? (_isRecurring ? 'Mensal' : null);

    _categoryNotifier = ValueNotifier<String?>(
      widget.transaction != null && widget.transaction!['category'] != null
          ? widget.transaction!['category']
          : (_isIncome ? _incomeCategories[0] : _expenseCategories[0]),
    );
    _categoryController.text = _categoryNotifier.value!;

    _titleController.addListener(_updateTitle);
    _amountController.addListener(_updateAmount);
    _installmentsController.addListener(_updateInstallments);

    _loadCustomCategories();
    _loadPreferences();
  }

  void _updateTitle() {
    setState(() {
      _titleError = _validateTitle(_titleController.text);
      _suggestCategory();
    });
  }

  void _updateAmount() {
    setState(() {
      _amountError = _validateAmount(_amountController.text);
    });
  }

  void _updateInstallments() {
    setState(() {
      _installmentsError = _validateInstallments(_installmentsController.text);
      final count = int.tryParse(_installmentsController.text) ?? 1;
      _installments = List.generate(
        count,
            (index) => {
          'amount': _amountController.numberValue / count,
          'date': _selectedDate!.add(Duration(days: index * 30)),
        },
      );
    });
  }

  Future<void> _loadPreferences() async {
    try {
      _currency = await ThemeManager.instance.getCurrencyPreference();
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar preferências: $e', stackTrace);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar moeda')));
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      final customCats = await DatabaseHelper.instance.getCustomCategoriesWithCounts();
      if (mounted) {
        setState(() {
          _customIncomeCategories = customCats
              .where((cat) => cat['type'] == 1)
              .map((cat) => cat['name'] as String)
              .toList();
          _customExpenseCategories = customCats
              .where((cat) => cat['type'] == -1)
              .map((cat) => cat['name'] as String)
              .toList();
        });
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar categorias personalizadas: $e', stackTrace);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar categorias')));
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateTitle);
    _amountController.removeListener(_updateAmount);
    _installmentsController.removeListener(_updateInstallments);

    _titleController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    _installmentsController.dispose();
    _categoryController.dispose();
    _categoryNotifier.dispose();
    super.dispose();
  }

  void _suggestCategory() {
    final title = _titleController.text.toLowerCase();
    final currentCategories = _isIncome ? _incomeCategories : _expenseCategories;
    for (var keyword in _categorySuggestions.keys) {
      if (title.contains(keyword) && currentCategories.contains(_categorySuggestions[keyword])) {
        _categoryNotifier.value = _categorySuggestions[keyword];
        _categoryController.text = _categoryNotifier.value!;
        break;
      }
    }
  }

  Future<bool> _confirmHighValue(double totalAmount) async {
    if (totalAmount.abs() > 10000) {
      try {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirmar Valor Alto'),
            content: Text('O valor ${_formatCurrency(totalAmount)} é elevado. Deseja confirmar?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Confirmar')),
            ],
          ),
        );
        return confirm ?? false;
      } catch (e, stackTrace) {
        ErrorLogger.logError('Erro ao confirmar valor alto: $e', stackTrace);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao confirmar valor')));
        return false;
      }
    }
    return true;
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate() && _titleError == null && _amountError == null && _installmentsError == null) {
      try {
        final title = _titleController.text.isEmpty ? _categoryNotifier.value! : _titleController.text;
        final totalAmount = _amountController.numberValue * (_isIncome ? 1 : -1);
        final type = _isIncome ? 1 : -1;
        final category = _categoryNotifier.value!;
        final installmentsCount = int.tryParse(_installmentsController.text) ?? 1;
        if (!await _confirmHighValue(totalAmount)) return;

        final db = await DatabaseHelper.instance.database;
        final columns = await db.rawQuery('PRAGMA table_info(transactions)');
        final hasInstallments = columns.any((col) => col['name'] == 'installments');

        if (widget.transaction != null) {
          await DatabaseHelper.instance.updateTransaction(
            widget.transaction!['id'],
            title,
            totalAmount,
            _selectedDate!.toIso8601String(),
            type,
            category,
            isRecurring: _isRecurring ? 1 : 0,
            frequency: _isRecurring ? _frequency : null,
            installments: hasInstallments ? installmentsCount : null,
          );
        } else {
          if (installmentsCount > 1) {
            for (int i = 0; i < _installments.length; i++) {
              final installment = _installments[i];
              final amountPerInstallment = installment['amount'] * (_isIncome ? 1 : -1);
              final installmentDate = (installment['date'] as DateTime).toIso8601String();
              await DatabaseHelper.instance.addTransaction(
                '$title (Parcela ${i + 1}/$installmentsCount)',
                amountPerInstallment,
                installmentDate,
                type,
                category,
                isRecurring: _isRecurring ? 1 : 0,
                frequency: _isRecurring ? _frequency : null,
                installments: hasInstallments ? installmentsCount : null,
              );
              // Correção da chamada ao scheduleRecurringNotification
              if (_isRecurring && i == 0 && _frequency != null) {
                await NotificationService.scheduleRecurringNotification(
                  flutterLocalNotificationsPlugin as int, // Objeto de notificação
                  (DateTime.now().millisecondsSinceEpoch % 100000) as String, // ID como int
                  title as double, // Título como String
                  amountPerInstallment, // Valor como double
                  _frequency! as DateTime, // Frequência como String
                  DateTime.parse(installmentDate) as BuildContext, // Data como DateTime
                );
              }
            }
          } else {
            await DatabaseHelper.instance.addTransaction(
              title,
              totalAmount,
              _selectedDate!.toIso8601String(),
              type,
              category,
              isRecurring: _isRecurring ? 1 : 0,
              frequency: _isRecurring ? _frequency : null,
              installments: hasInstallments ? installmentsCount : null,
            );
            if (_isRecurring && _frequency != null) {
              await NotificationService.scheduleRecurringNotification(
                flutterLocalNotificationsPlugin as int,
                (DateTime.now().millisecondsSinceEpoch % 100000) as String,
                title as double,
                totalAmount as String,
                _frequency! as DateTime,
                _selectedDate! as BuildContext,
              );
            }
          }
        }
        Navigator.pop(context, true);
      } catch (e, stackTrace) {
        ErrorLogger.logError('Erro ao salvar transação: $e', stackTrace);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar transação: $e')));
      }
    }
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR', name: _currency);
    return formatter.format(value);
  }

  double _calculateNewBalance() {
    final totalAmount = _amountController.numberValue * (_isIncome ? 1 : -1);
    final installments = int.tryParse(_installmentsController.text) ?? 1;
    final amountPerInstallment = totalAmount / installments;
    if (widget.transaction != null) {
      final originalAmount = widget.transaction!['amount'] as double;
      return widget.currentBalance - originalAmount + totalAmount;
    } else {
      return widget.currentBalance + (installments > 1 ? amountPerInstallment : totalAmount);
    }
  }

  String? _validateTitle(String? value) {
    if (value != null && value.length > 50) {
      return 'O título não pode ter mais de 50 caracteres.';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Por favor, insira um valor.';
    final amount = _amountController.numberValue;
    if (amount <= 0) return 'Por favor, insira um valor maior que zero.';
    if (amount > 1000000) {
      return 'O valor não pode exceder ${_formatCurrency(1000000)}.';
    }
    if (_categoryNotifier.value != null && _categoryLimits.containsKey(_categoryNotifier.value)) {
      final limit = _categoryLimits[_categoryNotifier.value]!;
      if (amount > limit) {
        return 'O valor excede o limite de ${_formatCurrency(limit)} para ${_categoryNotifier.value}.';
      }
    }
    return null;
  }

  String? _validateInstallments(String? value) {
    if (value == null || value.isEmpty) return 'Por favor, insira o número de parcelas.';
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 1) return 'Por favor, insira um número válido (>= 1).';
    if (intValue > 36) return 'O número de parcelas não pode exceder 36.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    final totalAmount = _amountController.numberValue * (_isIncome ? 1 : -1);
    final installments = int.tryParse(_installmentsController.text) ?? 1;
    final amountPerInstallment = totalAmount / installments;
    final newBalance = _calculateNewBalance();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Transação' : 'Adicionar Transação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título (opcional)',
                    hintText: 'Se vazio, usará a categoria',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    errorText: _titleError,
                  ),
                  onChanged: (value) => _updateTitle(),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    errorText: _amountError,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateAmount(),
                  validator: _validateAmount,
                ),
                if (_amountController.numberValue > 10000) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _installmentsController,
                    decoration: InputDecoration(
                      labelText: 'Número de Parcelas',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      errorText: _installmentsError,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateInstallments(),
                    validator: _validateInstallments,
                  ),
                  SizedBox(height: 16),
                  if (_installments.isNotEmpty)
                    Column(
                      children: _installments.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> installment = entry.value;
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: installment['amount'].toStringAsFixed(2),
                                decoration: InputDecoration(
                                  labelText: 'Valor Parcela ${index + 1}',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _installments[index]['amount'] = double.tryParse(value) ?? installment['amount'];
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: installment['date'],
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _installments[index]['date'] = pickedDate;
                                  });
                                }
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categoryNotifier.value,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        items: (_isIncome
                            ? [..._incomeCategories, ..._customIncomeCategories]
                            : [..._expenseCategories, ..._customExpenseCategories])
                            .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _categoryNotifier.value = value;
                              _categoryController.text = value;
                            });
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Por favor, selecione uma categoria.' : null,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: _addCustomCategory,
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () async {
                        try {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ManageCategoriesScreen()),
                          );
                          await _loadCustomCategories();
                        } catch (e, stackTrace) {
                          ErrorLogger.logError('Erro ao gerenciar categorias: $e', stackTrace);
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Erro ao abrir gerenciador de categorias')));
                          }
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Data'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    try {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate!,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    } catch (e, stackTrace) {
                      ErrorLogger.logError('Erro ao selecionar data: $e', stackTrace);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar data')));
                    }
                  },
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ToggleButtons(
                      children: [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Receita')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Despesa')),
                      ],
                      isSelected: [_isIncome, !_isIncome],
                      onPressed: (index) {
                        setState(() {
                          _isIncome = index == 0;
                          _categoryNotifier.value = _isIncome ? _incomeCategories[0] : _expenseCategories[0];
                          _categoryController.text = _categoryNotifier.value!;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Transação Recorrente'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                      if (!_isRecurring) _frequency = null;
                      if (_isRecurring && _frequency == null) _frequency = 'Mensal';
                    });
                  },
                ),
                if (_isRecurring) ...[
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _frequency,
                    decoration: InputDecoration(
                      labelText: 'Frequência',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    items: _frequencies.map((freq) => DropdownMenuItem(value: freq, child: Text(freq))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _frequency = value;
                      });
                    },
                  ),
                ],
                SizedBox(height: 16),
                Text('Saldo Atual: ${_formatCurrency(widget.currentBalance)}', style: TextStyle(fontSize: 16)),
                Text(
                  'Saldo Após: ${_formatCurrency(newBalance)}',
                  style: TextStyle(fontSize: 16, color: newBalance >= 0 ? Colors.green : Colors.red),
                ),
                if (installments > 1) ...[
                  SizedBox(height: 8),
                  Text(
                    'Valor por Parcela: ${_formatCurrency(amountPerInstallment)} ($installments parcelas)',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTransaction,
        child: Icon(widget.transaction != null ? Icons.check : Icons.save),
      ),
    );
  }

  void _addCustomCategory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Categoria'),
        content: TextField(
          controller: _customCategoryController,
          decoration: InputDecoration(labelText: 'Nome da categoria'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () async {
              try {
                final name = _customCategoryController.text.trim();
                if (name.isNotEmpty) {
                  final success = await DatabaseHelper.instance.addCustomCategory(name, _isIncome ? 1 : -1);
                  if (success) {
                    await _loadCustomCategories();
                    setState(() {
                      _categoryNotifier.value = name;
                      _categoryController.text = name;
                    });
                    _customCategoryController.clear();
                    Navigator.pop(context);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Categoria já existe para este tipo')));
                    }
                  }
                }
              } catch (e, stackTrace) {
                ErrorLogger.logError('Erro ao adicionar categoria personalizada: $e', stackTrace);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar categoria')));
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}