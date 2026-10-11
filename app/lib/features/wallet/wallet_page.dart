import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';

class WalletPage extends StatefulWidget {
  final String title;
  const WalletPage({super.key, this.title = 'Carteira'});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Future<Map<String, dynamic>?> wallet;
  late Future<List<Map<String, dynamic>>> ledger;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    wallet = loadWallet();
    ledger = loadLedger();
  }

  Future<Map<String, dynamic>?> loadWallet() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return await supabase
        .from('user_wallets')
        .select('user_id,balance,updated_at')
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> loadLedger() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final rows = await supabase
        .from('wallet_ledger')
        .select('event_type,amount,balance_after,created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          onPressed: () => setState(refresh),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Saldo da conta',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        FutureBuilder<Map<String, dynamic>?>(
          future: wallet,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Falha ao consultar carteira: ${snapshot.error}');
            }
            final row = snapshot.data;
            if (row == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma carteira encontrada. Nenhum saldo de teste foi criado.',
                  ),
                ),
              );
            }
            return Card(
              color: const Color(0xff0b1429),
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xffffd35a),
                ),
                title: const Text('Créditos virtuais'),
                trailing: Text(
                  '${row['balance'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xffffd35a),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Extrato',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ledger,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Falha ao consultar extrato: ${snapshot.error}');
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhuma movimentação registrada.'),
              );
            }
            return Column(
              children: rows
                  .map(
                    (r) => ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        (r['event_type'] ?? 'Movimentação').toString(),
                      ),
                      subtitle: Text((r['created_at'] ?? '').toString()),
                      trailing: Text(
                        '${r['amount'] ?? 0} → ${r['balance_after'] ?? 0}',
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}
