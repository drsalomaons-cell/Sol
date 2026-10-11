import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../wallet/wallet_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool busy = false;
  late final TextEditingController nameController;
  late final TextEditingController regionController;
  late final TextEditingController avatarController;

  User? get user => supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    nameController = TextEditingController(
      text: (metadata['display_name'] ?? metadata['name'] ?? '').toString(),
    );
    regionController = TextEditingController(
      text: (metadata['region'] ?? '').toString(),
    );
    avatarController = TextEditingController(
      text: (metadata['avatar_url'] ?? '').toString(),
    );
    _ensureProfileRows();
  }

  Future<void> _ensureProfileRows() async {
    final current = user;
    if (current == null) return;
    final metadata = current.userMetadata ?? const <String, dynamic>{};
    final name =
        (metadata['display_name'] ??
                metadata['name'] ??
                current.email?.split('@').first ??
                'Usuário Sol')
            .toString();
    try {
      await supabase.from('sol_profiles').upsert({
        'user_id': current.id,
        'language': (metadata['language'] ?? 'pt').toString(),
        'notifications_push': metadata['notifications_push'] ?? true,
        'notifications_room': metadata['notifications_room'] ?? true,
        'notifications_friends': metadata['notifications_friends'] ?? true,
      }, onConflict: 'user_id');
      await supabase.from('sol_public_profiles').upsert({
        'user_id': current.id,
        'display_name': name.trim().isEmpty ? 'Usuário Sol' : name.trim(),
        'region': (metadata['region'] ?? '').toString(),
        'avatar_url': (metadata['avatar_url'] ?? '').toString(),
      }, onConflict: 'user_id');
    } catch (_) {
      // The UI keeps existing auth metadata if profile synchronization is temporarily unavailable.
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    regionController.dispose();
    avatarController.dispose();
    super.dispose();
  }

  String get displayName {
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final saved = (metadata['display_name'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    if (saved.isNotEmpty) return saved;
    final email = user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Usuário Sol';
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> editProfile() async {
    nameController.text = displayName;
    regionController.text = (user?.userMetadata?['region'] ?? '').toString();
    avatarController.text = (user?.userMetadata?['avatar_url'] ?? '')
        .toString();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Nome de exibição',
                  ),
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Informe pelo menos 2 caracteres.'
                      : null,
                ),
                TextFormField(
                  controller: regionController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'País/região (opcional)',
                  ),
                ),
                TextFormField(
                  controller: avatarController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link da foto (opcional)',
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return null;
                    final uri = Uri.tryParse(v);
                    return uri != null &&
                            (uri.scheme == 'https' || uri.scheme == 'http') &&
                            uri.host.isNotEmpty
                        ? null
                        : 'Use um link http(s) válido.';
                  },
                ),
                const SizedBox(height: 8),
                Text('Conta: ${user?.email ?? 'sem e-mail'}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved != true || user == null) return;

    setState(() => busy = true);
    try {
      final current = user!;
      final name = nameController.text.trim();
      final region = regionController.text.trim();
      final avatar = avatarController.text.trim();
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'display_name': name, 'region': region, 'avatar_url': avatar},
        ),
      );
      await supabase.from('sol_public_profiles').upsert({
        'user_id': current.id,
        'display_name': name,
        'region': region,
        'avatar_url': avatar,
      }, onConflict: 'user_id');
      if (mounted) setState(() {});
      message('Perfil atualizado.');
    } on AuthException catch (e) {
      message('Não foi possível salvar: ${e.message}');
    } catch (e) {
      message('Falha ao salvar perfil: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> security() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final change = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Segurança da conta'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Conta conectada: ${user?.email ?? 'não identificada'}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (value) => (value ?? '').length < 8
                    ? 'Use pelo menos 8 caracteres.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Alterar senha'),
          ),
        ],
      ),
    );
    if (change != true) {
      controller.dispose();
      return;
    }
    setState(() => busy = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: controller.text));
      message('Senha alterada com sucesso.');
    } on AuthException catch (e) {
      message('Não foi possível alterar a senha: ${e.message}');
    } catch (e) {
      message('Falha ao alterar senha: $e');
    } finally {
      controller.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> contacts() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SolContactsPage()));
  }

  Future<void> blockedUsers() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SolBlockedUsersPage()),
    );
  }

  Future<void> visitors() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SolVisitorsPage()));
  }

  Future<void> notifications() async {
    final current = user;
    if (current == null) return;
    var push = true;
    var room = true;
    var friends = true;
    try {
      final row = await supabase
          .from('sol_profiles')
          .select('notifications_push,notifications_room,notifications_friends')
          .eq('user_id', current.id)
          .maybeSingle();
      push = row?['notifications_push'] as bool? ?? true;
      room = row?['notifications_room'] as bool? ?? true;
      friends = row?['notifications_friends'] as bool? ?? true;
    } catch (_) {
      final metadata = current.userMetadata ?? const <String, dynamic>{};
      push = metadata['notifications_push'] as bool? ?? true;
      room = metadata['notifications_room'] as bool? ?? true;
      friends = metadata['notifications_friends'] as bool? ?? true;
    }
    if (!mounted) return;
    final result = await showDialog<List<bool>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Notificações'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: push,
                onChanged: (v) => setDialogState(() => push = v),
                title: const Text('Avisos gerais'),
              ),
              SwitchListTile(
                value: room,
                onChanged: (v) => setDialogState(() => room = v),
                title: const Text('Atividade das salas'),
              ),
              SwitchListTile(
                value: friends,
                onChanged: (v) => setDialogState(() => friends = v),
                title: const Text('Amigos e contatos'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, [push, room, friends]),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (result == null || user == null) return;
    try {
      await supabase.from('sol_profiles').upsert({
        'user_id': current.id,
        'notifications_push': result[0],
        'notifications_room': result[1],
        'notifications_friends': result[2],
      }, onConflict: 'user_id');
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'notifications_push': result[0],
            'notifications_room': result[1],
            'notifications_friends': result[2],
          },
        ),
      );
      message('Preferências de notificação salvas.');
    } catch (e) {
      message('Falha ao salvar preferências: $e');
    }
  }

  Future<void> language() async {
    final current = user;
    if (current == null) return;
    const options = <String, String>{
      'pt': 'Português',
      'en': 'English',
      'ar': 'العربية',
      'es': 'Español',
    };
    var selected = (current.userMetadata?['language'] ?? 'pt').toString();
    try {
      final row = await supabase
          .from('sol_profiles')
          .select('language')
          .eq('user_id', current.id)
          .maybeSingle();
      selected = (row?['language'] ?? selected).toString();
    } catch (_) {}
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Idioma preferido'),
        content: DropdownButtonFormField<String>(
          initialValue: options.containsKey(selected) ? selected : 'pt',
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => selected = v ?? 'pt',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await supabase.from('sol_profiles').upsert({
        'user_id': current.id,
        'language': result,
      }, onConflict: 'user_id');
      await supabase.auth.updateUser(
        UserAttributes(data: {'language': result}),
      );
      message(
        'Preferência de idioma salva. A tradução completa das telas ainda não foi ativada.',
      );
    } catch (e) {
      message('Falha ao salvar idioma: $e');
    }
  }

  Future<void> vip() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WalletPage(title: 'VIP e decoração / carteira'),
      ),
    );
  }

  Future<void> agencyHost() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SolAgencyHostPage()));
  }

  Future<void> signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('A sessão será encerrada neste dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      message('Não foi possível sair: ${e.message}');
    }
  }

  Widget item(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) => Card(
    color: const Color(0xff0b1429),
    child: ListTile(
      onTap: busy ? null : onTap,
      leading: Icon(icon, color: const Color(0xffffd35a)),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    final metadata = currentUser?.userMetadata ?? const <String, dynamic>{};
    final avatarUrl = (metadata['avatar_url'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: busy ? null : signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: InkWell(
              onTap: busy ? null : editProfile,
              customBorder: const CircleBorder(),
              child: Tooltip(
                message: 'Toque para editar o perfil e o link da foto',
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xff172b55),
                  backgroundImage: avatarUrl.startsWith('http')
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.startsWith('http')
                      ? null
                      : const Icon(
                          Icons.person,
                          size: 44,
                          color: Color(0xffffd35a),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
            child: Text(
              currentUser?.email ?? 'Conta não conectada',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          if (metadata['region'] != null &&
              metadata['region'].toString().isNotEmpty)
            Center(
              child: Text(
                metadata['region'].toString(),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          const SizedBox(height: 20),
          item(Icons.edit, 'Editar perfil', editProfile),
          item(
            Icons.shield_outlined,
            'Segurança',
            security,
            subtitle: 'Alterar senha',
          ),
          item(Icons.people_outline, 'Amigos e contatos', contacts),
          item(Icons.block, 'Usuários bloqueados', blockedUsers),
          item(Icons.visibility_outlined, 'Visitantes', visitors),
          item(Icons.notifications_none, 'Notificações', notifications),
          item(
            Icons.language,
            'Idioma',
            language,
            subtitle: 'Português, English, العربية, Español',
          ),
          item(
            Icons.workspace_premium,
            'VIP e decoração',
            vip,
            subtitle: 'Abrir saldo e extrato',
          ),
          item(Icons.apartment, 'Agência / Host', agencyHost),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: busy ? null : signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}

class SolContactsPage extends StatefulWidget {
  const SolContactsPage({super.key});
  @override
  State<SolContactsPage> createState() => _SolContactsPageState();
}

class _SolContactsPageState extends State<SolContactsPage> {
  bool busy = false;
  final searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> profilesFuture;
  late Future<List<Map<String, dynamic>>> contactsFuture;
  String get currentId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    refresh();
    searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void refresh() {
    profilesFuture = supabase
        .from('sol_public_profiles')
        .select('user_id,display_name,region,avatar_url')
        .neq('user_id', currentId)
        .order('display_name')
        .limit(200);
    contactsFuture = supabase
        .from('sol_contacts')
        .select('id,owner_id,contact_user_id,status,created_at')
        .or('owner_id.eq.$currentId,contact_user_id.eq.$currentId')
        .order('created_at', ascending: false)
        .limit(300);
  }

  Future<Map<String, dynamic>?> profileFor(String id) async {
    final row = await supabase
        .from('sol_public_profiles')
        .select('user_id,display_name,region,avatar_url')
        .eq('user_id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> requestOrAccept(
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> rows,
  ) async {
    final target = profile['user_id'].toString();
    final incoming = rows
        .where(
          (r) =>
              r['owner_id'] == target &&
              r['contact_user_id'] == currentId &&
              r['status'] == 'pending',
        )
        .firstOrNull;
    final outgoing = rows
        .where(
          (r) =>
              r['owner_id'] == currentId &&
              r['contact_user_id'] == target &&
              r['status'] == 'pending',
        )
        .firstOrNull;
    final declined = rows.any(
      (r) =>
          r['status'] == 'declined' &&
          ((r['owner_id'] == currentId && r['contact_user_id'] == target) ||
              (r['owner_id'] == target && r['contact_user_id'] == currentId)),
    );
    final accepted = rows.any(
      (r) =>
          r['status'] == 'accepted' &&
          ((r['owner_id'] == currentId && r['contact_user_id'] == target) ||
              (r['owner_id'] == target && r['contact_user_id'] == currentId)),
    );
    setState(() => busy = true);
    try {
      if (incoming != null) {
        await supabase
            .from('sol_contacts')
            .update({
              'status': 'accepted',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', incoming['id']);
      } else if (accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta pessoa já está nos seus contatos.'),
          ),
        );
      } else if (declined) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este pedido foi recusado anteriormente.'),
            ),
          );
        }
      } else if (outgoing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Convite já enviado; aguardando resposta.'),
          ),
        );
      } else {
        await supabase.from('sol_contacts').insert({
          'owner_id': currentId,
          'contact_user_id': target,
          'status': 'pending',
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido de contato enviado.')),
          );
        }
      }
      if (mounted) setState(refresh);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar o contato: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openProfile(Map<String, dynamic> profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SolPublicProfilePage(profile: profile),
      ),
    );
  }

  Widget profileTile(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> contacts,
  ) {
    final name = (p['display_name'] ?? 'Usuário Sol').toString();
    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty &&
        !name.toLowerCase().contains(query) &&
        !(p['region'] ?? '').toString().toLowerCase().contains(query)) {
      return const SizedBox.shrink();
    }
    final id = p['user_id'].toString();
    final incoming = contacts.any(
      (r) =>
          r['owner_id'] == id &&
          r['contact_user_id'] == currentId &&
          r['status'] == 'pending',
    );
    final linked = contacts.any(
      (r) =>
          r['status'] == 'accepted' &&
          ((r['owner_id'] == id && r['contact_user_id'] == currentId) ||
              (r['owner_id'] == currentId && r['contact_user_id'] == id)),
    );
    final outgoing = contacts.any(
      (r) =>
          r['owner_id'] == currentId &&
          r['contact_user_id'] == id &&
          r['status'] == 'pending',
    );
    final label = incoming
        ? 'Aceitar pedido'
        : linked
        ? 'Conectado'
        : outgoing
        ? 'Enviado'
        : 'Conectar';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              ((p['avatar_url'] ?? '').toString().startsWith('http'))
              ? NetworkImage(p['avatar_url'].toString())
              : null,
          child: ((p['avatar_url'] ?? '').toString().startsWith('http'))
              ? null
              : const Icon(Icons.person),
        ),
        title: Text(name),
        subtitle: Text((p['region'] ?? '').toString()),
        onTap: () => openProfile(p),
        trailing: TextButton(
          onPressed: busy ? null : () => requestOrAccept(p, contacts),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Amigos e contatos'),
      actions: [
        IconButton(
          onPressed: () => setState(refresh),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([profilesFuture, contactsFuture]).then(
        (v) => [
          ...v[0],
          {'_contact_data': v[1]},
        ],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Falha ao carregar contatos: ${snapshot.error}'),
            ),
          );
        }
        final data = snapshot.data ?? [];
        final profiles = data.where((r) => r['_contact_data'] == null).toList();
        final contacts = List<Map<String, dynamic>>.from(
          (data.last['_contact_data'] as List?) ?? [],
        );
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Procurar perfil por nome ou região',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pedidos recebidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...contacts
                .where(
                  (r) =>
                      r['contact_user_id'] == currentId &&
                      r['status'] == 'pending',
                )
                .map((r) {
                  final id = r['owner_id'].toString();
                  final p = profiles
                      .where((x) => x['user_id'] == id)
                      .firstOrNull;
                  if (p == null) {
                    return ListTile(
                      title: Text('Pedido de usuário'),
                      subtitle: Text(id),
                    );
                  }
                  return profileTile(p, contacts);
                }),
            const SizedBox(height: 12),
            const Text(
              'Meus contatos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...contacts.where((r) => r['status'] == 'accepted').map((r) {
              final id = r['owner_id'] == currentId
                  ? r['contact_user_id'].toString()
                  : r['owner_id'].toString();
              final p = profiles.where((x) => x['user_id'] == id).firstOrNull;
              return p == null
                  ? const SizedBox.shrink()
                  : ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(p['display_name'].toString()),
                      subtitle: Text('Contato conectado'),
                      onTap: () => openProfile(p),
                    );
            }),
            const SizedBox(height: 12),
            const Text(
              'Encontrar pessoas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...profiles.map((p) => profileTile(p, contacts)),
            if (profiles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhum outro perfil foi criado no Sol ainda.'),
              ),
          ],
        );
      },
    ),
  );
}

class SolPublicProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const SolPublicProfilePage({super.key, required this.profile});
  @override
  State<SolPublicProfilePage> createState() => _SolPublicProfilePageState();
}

class _SolPublicProfilePageState extends State<SolPublicProfilePage> {
  bool busy = false;
  late Future<bool> connectedFuture;
  String get currentId => supabase.auth.currentUser!.id;
  String get targetId => widget.profile['user_id'].toString();

  @override
  void initState() {
    super.initState();
    _logVisit();
    connectedFuture = _isBlocked();
  }

  Future<void> _logVisit() async {
    if (targetId == currentId) return;
    try {
      await supabase.from('sol_profile_visits').upsert({
        'profile_user_id': targetId,
        'visitor_user_id': currentId,
        'last_visited_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_user_id,visitor_user_id');
    } catch (_) {}
  }

  Future<bool> _isBlocked() async =>
      await supabase
          .from('sol_blocked_users')
          .select('blocked_user_id')
          .eq('owner_id', currentId)
          .eq('blocked_user_id', targetId)
          .maybeSingle() !=
      null;

  Future<void> toggleBlock(bool isBlocked) async {
    setState(() => busy = true);
    try {
      if (isBlocked) {
        await supabase
            .from('sol_blocked_users')
            .delete()
            .eq('owner_id', currentId)
            .eq('blocked_user_id', targetId);
      } else {
        await supabase.from('sol_blocked_users').insert({
          'owner_id': currentId,
          'blocked_user_id': targetId,
        });
      }
      if (mounted) setState(() => connectedFuture = _isBlocked());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao alterar bloqueio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addContact() async {
    try {
      await supabase.from('sol_contacts').insert({
        'owner_id': currentId,
        'contact_user_id': targetId,
        'status': 'pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido de contato enviado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar o pedido: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil do usuário')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage:
              ((widget.profile['avatar_url'] ?? '').toString().startsWith(
                'http',
              ))
              ? NetworkImage(widget.profile['avatar_url'].toString())
              : null,
          child:
              ((widget.profile['avatar_url'] ?? '').toString().startsWith(
                'http',
              ))
              ? null
              : const Icon(Icons.person, size: 46),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            (widget.profile['display_name'] ?? 'Usuário Sol').toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Center(child: Text((widget.profile['region'] ?? '').toString())),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy ? null : addContact,
          icon: const Icon(Icons.person_add),
          label: const Text('Enviar pedido de contato'),
        ),
        FutureBuilder<bool>(
          future: connectedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            return OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => toggleBlock(snapshot.data ?? false),
              icon: Icon(
                snapshot.data == true
                    ? Icons.check_circle_outline
                    : Icons.block,
              ),
              label: Text(
                snapshot.data == true
                    ? 'Desbloquear usuário'
                    : 'Bloquear usuário',
              ),
            );
          },
        ),
      ],
    ),
  );
}

class SolBlockedUsersPage extends StatefulWidget {
  const SolBlockedUsersPage({super.key});
  @override
  State<SolBlockedUsersPage> createState() => _SolBlockedUsersPageState();
}

class _SolBlockedUsersPageState extends State<SolBlockedUsersPage> {
  late Future<List<Map<String, dynamic>>> future;
  String get currentId => supabase.auth.currentUser!.id;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    future = supabase
        .from('sol_blocked_users')
        .select('blocked_user_id,created_at')
        .eq('owner_id', currentId)
        .order('created_at', ascending: false)
        .then((rows) async {
          final ids = List<String>.from(
            rows.map((r) => r['blocked_user_id'].toString()),
          );
          if (ids.isEmpty) return <Map<String, dynamic>>[];
          final profiles = await supabase
              .from('sol_public_profiles')
              .select('user_id,display_name,region,avatar_url')
              .inFilter('user_id', ids);
          return List<Map<String, dynamic>>.from(profiles);
        });
  }

  Future<void> unblock(Map<String, dynamic> p) async {
    try {
      await supabase
          .from('sol_blocked_users')
          .delete()
          .eq('owner_id', currentId)
          .eq('blocked_user_id', p['user_id']);
      setState(refresh);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao desbloquear: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Usuários bloqueados'),
      actions: [
        IconButton(
          onPressed: () => setState(refresh),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Falha ao carregar bloqueios: ${snapshot.error}'),
          );
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text('Nenhum usuário bloqueado.'));
        }
        return ListView(
          children: rows
              .map(
                (p) => ListTile(
                  title: Text(p['display_name'].toString()),
                  subtitle: Text(p['region'].toString()),
                  trailing: TextButton(
                    onPressed: () => unblock(p),
                    child: const Text('Desbloquear'),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class SolVisitorsPage extends StatefulWidget {
  const SolVisitorsPage({super.key});
  @override
  State<SolVisitorsPage> createState() => _SolVisitorsPageState();
}

class _SolVisitorsPageState extends State<SolVisitorsPage> {
  late Future<List<Map<String, dynamic>>> future;
  String get currentId => supabase.auth.currentUser!.id;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    future = supabase
        .from('sol_profile_visits')
        .select('visitor_user_id,last_visited_at')
        .eq('profile_user_id', currentId)
        .order('last_visited_at', ascending: false)
        .limit(100)
        .then((rows) async {
          final ids = List<String>.from(
            rows.map((r) => r['visitor_user_id'].toString()),
          );
          if (ids.isEmpty) return <Map<String, dynamic>>[];
          final profiles = await supabase
              .from('sol_public_profiles')
              .select('user_id,display_name,region,avatar_url')
              .inFilter('user_id', ids);
          final lookup = {
            for (final p in profiles)
              p['user_id'].toString(): Map<String, dynamic>.from(p),
          };
          return ids
              .map((id) => lookup[id])
              .whereType<Map<String, dynamic>>()
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Visitantes'),
      actions: [
        IconButton(
          onPressed: () => setState(refresh),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Falha ao carregar visitantes: ${snapshot.error}'),
          );
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text('Ainda não há visitas registradas.'));
        }
        return ListView(
          children: rows
              .map(
                (p) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(p['display_name'].toString()),
                  subtitle: Text(p['region'].toString()),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => SolPublicProfilePage(profile: p),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class SolAgencyHostPage extends StatefulWidget {
  const SolAgencyHostPage({super.key});
  @override
  State<SolAgencyHostPage> createState() => _SolAgencyHostPageState();
}

class _SolAgencyHostPageState extends State<SolAgencyHostPage> {
  String type = 'host';
  bool busy = false;
  final details = TextEditingController();
  late Future<List<Map<String, dynamic>>> future;
  String get currentId => supabase.auth.currentUser!.id;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  void refresh() {
    future = supabase
        .from('sol_agency_applications')
        .select('id,application_type,message,status,created_at')
        .eq('user_id', currentId)
        .order('created_at', ascending: false)
        .limit(50)
        .then((r) => List<Map<String, dynamic>>.from(r));
  }

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      final pending = await supabase
          .from('sol_agency_applications')
          .select('id')
          .eq('user_id', currentId)
          .eq('application_type', type)
          .eq('status', 'pending')
          .maybeSingle();
      if (!mounted) return;
      if (pending != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Já existe uma solicitação pendente deste tipo.'),
          ),
        );
      } else {
        await supabase.from('sol_agency_applications').insert({
          'user_id': currentId,
          'application_type': type,
          'message': details.text.trim(),
          'status': 'pending',
        });
        if (!mounted) return;
        details.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada para análise.')),
        );
      }
      if (mounted) setState(refresh);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar a solicitação: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Agência / Host')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Solicitar participação',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'host', label: Text('Host')),
            ButtonSegment(value: 'agency', label: Text('Agência')),
          ],
          selected: {type},
          onSelectionChanged: busy
              ? null
              : (v) => setState(() => type = v.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: details,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Apresente sua solicitação (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Enviando…' : 'Enviar solicitação'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Minhas solicitações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Falha ao carregar solicitações: ${snapshot.error}');
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhuma solicitação enviada.'),
              );
            }
            return Column(
              children: rows
                  .map(
                    (r) => ListTile(
                      leading: Icon(
                        r['application_type'] == 'agency'
                            ? Icons.apartment
                            : Icons.mic,
                      ),
                      title: Text(
                        r['application_type'] == 'agency' ? 'Agência' : 'Host',
                      ),
                      subtitle: Text((r['message'] ?? '').toString()),
                      trailing: Text(r['status'].toString()),
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
