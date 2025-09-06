// lib/modelos/exame_tipo.dart

class ExameTipo {
  final int id;
  final String nome;
  final int categoriaId;
  final String valorReferenciaHomem;
  final String valorReferenciaMulher;

  ExameTipo({
    required this.id,
    required this.nome,
    required this.categoriaId,
    required this.valorReferenciaHomem,
    required this.valorReferenciaMulher,
  });

  factory ExameTipo.fromMap(Map<String, dynamic> map) {
    return ExameTipo(
      id: map['id'] as int,
      nome: map['nome'] as String? ?? '',
      categoriaId: map['categoria_id'] as int,
      valorReferenciaHomem: map['valor_referencia_homem'] as String? ?? 'N/A',
      valorReferenciaMulher: map['valor_referencia_mulher'] as String? ?? 'N/A',
    );
  }
}