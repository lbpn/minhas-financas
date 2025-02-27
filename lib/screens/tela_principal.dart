import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../utils/goals_provider.dart';
import 'tela_transacao.dart';
import 'tela_configuracao.dart';
import 'tela_metas.dart';
import '../utils/theme_manager.dart';
import '../utils/error_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceSummary extends StatefulWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final int filterType;

  const BalanceSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.filterType,
  });

  @override
  _BalanceSummaryState createState() => _BalanceSummaryState();
}

class _BalanceSummaryState extends State<BalanceSummary> {
  bool _isExpanded = false;

  String _formatCurrency(double value) {
    final currency = Provider.of<ThemeManager>(context, listen: false).getCurrencyPreferenceSync();
    return NumberFormat.simpleCurrency(locale: 'pt_BR', name: currency).format(value);
  }

  @override
  Widget build(BuildContext context) {
    String label;
    double value;
    Color color;

    switch (widget.filterType) {
      case 1:
        label = 'Receita';
        value = widget.totalIncome;
        color = Colors.green;
        break;
      case -1:
        label = 'Despesa';
        value = widget.totalExpense;
        color = Colors.red;
        break;
      case 0:
      default:
        label = 'Saldo';
        value = widget.totalBalance;
        color = widget.totalBalance >= 0 ? Colors.green : Colors.red;
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4.0, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$label: ${_formatCurrency(value)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
            if (_isExpanded) ...[
              SizedBox(height: 16),
              Text('Receita: ${_formatCurrency(widget.totalIncome)}', style: TextStyle(color: Colors.green)),
              SizedBox(height: 8),
              Text('Despesa: ${_formatCurrency(widget.totalExpense)}', style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
              Text(
                'Saldo: ${_formatCurrency(widget.totalBalance)}',
                style: TextStyle(color: widget.totalBalance >= 0 ? Colors.green : Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomDateFilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime, DateTime) onApply;

  const CustomDateFilterDialog({
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
  });

  @override
  _CustomDateFilterDialogState createState() => _CustomDateFilterDialogState();
}

class _CustomDateFilterDialogState extends State<CustomDateFilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filtro Personalizado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Início'),
            onTap: () async {
              try {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _startDate = picked);
              } catch (e, stackTrace) {
                ErrorLogger.logError('Erro ao selecionar data inicial: $e', stackTrace);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar data')));
              }
            },
          ),
          ListTile(
            title: Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Fim'),
            onTap: () async {
              try {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _endDate = picked);
              } catch (e, stackTrace) {
                ErrorLogger.logError('Erro ao selecionar data final: $e', stackTrace);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar data')));
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_startDate != null && _endDate != null) {
              widget.onApply(_startDate!, _endDate!);
              Navigator.pop(context);
            }
          },
          child: Text('Aplicar'),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _filterType = 0;
  String _timeFilter = 'Tudo';
  String _sortOrder = 'Data ↓';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedCategory;
  List<String> _categories = [];
  TextEditingController _searchController = TextEditingController();
  final PagingController<int, Map<String, dynamic>> _pagingController = PagingController(firstPageKey: 0);
  static const int _pageSize = 20;
  bool _isLoading = true;
  late ThemeManager _themeManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeManager = Provider.of<ThemeManager>(context, listen: false);
    _themeManager.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadCategories();
    _searchController.addListener(() {
      _pagingController.refresh();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pagingController.addPageRequestListener((pageKey) {
        _fetchTransactions(pageKey);
      });
      _fetchTransactions(0);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    _themeManager.removeListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _filterType = prefs.getInt('filterType') ?? 0;
          _timeFilter = prefs.getString('timeFilter') ?? 'Tudo';
          _sortOrder = prefs.getString('sortOrder') ?? 'Data ↓';
          _customStartDate = prefs.getString('customStartDate') != null
              ? DateTime.parse(prefs.getString('customStartDate')!)
              : null;
          _customEndDate = prefs.getString('customEndDate') != null
              ? DateTime.parse(prefs.getString('customEndDate')!)
              : null;
          _selectedCategory = prefs.getString('selectedCategory');

          if (!['Tudo', '7 Dias', '30 Dias', 'Personalizado'].contains(_timeFilter)) {
            _timeFilter = 'Tudo';
          }
          if (!['Data ↓', 'Data ↑', 'Valor ↓', 'Valor ↑'].contains(_sortOrder)) {
            _sortOrder = 'Data ↓';
          }
        });
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar filtros: $e', stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('filterType', _filterType);
      await prefs.setString('timeFilter', _timeFilter);
      await prefs.setString('sortOrder', _sortOrder);
      await prefs.setString('customStartDate', _customStartDate?.toIso8601String() ?? '');
      await prefs.setString('customEndDate', _customEndDate?.toIso8601String() ?? '');
      await prefs.setString('selectedCategory', _selectedCategory ?? '');
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao salvar filtros: $e', stackTrace);
    }
  }

  Future<void> _fetchTransactions(int pageKey) async {
    try {
      print('Fetching transactions for pageKey: $pageKey');
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final searchText = _searchController.text.trim().toLowerCase();
      String? whereClause;
      List<dynamic> whereArgs = [];

      if (_filterType != 0) {
        whereClause = 'type = ?';
        whereArgs.add(_filterType);
      }

      if (_timeFilter == '7 Dias') {
        whereClause = whereClause == null ? 'date >= ?' : '$whereClause AND date >= ?';
        whereArgs.add(DateTime.now().subtract(Duration(days: 7)).toIso8601String());
      } else if (_timeFilter == '30 Dias') {
        whereClause = whereClause == null ? 'date >= ?' : '$whereClause AND date >= ?';
        whereArgs.add(DateTime.now().subtract(Duration(days: 30)).toIso8601String());
      } else if (_timeFilter == 'Personalizado' && _customStartDate != null && _customEndDate != null) {
        whereClause = whereClause == null ? 'date BETWEEN ? AND ?' : '$whereClause AND date BETWEEN ? AND ?';
        whereArgs.add(_customStartDate!.toIso8601String());
        whereArgs.add(_customEndDate!.toIso8601String());
      }

      if (_selectedCategory != null) {
        whereClause = whereClause == null ? 'category = ?' : '$whereClause AND category = ?';
        whereArgs.add(_selectedCategory);
      }

      if (searchText.isNotEmpty) {
        whereClause = whereClause == null
            ? '(title LIKE ? OR category LIKE ? OR amount LIKE ? OR date LIKE ?)'
            : '$whereClause AND (title LIKE ? OR category LIKE ? OR amount LIKE ? OR date LIKE ?)';
        whereArgs.addAll(['%$searchText%', '%$searchText%', '%$searchText%', '%$searchText%']);
      }

      String orderBy;
      switch (_sortOrder) {
        case 'Data ↑':
          orderBy = 'date ASC';
          break;
        case 'Valor ↓':
          orderBy = 'amount DESC';
          break;
        case 'Valor ↑':
          orderBy = 'amount ASC';
          break;
        case 'Data ↓':
        default:
          orderBy = 'date DESC';
          break;
      }

      final data = await DatabaseHelper.instance.getTransactions(
        limit: _pageSize,
        offset: pageKey * _pageSize,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );

      print('Fetched ${data.length} transactions');
      final isLastPage = data.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(data);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(data, nextPageKey);
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar transações: $e', stackTrace);
      print('Error fetching transactions: $e');
      _pagingController.error = e;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final customCats = await DatabaseHelper.instance.getCustomCategoriesWithCounts();
      final predefinedIncome = ['Salário', 'Freelance', 'Investimentos', 'Presentes', 'Reembolsos'];
      final predefinedExpense = [
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
      if (mounted) {
        setState(() {
          _categories = [...predefinedIncome, ...predefinedExpense, ...customCats.map((cat) => cat['name'] as String)].toSet().toList();
          if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
            _selectedCategory = null;
          }
        });
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar categorias: $e', stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar categorias')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteTransaction(int id) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Excluir Transação'),
          content: Text('Tem certeza que deseja excluir esta transação?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir')),
          ],
        ),
      );
      if (confirm ?? false) {
        await DatabaseHelper.instance.deleteTransaction(id);
        _pagingController.refresh();
        Provider.of<GoalsProvider>(context, listen: false).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transação excluída')));
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao excluir transação: $e', stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir transação')));
    }
  }

  void _editTransaction(Map<String, dynamic> transaction) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTransactionScreen(
            transaction: transaction,
            currentBalance: _calculateTotalBalance(),
          ),
        ),
      );
      if (result == true) {
        _pagingController.refresh();
        Provider.of<GoalsProvider>(context, listen: false).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transação atualizada')));
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao editar transação: $e', stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao editar transação')));
    }
  }

  double _calculateTotalBalance() {
    final items = _pagingController.itemList ?? [];
    return items.fold(0, (sum, t) => sum + t['amount']);
  }

  String _formatCurrency(double value) {
    final currency = Provider.of<ThemeManager>(context, listen: false).getCurrencyPreferenceSync();
    return NumberFormat.simpleCurrency(locale: 'pt_BR', name: currency).format(value);
  }

  void _showFilterDialog() async {
    if (!['Tudo', '7 Dias', '30 Dias', 'Personalizado'].contains(_timeFilter)) {
      _timeFilter = 'Tudo';
    }
    if (!['Data ↓', 'Data ↑', 'Valor ↓', 'Valor ↑'].contains(_sortOrder)) {
      _sortOrder = 'Data ↓';
    }
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtros e Ordenação'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrar por Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Center(
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(8.0),
                  children: [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Todas')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Receita')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Despesa')),
                  ],
                  isSelected: [_filterType == 0, _filterType == 1, _filterType == -1],
                  onPressed: (index) {
                    setState(() => _filterType = index == 0 ? 0 : (index == 1 ? 1 : -1));
                    Navigator.pop(context);
                    _pagingController.refresh();
                  },
                ),
              ),
              SizedBox(height: 16),
              Text('Período', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _timeFilter,
                isExpanded: true,
                items: ['Tudo', '7 Dias', '30 Dias', 'Personalizado']
                    .map((filter) => DropdownMenuItem(value: filter, child: Text(filter)))
                    .toList(),
                onChanged: (value) async {
                  if (value == 'Personalizado') {
                    Navigator.pop(context);
                    _showCustomDateFilterDialog();
                  } else if (value != null) {
                    setState(() => _timeFilter = value);
                    Navigator.pop(context);
                    _pagingController.refresh();
                  }
                },
              ),
              SizedBox(height: 16),
              Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String?>(
                value: _selectedCategory,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: null, child: Text('Todas')),
                  ..._categories.map((category) => DropdownMenuItem(value: category, child: Text(category))),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  Navigator.pop(context);
                  _pagingController.refresh();
                },
              ),
              SizedBox(height: 16),
              Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _sortOrder,
                isExpanded: true,
                items: ['Data ↓', 'Data ↑', 'Valor ↓', 'Valor ↑']
                    .map((order) => DropdownMenuItem(value: order, child: Text(order)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOrder = value);
                    Navigator.pop(context);
                    _pagingController.refresh();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDateFilterDialog(
        initialStartDate: _customStartDate,
        initialEndDate: _customEndDate,
        onApply: (start, end) {
          setState(() {
            _timeFilter = 'Personalizado';
            _customStartDate = start;
            _customEndDate = end;
            _pagingController.refresh();
          });
        },
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction['title'], style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text(
              _formatCurrency(transaction['amount']),
              style: TextStyle(fontSize: 20, color: transaction['type'] == 1 ? Colors.green : Colors.red),
            ),
            SizedBox(height: 8),
            Text('Data: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction['date']))}'),
            Text('Categoria: ${transaction['category']}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _editTransaction(transaction);
                  },
                  child: Text('Editar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteTransaction(transaction['id']);
                  },
                  child: Text('Excluir', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _pagingController.itemList ?? [];
    double totalIncome = items.where((t) => t['type'] == 1).fold(0, (sum, t) => sum + t['amount']);
    double totalExpense = items.where((t) => t['type'] == -1).fold(0, (sum, t) => sum + t['amount'].abs());
    double totalBalance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Finanças'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros e Ordenação',
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () => Navigator.pushNamed(context, '/reports'),
            tooltip: 'Relatórios',
          ),
          IconButton(
            icon: Icon(Icons.star),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GoalsScreen())).then((_) => _pagingController.refresh()),
            tooltip: 'Metas',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())).then((_) => _pagingController.refresh()),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: Column(
        children: [
          BalanceSummary(
            totalBalance: totalBalance,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            filterType: _filterType,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar transações',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _pagingController.refresh(); // Atualiza a lista ao puxar para baixo
              },
              child: PagedListView<int, Map<String, dynamic>>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                  itemBuilder: (context, transaction, index) {
                    return Dismissible(
                      key: Key(transaction['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 16.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _deleteTransaction(transaction['id']),
                      child: ListTile(
                        title: Text(
                          transaction['title'],
                          style: TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatCurrency(transaction['amount']),
                          style: TextStyle(
                            fontSize: 16,
                            color: transaction['type'] == 1 ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () => _showTransactionDetails(transaction),
                      ),
                    );
                  },
                  firstPageProgressIndicatorBuilder: (_) => Center(child: CircularProgressIndicator()),
                  newPageProgressIndicatorBuilder: (_) => Center(child: CircularProgressIndicator()),
                  noItemsFoundIndicatorBuilder: (_) => Center(
                    child: Text(
                      _searchController.text.isEmpty ? 'Nenhuma transação ainda' : 'Nenhuma transação encontrada',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTransactionScreen(currentBalance: _calculateTotalBalance())),
        ).then((result) {
          if (result == true) {
            _pagingController.refresh();
            Provider.of<GoalsProvider>(context, listen: false).refresh();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transação adicionada')));
          }
        }),
        child: Icon(Icons.add),
        tooltip: 'Adicionar Transação',
      ),
    );
  }
}