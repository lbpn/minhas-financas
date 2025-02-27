import 'package:flutter/material.dart';
import '../utils/database_helper.dart';
import '../utils/error_logger.dart';

class ManageCategoriesScreen extends StatefulWidget {
  @override
  _ManageCategoriesScreenState createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  int _filterType = 0;
  String _sortOrder = 'Nome';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await DatabaseHelper.instance.getCustomCategoriesWithCounts();
      setState(() {
        _categories = categories;
      });
      _filterCategories();
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao carregar categorias: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar categorias')));
    }
  }

  void _filterCategories() {
    setState(() {
      var filtered = _categories.where((cat) {
        final matchesType = _filterType == 0 || cat['type'] == _filterType;
        final searchText = _searchController.text.trim().toLowerCase();
        final matchesSearch = searchText.isEmpty ||
            cat['name'].toLowerCase().contains(searchText);
        return matchesType && matchesSearch;
      }).toList();

      if (_sortOrder == 'Nome') {
        filtered.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (_sortOrder == 'Transações') {
        filtered.sort((a, b) => (b['transaction_count'] as int)
            .compareTo(a['transaction_count'] as int));
      }

      _categories = filtered;
    });
  }

  void _renameCategory(int id, String currentName, int type) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renomear Categoria'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Novo nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Salvar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        await DatabaseHelper.instance.updateCustomCategory(id, newName);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Categoria renomeada')));
        _loadCategories();
      } catch (e, stackTrace) {
        ErrorLogger.logError('Erro ao renomear categoria: $e', stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao renomear categoria')));
      }
    }
  }

  void _deleteCategory(int id, String name) async {
    try {
      final inUse = await DatabaseHelper.instance
          .isCategoryInUse(name); // Novo método corrigido
      if (inUse) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoria em uso, não pode ser excluída')));
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Excluir Categoria'),
          content: Text('Tem certeza que deseja excluir "$name"?'),
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
        await DatabaseHelper.instance.deleteCustomCategory(id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Categoria excluída')));
        _loadCategories();
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError('Erro ao excluir categoria: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao excluir categoria')));
    }
  }

  void _deleteSelectedCategories(List<int> selectedIds) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Excluir Categorias Selecionadas'),
          content: Text(
              'Tem certeza que deseja excluir ${selectedIds.length} categoria(s)? Categorias em uso não serão excluídas.'),
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
        int deletedCount = 0;
        for (var id in selectedIds) {
          final category = _categories.firstWhere((cat) => cat['id'] == id);
          final inUse =
              await DatabaseHelper.instance.isCategoryInUse(category['name']);
          if (!inUse) {
            await DatabaseHelper.instance.deleteCustomCategory(id);
            deletedCount++;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$deletedCount categoria(s) excluída(s)')));
        _loadCategories();
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(
          'Erro ao excluir categorias selecionadas: $e', stackTrace);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao excluir categorias')));
    }
  }

  void _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtros e Ordenação'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrar por Tipo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Center(
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(8.0),
                  children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Todas')),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Receita')),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Despesa')),
                  ],
                  isSelected: [
                    _filterType == 0,
                    _filterType == 1,
                    _filterType == -1
                  ],
                  onPressed: (index) {
                    setState(() =>
                        _filterType = index == 0 ? 0 : (index == 1 ? 1 : -1));
                    Navigator.pop(context);
                    _filterCategories();
                  },
                ),
              ),
              SizedBox(height: 16),
              Text('Ordenar por',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _sortOrder,
                isExpanded: true,
                items: ['Nome', 'Transações']
                    .map((order) =>
                        DropdownMenuItem(value: order, child: Text(order)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOrder = value);
                    Navigator.pop(context);
                    _filterCategories();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<int> selectedIds = [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Categorias'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros e Ordenação',
          ),
          if (selectedIds.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSelectedCategories(selectedIds),
              tooltip: 'Excluir Selecionadas',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar categorias',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _categories.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Nenhuma categoria personalizada'
                          : 'Nenhuma categoria encontrada',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : StatefulBuilder(
                    builder: (context, setState) {
                      return ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              selectedIds.contains(category['id']);
                          return Dismissible(
                            key: Key(category['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 16.0),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) => _deleteCategory(
                                category['id'], category['name']),
                            child: CheckboxListTile(
                              title: Text(category['name']),
                              subtitle: Text(
                                  '${category['type'] == 1 ? 'Receita' : 'Despesa'} • ${category['transaction_count']} transações'),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedIds.add(category['id']);
                                  } else {
                                    selectedIds.remove(category['id']);
                                  }
                                });
                              },
                              secondary: IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _renameCategory(category['id'],
                                    category['name'], category['type']),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
