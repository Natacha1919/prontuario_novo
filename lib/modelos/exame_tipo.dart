// lib/modelos/exame_tipo.dart

class ExameTipo {
  final int id;
  final String nome;
  final int categoriaId;
  final String? valorReferencia;

  const ExameTipo({
    required this.id,
    required this.nome,
    required this.categoriaId,
    this.valorReferencia,
  });

  factory ExameTipo.fromMap(Map<String, dynamic> map) {
    return ExameTipo(
      id: map['id'] as int? ?? 0,
      nome: map['nome'] ?? '',
      categoriaId: map['categoria_id'] ?? 0,
      valorReferencia: map['valor_referencia'] as String?, // Maps the field from the database
    );
  }
}