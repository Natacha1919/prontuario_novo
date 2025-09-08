// lib/modelos/atividade_recente.dart

import 'package:timezone/timezone.dart' as tz;

class AtividadeRecente {
  final int id;
  final String tipoAcao;
  final String descricao;
  final String? usuarioId;
  final int? pacienteId;
  final String? pacienteNome;
  
  // ⚠️ Use o created_at do banco para esta propriedade
  final DateTime timestampUtc;

  AtividadeRecente({
    required this.id,
    required this.tipoAcao,
    required this.descricao,
    this.usuarioId,
    this.pacienteId,
    this.pacienteNome,
    required this.timestampUtc, // Adicione required
  });

  factory AtividadeRecente.fromMap(Map<String, dynamic> map) {
    return AtividadeRecente(
      id: map['id'],
      tipoAcao: map['tipo_acao'] ?? '',
      descricao: map['descricao'] ?? '',
      usuarioId: map['usuario_id'],
      pacienteId: map['paciente_id'],
      pacienteNome: map['paciente_nome'],
      // Mapeie o created_at diretamente
      timestampUtc: DateTime.parse(map['created_at']), 
    );
  }

  // ⚠️ Este getter é o que faz a conversão
  DateTime get timestampLocal {
    return tz.TZDateTime.from(timestampUtc, tz.local);
  }
}