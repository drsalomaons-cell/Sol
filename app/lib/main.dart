import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_service.dart';
import 'features/auth/auth_page.dart';
import 'features/wallet/wallet_page.dart';
import 'features/profile/profile_page.dart';
import 'features/room/room_page.dart';
import 'features/games/games_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (solSupabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: solSupabaseUrl,
      publishableKey: solSupabasePublishableKey,
    );
  }
  runApp(SolApp(configured: solSupabasePublishableKey.isNotEmpty));
}

class SolApp extends StatelessWidget {
  final bool configured;
  const SolApp({super.key, this.configured = false});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Sol',
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xff060d1c),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffffd35a),
        brightness: Brightness.dark,
      ),
    ),
    home: configured ? const SolAuthGate() : const SolSetupPage(),
  );
}

class SolSetupPage extends StatelessWidget {
  const SolSetupPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny_outlined, size: 58, color: Color(0xffffd35a)),
              SizedBox(height: 16),
              Text(
                'SOL',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Falta configurar a chave pública do Supabase para habilitar o acesso real. Nenhuma sala ou saldo de demonstração será apresentado como dado real.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SolAuthGate extends StatelessWidget {
  const SolAuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: supabase.auth.onAuthStateChange,
    builder: (context, snapshot) => supabase.auth.currentSession != null
        ? const SolShell()
        : const AuthPage(),
  );
}

class SolShell extends StatefulWidget {
  const SolShell({super.key});
  @override
  State<SolShell> createState() => _SolShellState();
}

class _SolShellState extends State<SolShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const SolHomePage(),
      const SolGamesPage(),
      const WalletPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Jogos',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Carteira',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class SolHomePage extends StatefulWidget {
  const SolHomePage({super.key});
  @override
  State<SolHomePage> createState() => _SolHomePageState();
}

class _SolHomePageState extends State<SolHomePage> {
  late Future<List<Map<String, dynamic>>> sessions;
  @override
  void initState() {
    super.initState();
    sessions = loadSessions();
  }

  Future<List<Map<String, dynamic>>> loadSessions() async {
    final rows = await supabase
        .from('room_sessions')
        .select(
          'id,room_key,title,status,seats,video_enabled,chat_enabled,created_at',
        )
        .eq('status', 'live')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _createRoom() async {
    final titleController = TextEditingController();
    var capacity = 30;
    var saving = false;
    String? dialogError;

    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Criar sala ao vivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nome da sala',
                  hintText: 'Ex.: Conversa com amigos',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: capacity,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de cadeiras',
                ),
                items: const [30, 40, 48, 60, 80, 100]
                    .map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n cadeiras'),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) => setDialogState(() => capacity = value ?? 30),
              ),
              if (dialogError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dialogError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.length < 3) {
                        setDialogState(
                          () => dialogError =
                              'Digite um nome com pelo menos 3 caracteres.',
                        );
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        dialogError = null;
                      });
                      try {
                        final raw = await supabase.rpc(
                          'create_room_session',
                          params: {
                            'p_title': title,
                            'p_seats': capacity,
                            'p_video_enabled': false,
                            'p_chat_enabled': true,
                          },
                        );
                        final room = Map<String, dynamic>.from(raw as Map);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, room);
                        }
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          dialogError = e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          );
                        });
                      }
                    },
              child: Text(saving ? 'Criando…' : 'Criar sala'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    if (created == null || !mounted) return;
    setState(() {
      sessions = loadSessions();
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomPage(
          roomId: created['id']?.toString(),
          roomTitle: (created['title'] ?? 'Sala').toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text(
            'SOL',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
          ),
          actions: [
            IconButton(
              onPressed: () => setState(() {
                sessions = loadSessions();
              }),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xff172b55), Color(0xff0b1429)],
                  ),
                  border: Border.all(color: const Color(0xffc9a43a)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salas ao vivo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Lista real do banco. O áudio requer servidor de mídia e token válidos.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _createRoom,
                  icon: const Icon(Icons.add),
                  label: const Text('Criar sala'),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Salas ativas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: sessions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Falha ao carregar salas: ${snapshot.error}');
                  }
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return const Text('Nenhuma sala ao vivo encontrada.');
                  }
                  return Column(
                    children: rows
                        .map(
                          (row) => Card(
                            color: const Color(0xff0b1429),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.mic),
                              ),
                              title: Text(
                                (row['title'] ?? row['room_key'] ?? 'Sala')
                                    .toString(),
                              ),
                              subtitle: Text(
                                '${row['seats'] ?? 0} posições • ${row['status'] ?? '—'}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomPage(
                                    roomId: row['id']?.toString(),
                                    roomTitle: (row['title'] ?? 'Sala')
                                        .toString(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    ),
  );
}
