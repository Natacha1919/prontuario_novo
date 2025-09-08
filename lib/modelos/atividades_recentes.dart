// lib/modelos/atividade_recente.dart

import 'package:timezone/timezone.dart' as tz;

class AtividadeRecente {
final int id;
final DateTime data;
final String tipoAcao;
final String descricao;
final String? usuarioId;
final int? pacienteId;
final String? pacienteNome;
final DateTime timestampUtc;

AtividadeRecente({
  required this.id,
  required this.data,
  required this.tipoAcao,
  required this.descricao,
  this.usuarioId,
  this.pacienteId,
  this.pacienteNome,
  required this.timestampUtc,
});

factory AtividadeRecente.fromMap(Map<String, dynamic> map) {
  return AtividadeRecente(
	id: map['id'],
	data: DateTime.parse(map['created_at']),
	tipoAcao: map['tipo_acao'] ?? '',
	descricao: map['descricao'] ?? '',
	usuarioId: map['usuario_id'],
	pacienteId: map['paciente_id'],
	pacienteNome: map['paciente_nome'],
	// ⚠️ ATENÇÃO: Mapeie o created_at para o campo timestampUtc
	timestampUtc: DateTime.parse(map['created_at']),
  );
}

// Adicione este getter para converter para o fuso horário local
DateTime get timestampLocal {
  return tz.TZDateTime.from(timestampUtc, tz.local);
}
}