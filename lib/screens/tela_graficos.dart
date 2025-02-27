import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/database_helper.dart';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/theme_manager.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  String _currency = 'BRL';
  final List<Color> _chartColors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.yellow, Colors.teal, Colors.pink, Colors.cyan, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchTransactions();
  }

  Future<void> _loadPreferences() async {
    _currency = await ThemeManager.instance.getCurrencyPreference();
    setState(() {});
  }

  Future<void> _fetchTransactions() async {
    final data = await DatabaseHelper.instance.getTransactions();
    setState(() => _transactions = data);
  }

  Map<String, double> _calculateCategoryTotals(bool isIncome) {
    final filtered = _transactions.where((t) => t['type'] == (isIncome ? 1 : -1));
    final totals = <String, double>{};
    for (var transaction in filtered) {
      totals[transaction['category']] = (totals[transaction['category']] ?? 0) + transaction['amount'].abs();
    }
    return totals;
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR', name: _currency);
    return formatter.format(value);
  }

  Color _getRandomColor(int index) {
    if (index < _chartColors.length) return _chartColors[index];
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  Future<void> _exportReportAsCSV() async {
    final incomeTotals = _calculateCategoryTotals(true);
    final expenseTotals = _calculateCategoryTotals(false);
    List<List<dynamic>> csvData = [
      ['Tipo', 'Categoria', 'Total'],
    ];
    incomeTotals.forEach((category, total) {
      csvData.add(['Receita', category, _formatCurrency(total)]);
    });
    expenseTotals.forEach((category, total) {
      csvData.add(['Despesa', category, _formatCurrency(total)]);
    });
    String csv = const ListToCsvConverter().convert(csvData);
    final params = SaveFileDialogParams(
      data: Uint8List.fromList(csv.codeUnits),
      fileName: 'report_${DateTime.now().toIso8601String()}.csv',
    );
    final result = await FlutterFileDialog.saveFile(params: params);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Relatório exportado para: $result')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportação cancelada')));
    }
  }

  Future<void> _exportReportAsPDF() async {
    final pdf = pw.Document();
    final incomeTotals = _calculateCategoryTotals(true);
    final expenseTotals = _calculateCategoryTotals(false);
    final totalIncome = incomeTotals.values.fold(0.0, (sum, value) => sum + value);
    final totalExpense = expenseTotals.values.fold(0.0, (sum, value) => sum + value);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Relatório Financeiro', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Resumo Financeiro', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 8),
            pw.Text('Receita Total: ${_formatCurrency(totalIncome)}'),
            pw.Text('Despesa Total: ${_formatCurrency(totalExpense)}'),
            pw.Text('Saldo: ${_formatCurrency(totalIncome - totalExpense)}'),
            pw.SizedBox(height: 16),
            pw.Text('Receitas por Categoria', style: pw.TextStyle(fontSize: 18)),
            pw.Table.fromTextArray(
              headers: ['Categoria', 'Total'],
              data: incomeTotals.entries.map((e) => [e.key, _formatCurrency(e.value)]).toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Despesas por Categoria', style: pw.TextStyle(fontSize: 18)),
            pw.Table.fromTextArray(
              headers: ['Categoria', 'Total'],
              data: expenseTotals.entries.map((e) => [e.key, _formatCurrency(e.value)]).toList(),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'report_${DateTime.now().toIso8601String()}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeTotals = _calculateCategoryTotals(true);
    final expenseTotals = _calculateCategoryTotals(false);
    final totalIncome = incomeTotals.values.fold(0.0, (sum, value) => sum + value);
    final totalExpense = expenseTotals.values.fold(0.0, (sum, value) => sum + value);

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatórios'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'csv') {
                _exportReportAsCSV();
              } else if (value == 'pdf') {
                _exportReportAsPDF();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'csv', child: Text('Exportar como CSV')),
              PopupMenuItem(value: 'pdf', child: Text('Exportar como PDF')),
            ],
            icon: Icon(Icons.download),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo Financeiro', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              Text('Receita Total: ${_formatCurrency(totalIncome)}', style: TextStyle(color: Colors.green)),
              Text('Despesa Total: ${_formatCurrency(totalExpense)}', style: TextStyle(color: Colors.red)),
              Text('Saldo: ${_formatCurrency(totalIncome - totalExpense)}'),
              SizedBox(height: 32),
              Text('Gastos por Categoria', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              Container(
                height: 200,
                child: expenseTotals.isEmpty
                    ? Center(child: Text('Nenhuma despesa registrada.'))
                    : PieChart(
                  PieChartData(
                    sections: expenseTotals.entries.map((entry) {
                      final percentage = (entry.value / totalExpense) * 100;
                      final index = expenseTotals.keys.toList().indexOf(entry.key);
                      return PieChartSectionData(
                        value: entry.value,
                        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
                        radius: 50,
                        color: _getRandomColor(index),
                        titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text('Receitas por Categoria', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              Container(
                height: 200,
                child: incomeTotals.isEmpty
                    ? Center(child: Text('Nenhuma receita registrada.'))
                    : PieChart(
                  PieChartData(
                    sections: incomeTotals.entries.map((entry) {
                      final percentage = (entry.value / totalIncome) * 100;
                      final index = incomeTotals.keys.toList().indexOf(entry.key);
                      return PieChartSectionData(
                        value: entry.value,
                        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
                        radius: 50,
                        color: _getRandomColor(index),
                        titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}