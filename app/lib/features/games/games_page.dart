import 'package:flutter/material.dart';

/// A área só deve listar jogos depois de identificar e integrar os pacotes
/// reais observados no Shabab. Não há jogos funcionais confirmados nesta tela.
class SolGamesPage extends StatelessWidget {
  const SolGamesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Jogos')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports_outlined, size: 48),
            SizedBox(height: 12),
            Text(
              'Catálogo de jogos ainda não integrado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Esta área será ligada aos jogos e pacotes identificados na análise do Shabab. Nenhum jogo demonstrativo será apresentado como funcional.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
