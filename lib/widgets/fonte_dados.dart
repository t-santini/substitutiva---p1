import 'package:flutter/material.dart';

/// Rodapé que identifica o CPTEC/INPE como fonte dos dados.
class FonteDados extends StatelessWidget {
  const FonteDados({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        'Fonte dos dados: CPTEC/INPE – Centro de Previsão de Tempo e '
        'Estudos Climáticos / Instituto Nacional de Pesquisas Espaciais',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
      ),
    );
  }
}

/// Mensagem centralizada com ícone e ação opcional.
class MensagemEstado extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String? textoBotao;
  final VoidCallback? aoPressionar;

  const MensagemEstado({
    super.key,
    required this.icone,
    required this.mensagem,
    this.textoBotao,
    this.aoPressionar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            if (textoBotao != null && aoPressionar != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: aoPressionar,
                icon: const Icon(Icons.refresh),
                label: Text(textoBotao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
