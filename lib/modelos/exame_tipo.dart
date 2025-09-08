// lib/modelos/exame_tipo.dart

class ExameTipo {
  final int id;
  final String nome;
  final int categoriaId;
  final String? valorReferenciaHomem;   // Adicione esta propriedade
  final String? valorReferenciaMulher;  // Adicione esta propriedade

  const ExameTipo({
    required this.id,
    required this.nome,
    required this.categoriaId,
    this.valorReferenciaHomem,
    this.valorReferenciaMulher,
  });

  factory ExameTipo.fromMap(Map<String, dynamic> map) {
    return ExameTipo(
      id: map['id'],
      nome: map['nome'] ?? '',
      categoriaId: map['categoria_id'] ?? 0,
      valorReferenciaHomem: map['valor_referencia_masculino'] as String?, // Mapeie o campo do banco
      valorReferenciaMulher: map['valor_referencia_feminino'] as String?, // Mapeie o campo do banco
    );
  }
}