// lib/telas/exame_resultado_form_tela.dart

import 'package:flutter/material.dart';
import 'package:prontuario_medico/modelos/exame_resultado.dart';
import 'package:prontuario_medico/modelos/exame_solicitacao.dart';
import 'package:prontuario_medico/modelos/exame_tipo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
const Color corPrimaria = Color(0xFF133B4E); // Cor principal do tema
const Color corSecundaria = Color(0xFFF0F2F5); // Cor de fundo suave

class ExameResultadoFormTela extends StatefulWidget {
  final ExameSolicitacao solicitacao;
  final ExameResultado? resultadoExistente;

  const ExameResultadoFormTela({
    super.key,
    required this.solicitacao,
    this.resultadoExistente,
  });

  @override
  State<ExameResultadoFormTela> createState() => _ExameResultadoFormTelaState();
}

class _ExameResultadoFormTelaState extends State<ExameResultadoFormTela> {
  final _formKey = GlobalKey<FormState>();
  final _observacoesController = TextEditingController();
  final Map<int, TextEditingController> _resultadoControllers = {};

  List<ExameTipo> _tiposDeExame = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _observacoesController.text = widget.resultadoExistente?.observacoes ?? '';
    _buscarTiposDeExame();
  }

  Future<void> _buscarTiposDeExame() async {
    try {
      final ids = widget.solicitacao.examesSolicitadosIds;
      if (ids.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final data =
          await supabase.from('exame_tipos').select().inFilter('id', ids);
      final List<ExameTipo> tipos = [];
      for (final item in data) {
        final tipo = ExameTipo.fromMap(item as Map<String, dynamic>);
        tipos.add(tipo);
        final valorExistente =
            widget.resultadoExistente?.resultados[tipo.nome] ?? '';
        _resultadoControllers[tipo.id] =
            TextEditingController(text: valorExistente.toString());
      }
      setState(() {
        _tiposDeExame = tipos;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao buscar tipos de exame: $e'),
            backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _salvarResultados() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, String> resultados = {};
    for (var tipo in _tiposDeExame) {
      resultados[tipo.nome] = _resultadoControllers[tipo.id]!.text;
    }
    try {
      if (widget.resultadoExistente != null) {
        await supabase.from('exame_resultados').update({
          'observacoes': _observacoesController.text,
          'resultados': resultados
        }).eq('id', widget.resultadoExistente!.id!);
      } else {
        await supabase.from('exame_resultados').insert({
          'solicitacao_id': widget.solicitacao.id,
          'observacoes': _observacoesController.text,
          'resultados': resultados
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Resultados salvos com sucesso!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao salvar resultados: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    for (var controller in _resultadoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corSecundaria,
      appBar: AppBar(
        backgroundColor: corPrimaria,
        title: Text(
          widget.resultadoExistente == null ? 'Inserir Resultados' : 'Editar Resultados',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvarResultados,
        label: const Text('Salvar Alterações'),
        icon: const Icon(Icons.save),
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      _buildTabelaResultados(),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _observacoesController,
                        decoration: _buildInputDecoration(
                          labelText: 'Observações Gerais',
                          icon: Icons.notes,
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTabelaResultados() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            headingRowColor: MaterialStateProperty.all(corPrimaria.withOpacity(0.9)),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            dataRowColor: MaterialStateProperty.all(Colors.white),
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
              borderRadius: BorderRadius.circular(12),
            ),

            // Removido: DataTable não suporta columnWidths
            columns: const [
              DataColumn(label: Text('Exame Solicitado')),
              DataColumn(label: Text('Resultado')),
              DataColumn(label: Text('Valores de Ref.')),
              DataColumn(label: Text('Valores de Ref. (H)')),
              DataColumn(label: Text('Valores de Ref. (M)')),
            ],
            rows: _tiposDeExame.map((tipo) {
              return DataRow(
                cells: [
                  DataCell(Text(tipo.nome, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: _buildResultInput(tipo),
                    ),
                  ),
                  // CORREÇÃO AQUI: Tratamento para null com 'N/A'
                  DataCell(Text(tipo.valorReferencia ?? 'N/A', textAlign: TextAlign.center)),
                  DataCell(Text(tipo.valorReferenciaHomem ?? 'N/A', textAlign: TextAlign.center)),
                  DataCell(Text(tipo.valorReferenciaMulher ?? 'N/A', textAlign: TextAlign.center)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  Widget _buildResultInput(ExameTipo tipo) {
    return TextFormField(
      controller: _resultadoControllers[tipo.id],
      decoration: _buildInputDecoration(),
      textAlign: TextAlign.center,
      validator: (v) => v!.trim().isEmpty ? '*' : null,
    );
  }

  InputDecoration _buildInputDecoration({String? labelText, IconData? icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: icon != null ? Icon(icon, color: corPrimaria) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}