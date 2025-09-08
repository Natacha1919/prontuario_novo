// lib/servicos/gerador_pdf.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:prontuario_medico/modelos/anamnese.dart'; // Adicionado para a nova seção
import 'package:prontuario_medico/modelos/devolutiva.dart';
import 'package:prontuario_medico/modelos/exame_resultado.dart';
import 'package:prontuario_medico/modelos/exame_tipo.dart';
import 'package:prontuario_medico/modelos/paciente.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

final supabase = Supabase.instance.client;

const PdfColor corAzulPdf = PdfColor.fromInt(0xFF133B4E);

class GeradorPdf {
  static Future<void> gerarLaudoCompleto(BuildContext context, Paciente paciente) async {
    try {
      print('1. Iniciando geração do PDF...');

      // --- Funções Auxiliares de Busca de Dados ---
      final anamneses = await _buscarAnamneses(paciente.id!); // Busca as anamneses
      final resultado = await _buscarUltimoResultado(paciente.id!);
      final tiposExamesComRef = await _buscarTiposExames();
      final devolutiva = await _buscarUltimaDevolutiva(paciente.id!);

      if (resultado == null && devolutiva == null && anamneses.isEmpty) {
        print('ERRO: Nenhum dado para gerar o laudo.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não há dados (anamnese, resultados ou devolutiva) para gerar o laudo.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      final pdf = pw.Document();
      final imageUrl = 'https://qqhrskmuzbbhslgmdord.supabase.co/storage/v1/object/public/assets/logo.png';
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar a imagem da internet.');
      }
      final imageBytes = response.bodyBytes;
      final logoImage = pw.MemoryImage(imageBytes);
      print('5. Logo carregado com sucesso da internet.');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(logoImage),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildInfoPaciente(paciente),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 20),

            if (anamneses.isNotEmpty) ...[
              _buildSecaoAnamneses(anamneses),
              pw.SizedBox(height: 20),
            ],

            if (resultado != null) ...[
              _buildTabelaResultados(resultado, tiposExamesComRef),
              pw.SizedBox(height: 20),
            ],

            if (devolutiva != null) ...[
              _buildSecaoDevolutiva(devolutiva),
            ],
          ],
        ),
      );
      print('6. Página do PDF construída.');

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      print('7. PDF enviado para a tela de impressão/preview.');

    } catch (e) {
      print('ERRO AO GERAR PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Funções Auxiliares de Busca de Dados ---

  static Future<List<Anamnese>> _buscarAnamneses(int pacienteId) async {
    final data = await supabase.from('anamneses').select().eq('paciente_id', pacienteId).order('created_at', ascending: false);
    return data.map((item) => Anamnese.fromMap(item)).toList();
  }

  static Future<ExameResultado?> _buscarUltimoResultado(int pacienteId) async {
    final solicitacaoData = await supabase.from('exame_solicitacoes').select('id').eq('paciente_id', pacienteId).order('created_at', ascending: false).limit(1);
    if (solicitacaoData.isEmpty) return null;
    final ultimaSolicitacaoId = solicitacaoData.first['id'];
    final resultadoData = await supabase.from('exame_resultados').select().eq('solicitacao_id', ultimaSolicitacaoId).limit(1);
    return resultadoData.isNotEmpty ? ExameResultado.fromMap(resultadoData.first) : null;
  }
  
  static Future<Devolutiva?> _buscarUltimaDevolutiva(int pacienteId) async {
    final data = await supabase.from('devolutivas').select().eq('paciente_id', pacienteId).order('created_at', ascending: false).limit(1);
    return data.isNotEmpty ? Devolutiva.fromMap(data.first) : null;
  }

  static Future<Map<String, ExameTipo>> _buscarTiposExames() async {
    final data = await supabase.from('exame_tipos').select();
    final Map<String, ExameTipo> tiposMap = {};
    for (var item in data) {
      final tipo = ExameTipo.fromMap(item);
      tiposMap[tipo.nome] = tipo;
    }
    return tiposMap;
  }

  // --- Widgets para Construir o Layout do PDF ---

  static pw.Widget _buildHeader(pw.MemoryImage logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 2))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Image(logo, width: 120),
        pw.Text('Laudo de Atendimento', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: corAzulPdf)),
      ]),
    );
  }
  
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(color: PdfColors.grey)),
    );
  }

  static pw.Widget _buildInfoPaciente(Paciente paciente) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Paciente:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(paciente.nomeCompleto),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Data de Nascimento:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(paciente.dataNascimento ?? 'N/A'),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Sexo:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(paciente.sexo ?? 'N/A'),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Nº Prontuário:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(paciente.numeroProntuario ?? 'N/A'),
        ]),
      ]),
    ]);
  }

  static pw.Widget _buildSecaoAnamneses(List<Anamnese> anamneses) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTituloSecao('Anamneses'),
        for (var anamnese in anamneses) _buildAnamneseCard(anamnese),
      ],
    );
  }

  static pw.Widget _buildAnamneseCard(Anamnese anamnese) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
              'Anamnese de ${DateFormat('dd/MM/yyyy').format(anamnese.data!)}',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: corAzulPdf)),
          pw.Divider(height: 10, color: PdfColors.grey400),
          if (anamnese.queixaPrincipal.isNotEmpty)
            _buildDetalheAnamnese('Queixa Principal', anamnese.queixaPrincipal),
          if (anamnese.historiaDoencaAtual.isNotEmpty)
            _buildDetalheAnamnese(
                'História da Doença Atual', anamnese.historiaDoencaAtual),
          if (anamnese.historicoPatologicoPregresso.isNotEmpty)
            _buildDetalheAnamnese('Histórico Patológico Pregresso',
                anamnese.historicoPatologicoPregresso),
          if (anamnese.usoMedicamentos.isNotEmpty)
            _buildDetalheAnamnese(
                'Uso de Medicamentos', anamnese.usoMedicamentos),
          if (anamnese.habitosVida.isNotEmpty)
            _buildDetalheAnamnese('Hábitos de Vida', anamnese.habitosVida),
          if (anamnese.antecedentesFamiliares.isNotEmpty)
            _buildDetalheAnamnese(
                'Antecedentes Familiares', anamnese.antecedentesFamiliares),
        ],
      ),
    );
  }

  static pw.Widget _buildDetalheAnamnese(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$title:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(content, textAlign: pw.TextAlign.justify),
        ],
      ),
    );
  }

  static pw.Widget _buildSecaoResultados(
      ExameResultado resultado, Map<String, ExameTipo> tiposExames) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTituloSecao('Resultados de Exames'),
        _buildTabelaResultados(resultado, tiposExames),
      ],
    );
  }

  static pw.Widget _buildTabelaResultados(
      ExameResultado resultado, Map<String, ExameTipo> tiposExames) {
    final headers = [
      'Exame Solicitado',
      'Resultado',
      'Valores de Ref.',
    ];
    final data = resultado.resultados!.entries.map((entry) {
      final nomeExame = entry.key;
      final valorResultado = entry.value.toString();
      final tipoExame = tiposExames[nomeExame];
      return [
        nomeExame,
        valorResultado,
        tipoExame?.valorReferencia ?? 'N/A',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: corAzulPdf),
      border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center
      },
    );
  }

  static pw.Widget _buildSecaoDevolutiva(Devolutiva devolutiva) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTituloSecao('Devolutivas'),
        _buildDevolutivaCard(devolutiva),
      ],
    );
  }

  static pw.Widget _buildDevolutivaCard(Devolutiva devolutiva) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildTextBlock(
            'Relatório Acessível ao Paciente', devolutiva.relatorioPaciente),
        _buildTextBlock('Interpretação Básica (Profissional)',
            devolutiva.interpretacaoBasica),
        _buildTextBlock(
            'Orientação e Encaminhamento', devolutiva.orientacaoEncaminhamento),
        pw.SizedBox(height: 60),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildAssinatura(
                'Assinatura Aluno(s):\n${devolutiva.assinaturaAluno}'),
            _buildAssinatura(
                'Assinatura Professor:\n${devolutiva.assinaturaProfessor}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTextBlock(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  color: corAzulPdf)),
          pw.Container(
              height: 1,
              color: PdfColors.grey,
              margin: const pw.EdgeInsets.symmetric(vertical: 4)),
          pw.Text(content, textAlign: pw.TextAlign.justify),
        ],
      ),
    );
  }

  static pw.Widget _buildAssinatura(String text) {
    return pw.SizedBox(
      width: 200,
      child: pw.Column(
        children: [
          pw.Container(
              height: 0.5,
              color: PdfColors.black,
              margin: const pw.EdgeInsets.only(bottom: 4)),
          pw.Text(text, textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  static pw.Widget _buildTituloSecao(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 18,
          color: corAzulPdf,
        ),
      ),
    );
  }
}