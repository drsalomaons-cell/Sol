[Reading 196 lines from start (total: 196 lines, 0 remaining)]

import 'package:flutter/material.dart';

void main() => runApp(const SolApp());

class SolApp extends StatelessWidget {
  const SolApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Sol',
    theme: ThemeData.dark(useMaterial3: true),
    home: const SolHome(),
  );
}

class SolHome extends StatefulWidget {
  const SolHome({super.key});
  @override
  State<SolHome> createState() => _SolHomeState();
}

class _SolHomeState extends State<SolHome> {
  int tab = 0;
  int selectedSeat = -1;
  int coins = 12580;
  final List<String?> seats = List<String?>.filled(12, null);

  void toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void openSeat(int index) {
    setState(() => selectedSeat = index);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff10182b),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Cadeira ' + (index + 1).toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(seats[index] ?? 'Cadeira livre'),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => seats[index] = 'Você');
                toast('Você entrou na cadeira ' + (index + 1).toString());
              },
              icon: const Icon(Icons.mic),
              label: const Text('Sentar / falar'),
            )),
            IconButton(
              onPressed: () { Navigator.pop(context); toast('Convite enviado.'); },
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ]),
        ]),
      ),
    );
  }

  void gift() {
    if (coins < 100) { toast('Saldo insuficiente'); return; }
    setState(() => coins -= 100);
    toast('Presente enviado -100 moedas');
  }

  Widget pill(IconData icon, String label) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: const Color(0xff6de8ed)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    ]),
  );

  Widget room() => SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xff111d3d), Color(0xff17234a)]),
          border: Border.all(color: Color(0xffd6ae4b)),
        ),
        child: Column(children: [
          Row(children: [
            const CircleAvatar(backgroundColor: Color(0xff27d8df), child: Icon(Icons.person)),
            const SizedBox(width: 10),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sala Sol • Noite Cósmica', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Host • 1.284 ouvintes', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
            IconButton(onPressed: () => toast('Sala adicionada aos favoritos'), icon: const Icon(Icons.star_border, color: Color(0xffffd45c))),
          ]),
          const SizedBox(height: 8),
          Row(children: [pill(Icons.mic, 'Voz ao vivo'), pill(Icons.videocam_outlined, 'Vídeo'), pill(Icons.shield_outlined, 'Moderada')]),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        const Expanded(child: Text('Cadeiras', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
        Text(seats.where((x) => x != null).length.toString() + '/12', style: const TextStyle(color: Colors.white54)),
      ]),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 12),
        itemBuilder: (_, index) => GestureDetector(
          onTap: () => openSeat(index),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff101a34),
              border: Border.all(color: index == selectedSeat ? const Color(0xff28dce2) : const Color(0xff344365), width: 2),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(seats[index] == null ? Icons.mic_none : Icons.mic, color: seats[index] == null ? Colors.white38 : const Color(0xff28d8df)),
              Text(seats[index] ?? 'Livre', style: const TextStyle(fontSize: 9, color: Colors.white60)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xff0d152b), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Expanded(child: TextField(
            decoration: const InputDecoration(hintText: 'Escreva no chat...', border: InputBorder.none),
            onSubmitted: (value) { if (value.isNotEmpty) toast('Você: ' + value); },
          )),
          IconButton(onPressed: gift, icon: const Icon(Icons.card_giftcard, color: Color(0xffffd45c))),
          IconButton(onPressed: () => toast('Jogos: Roulette • Ludo • 777'), icon: const Icon(Icons.sports_esports_outlined, color: Color(0xff2bdbe1))),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => toast('Ranking da sala aberto'), icon: const Icon(Icons.leaderboard), label: const Text('Ranking'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: () => toast('Tarefas e recompensas abertas'), icon: const Icon(Icons.task_alt), label: const Text('Tarefas'))),
      ]),
    ]),
  );

  Widget wallet() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.account_balance_wallet, color: Color(0xffffd45c), size: 64),
    const SizedBox(height: 12),
    const Text('Carteira Sol', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    const SizedBox(height: 6),
    Text(coins.toString() + ' moedas', style: const TextStyle(fontSize: 20, color: Color(0xffffd45c))),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: () => toast('Recarga LAB disponível'), icon: const Icon(Icons.add), label: const Text('Adicionar moedas')),
    TextButton(onPressed: () => toast('Extrato aberto'), child: const Text('Ver extrato')),
  ]));

  @override
  Widget build(BuildContext context) {
    Widget body = tab == 0 ? room() : tab == 1 ? const Center(child: Text('Descobrir salas')) : wallet();
    return Scaffold(
      backgroundColor: const Color(0xff070d1d),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a1124),
        title: Row(children: [
          const Icon(Icons.wb_sunny_rounded, color: Color(0xffffd45c)),
          const SizedBox(width: 8),
          const Text('SOL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Spacer(),
          Text(coins.toString(), style: const TextStyle(color: Color(0xffffd45c), fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Icon(Icons.monetization_on, color: Color(0xffffd45c)),
        ]),
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        backgroundColor: const Color(0xff0a1124),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Salas'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Descobrir'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Carteira'),
        ],
      ),
    );
  }
}