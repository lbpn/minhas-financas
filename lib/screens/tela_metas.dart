import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/error_logger.dart';
import '../utils/goals_provider.dart';

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializa o provider, mas o carregamento já é feito no construtor
  }

  String _formatCurrency(double value) {
    return NumberFormat.simpleCurrency(locale: 'pt_BR', name: 'BRL')
        .format(value);
  }

  Future<void> _addOrEditGoal(GoalsProvider provider,
      [Map<String, dynamic>? goal]) async {
    TextEditingController nameController =
        TextEditingController(text: goal?['name']);
    TextEditingController amountController =
        TextEditingController(text: goal?['target_amount']?.toString());
    DateTime? deadline =
        goal?['deadline'] != null ? DateTime.parse(goal!['deadline']) : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal == null ? 'Nova Meta' : 'Editar Meta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nome da Meta'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Valor Alvo (R\$)'),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                title: Text(deadline != null
                    ? 'Prazo: ${DateFormat('dd/MM/yyyy').format(deadline!)}'
                    : 'Escolher Prazo'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: deadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      deadline = picked;
                    });
                  }
                },
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
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text);
              if (name.isEmpty || amount == null || deadline == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Preencha todos os campos corretamente')));
                return;
              }
              await provider.addOrEditGoal(
                id: goal?['id'],
                name: name,
                targetAmount: amount,
                deadline: deadline!,
              );
              Navigator.pop(context, true);
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      // O Provider já notifica a atualização
    }
  }

  Future<void> _deleteGoal(GoalsProvider provider, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Meta'),
        content: Text('Tem certeza que deseja excluir esta meta?'),
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
      await provider.deleteGoal(id);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Meta excluída')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Metas Financeiras'),
          ),
          body: provider!.goals.isEmpty
              ? Center(child: Text('Nenhuma meta cadastrada'))
              : ListView.builder(
                  itemCount: provider!.goals.length,
                  itemBuilder: (context, index) {
                    final goal = provider!.goals[index];
                    final targetAmount = goal['target_amount'] as double;
                    final progress = provider!.totalSavings > targetAmount
                        ? 1.0
                        : provider.totalSavings / targetAmount;
                    final deadline = DateTime.parse(goal['deadline']);
                    final daysLeft = deadline.difference(DateTime.now()).inDays;

                    return Dismissible(
                      key: Key(goal['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 16.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) =>
                          _deleteGoal(provider, goal['id']),
                      child: Card(
                        child: ListTile(
                          title: Text(goal['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alvo: ${_formatCurrency(targetAmount)}'),
                              Text(
                                  'Progresso: ${_formatCurrency(provider.totalSavings)} (${(progress * 100).toStringAsFixed(1)}%)'),
                              Text(
                                  'Prazo: ${DateFormat('dd/MM/yyyy').format(deadline)} ($daysLeft dias restantes)'),
                              SizedBox(height: 8),
                              LinearProgressIndicator(value: progress),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _addOrEditGoal(provider, goal),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addOrEditGoal(provider),
            child: Icon(Icons.add),
            tooltip: 'Adicionar Meta',
          ),
        );
      },
    );
  }
}
