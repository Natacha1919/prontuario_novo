// lib/modelos/exame_tipo.dart

class ExameTipo {
  final int id;
  final String nome;
  final int categoriaId;
  final String? valorReferencia;
  final int? parentId; // ⚠️ Adicione esta linha

  const ExameTipo({
    required this.id,
    required this.nome,
    required this.categoriaId,
    this.valorReferencia,
    this.parentId, // ⚠️ Adicione aqui no construtor
  });

  factory ExameTipo.fromMap(Map<String, dynamic> map) {
    return ExameTipo(
      id: map['id'] as int? ?? 0,
      nome: map['nome'] ?? '',
      categoriaId: map['categoria_id'] ?? 0,
      valorReferencia: map['valor_referencia'] as String?,
      parentId: map['parent_id'] as int?, // ⚠️ Mapeie o campo do Supabase
    );
  }
}