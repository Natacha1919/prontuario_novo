// lib/telas/anamnese_form_tela.dart

import 'package:flutter/material.dart';
import 'package:prontuario_medico/modelos/anamnese.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AnamneseFormTela extends StatefulWidget {
  final int pacienteId;
  final Anamnese? anamnese;

  const AnamneseFormTela({
    super.key,
    required this.pacienteId,
    this.anamnese,
  });

  @override
  State<AnamneseFormTela> createState() => _AnamneseFormTelaState();
}

class _AnamneseFormTelaState extends State<AnamneseFormTela> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _queixaController;
  late TextEditingController _historiaController;
  late TextEditingController _patologicoController;
  late TextEditingController _medicamentosController;
  late TextEditingController _habitosController;
  late TextEditingController _familiaresController;

  @override
  void initState() {
    super.initState();
    _queixaController = TextEditingController(text: widget.anamnese?.queixaPrincipal ?? '');
    _historiaController = TextEditingController(text: widget.anamnese?.historiaDoencaAtual ?? '');
    _patologicoController = TextEditingController(text: widget.anamnese?.historicoPatologicoPregresso ?? '');
    _medicamentosController = TextEditingController(text: widget.anamnese?.usoMedicamentos ?? '');
    _habitosController = TextEditingController(text: widget.anamnese?.habitosVida ?? '');
    _familiaresController = TextEditingController(text: widget.anamnese?.antecedentesFamiliares ?? '');
  }

  void _salvarFormulario() async {
    if (_formKey.currentState!.validate()) {
      final anamneseProcessada = Anamnese(
        id: widget.anamnese?.id,
        pacienteId: widget.pacienteId,
        data: DateTime.now(),
        queixaPrincipal: _queixaController.text,
        historiaDoencaAtual: _historiaController.text,
        historicoPatologicoPregresso: _patologicoController.text,
        usoMedicamentos: _medicamentosController.text,
        habitosVida: _habitosController.text,
        antecedentesFamiliares: _familiaresController.text,
      );

      try {
        if (widget.anamnese == null) {
          await supabase.from('anamneses').insert(anamneseProcessada.toMap());
          await supabase.from('historico_atividades').insert({
            'tipo_acao': 'Anamnese Registrada',
            'descricao': 'Nova anamnese para o paciente ID ${widget.pacienteId}.',
            'usuario_id': supabase.auth.currentUser?.id,
            'paciente_id': widget.pacienteId,
          });
        } else {
          await supabase.from('anamneses').update(anamneseProcessada.toMap()).eq('id', anamneseProcessada.id!);
          await supabase.from('historico_atividades').insert({
            'tipo_acao': 'Anamnese Atualizada',
            'descricao': 'Anamnese ID ${anamneseProcessada.id} atualizada.',
            'usuario_id': supabase.auth.currentUser?.id,
            'paciente_id': widget.pacienteId,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anamnese salva com sucesso!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar anamnese: $e'), backgroundColor: Colors.red));
          Navigator.of(context).pop(false);
        }
      }
    }
  }

  @override
  void dispose() {
    _queixaController.dispose();
    _historiaController.dispose();
    _patologicoController.dispose();
    _medicamentosController.dispose();
    _habitosController.dispose();
    _familiaresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
          widget.anamnese == null ? 'Nova Anamnese' : 'Editar Anamnese',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 16, 36, 67),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    'Preencha o formulário para adicionar ou editar a anamnese do paciente.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    controller: _queixaController,
                    label: 'Queixa Principal',
                    maxLines: 2,
                    icon: Icons.personal_injury_outlined,
                  ),
                  _buildTextFormField(
                    controller: _historiaController,
                    label: 'História da Doença Atual',
                    maxLines: 5,
                    icon: Icons.description_outlined,
                  ),
                  _buildTextFormField(
                    controller: _patologicoController,
                    label: 'Histórico Patológico Pregresso',
                    maxLines: 3,
                    icon: Icons.history_outlined,
                  ),
                  _buildTextFormField(
                    controller: _medicamentosController,
                    label: 'Uso de Medicamentos',
                    maxLines: 3,
                    icon: Icons.medical_services_outlined,
                  ),
                  _buildTextFormField(
                    controller: _habitosController,
                    label: 'Hábitos de Vida',
                    maxLines: 3,
                    icon: Icons.favorite_border_outlined,
                  ),
                  _buildTextFormField(
                    controller: _familiaresController,
                    label: 'Antecedentes Familiares Relevantes',
                    maxLines: 3,
                    icon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _salvarFormulario,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Salvar Anamnese'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF133B4E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        maxLines: maxLines,
        validator: (value) => (value?.trim().isEmpty ?? true) ? 'Campo obrigatório' : null,
      ),
    );
  }
}