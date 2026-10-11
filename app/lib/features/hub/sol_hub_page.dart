import 'package:flutter/material.dart';

class SolHubPage extends StatelessWidget {
  final String title;
  const SolHubPage({super.key, required this.title});

  static const modules = <String>[
    'Ranking','Tarefas','Loja / Mall','VIP','DecoraÃ§Ãµes',
    'Jogos LAB','AgÃªncia','Host','BD','ADM Oficial',
    'Eventos','Metas','Recompensas','HistÃ³rico','Auditoria'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: modules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text(modules[i]),
            subtitle: const Text('MÃ³dulo Sol'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ModulePage(name: modules[i]),
            )),
          ),
        ),
      ),
    );
  }
}

class ModulePage extends StatelessWidget {
  final String name;
  const ModulePage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('MÃ³dulo Sol preparado para integraÃ§Ã£o funcional.'),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('MÃ³dulo disponÃ­vel no ambiente LAB.')),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Abrir mÃ³dulo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

