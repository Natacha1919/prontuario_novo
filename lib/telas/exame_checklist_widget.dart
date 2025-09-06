// lib/telas/exames_checklist_widget.dart

import 'package:flutter/material.dart';
import 'package:prontuario_medico/modelos/exame_categoria.dart';
import 'package:prontuario_medico/modelos/exame_solicitacao.dart';
import 'package:prontuario_medico/modelos/exame_tipo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

// Classe para o widget do checklist, que agora é um StatefulWidget
class ExamesChecklistWidget extends StatefulWidget {
  // Precisamos passar o ID do paciente e a solicitação para ele
  final int pacienteId;
  final ExameSolicitacao solicitacao; // A solicitação para saber quais exames buscar

  const ExamesChecklistWidget({
    super.key,
    required this.pacienteId,
    required this.solicitacao,
  });

  @override
  State<ExamesChecklistWidget> createState() => _ExamesChecklistWidgetState();
}

class _ExamesChecklistWidgetState extends State<ExamesChecklistWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _justificativaController = TextEditingController();
  // Mapa para guardar o estado de cada checkbox (ID do exame -> bool)
  final Map<int, bool> _selecionados = {}; 
  bool _isLoading = false; // Usado para mostrar loading no botão

  @override
  void initState() {
    super.initState();
    // Busca os exames disponíveis quando o widget é criado
    // Nenhuma chamada necessária, pois FutureBuilder já chama _buscarExamesDisponiveis()
  }

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  Future<List<ExameCategoria>> _buscarExamesDisponiveis() async {
    final ids = widget.solicitacao.examesSolicitadosIds;
    if (ids.isEmpty) return []; // Se nenhuma solicitação, retorna lista vazia

    // Busca as categorias e os tipos de exame associados
    final data = await supabase
        .from('exame_tipos')
        .select('id, nome, categoria_id, exame_categorias(nome)') // Seleciona os campos necessários
        .filter('id', 'in', '(${ids.join(",")})') // Filtra pelos IDs que foram solicitados
        .order('categoria_id') // Ordena pela categoria
        .order('nome'); // E depois pelo nome do exame
    // final List<ExameCategoria> categoriasComExames = []; // Removido, não utilizado
    final Map<int, ExameCategoria> mapCategorias = {};

    for (var item in data) {
      final tipoExame = ExameTipo.fromMap(item);
      final categoriaId = item['categoria_id'];
      final categoriaNome = item['exame_categorias']['nome'];

      if (!mapCategorias.containsKey(categoriaId)) {
        mapCategorias[categoriaId] = ExameCategoria(id: categoriaId, nome: categoriaNome, tipos: []);
      }
      mapCategorias[categoriaId]!.tipos.add(tipoExame);
    }
    
    return mapCategorias.values.toList();
  }

  // Método usado como callback do botão de salvar
  void _salvarSolicitacao() async {
    if (!_formKey.currentState!.validate()) return;
    
    final List<int> idsSelecionadas = _selecionados.entries
        .where((entry) => entry.value) // Filtra os que estão marcados como true
        .map((entry) => entry.key)      // Pega apenas os IDs
        .toList();

    if (idsSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione ao menos um exame.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true); // Ativa o indicador de loading
    try {
      // Salva no Supabase
      await supabase.from('exame_solicitacoes').insert({
        'paciente_id': widget.pacienteId, // Usa o pacienteId passado
        'justificativa_clinica': _justificativaController.text.trim(),
        'exames_solicitados': idsSelecionadas, // A lista de IDs dos exames selecionados
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação salva com sucesso!'), backgroundColor: Colors.green),
      );
      
      // Limpa os campos após salvar com sucesso
      _justificativaController.clear();
      setState(() { // Limpa os checkboxes selecionados
        _selecionados.clear();
      });

    } catch (e) {
      print('Erro ao salvar solicitação: $e'); // Loga o erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar solicitação: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Desativa o indicador de loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExameCategoria>>(
      future: _buscarExamesDisponiveis(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar exames: ${snapshot.error}'));
        }
        
        final categorias = snapshot.data ?? [];
        if (categorias.isEmpty) {
          return const Center(child: Text('Nenhum tipo de exame encontrado.'));
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Selecione os exames a serem solicitados:', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Cria uma ExpansionTile para cada categoria de exame
              ...categorias.map((categoria) => ExpansionTile(
                title: Text(categoria.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: true, // Abre a expansão por padrão
                children: categoria.tipos.map<Widget>((tipo) => CheckboxListTile(
                  title: Text(tipo.nome),
                  value: _selecionados[tipo.id] ?? false, // Pega o estado atual do checkbox
                  onChanged: (bool? value) {
                    // **** ESSENCIAL: Chama setState para atualizar a UI ****
                    setState(() {
                      _selecionados[tipo.id] = value ?? false; // Atualiza o estado do checkbox
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading, // Checkbox fica à esquerda
                )).toList(),
              )).toList(),

              const SizedBox(height: 24),
              TextFormField(
                controller: _justificativaController,
                decoration: const InputDecoration(labelText: 'Justificativa Clínica', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              // Botão de salvar, mostra o indicador de loading se estiver salvando
              // Botão de salvar, mostra o indicador de loading se estiver salvando
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _salvarSolicitacao,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Enviar Solicitação'),
                    ),
            ],
          ),
        );
      }
    );
  }
}