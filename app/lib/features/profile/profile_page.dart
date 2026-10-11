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
  }

  @override
  void dispose() {
    nameController.dispose();
    regionController.dispose();
    super.dispose();
  }

  String get displayName {
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final saved = (metadata['display_name'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    if (saved.isNotEmpty) return saved;
    final email = user?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'Usuário Sol';
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> editProfile() async {
    nameController.text = displayName;
    regionController.text = (user?.userMetadata?['region'] ?? '').toString();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Nome de exibição',
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  return v.length < 2
                      ? 'Informe pelo menos 2 caracteres.'
                      : null;
                },
              ),
              TextFormField(
                controller: regionController,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'País/região (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              Text('Conta: ${user?.email ?? 'sem e-mail'}'),
            ],
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
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': nameController.text.trim(),
            'region': regionController.text.trim(),
          },
        ),
      );
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
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Amigos e contatos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A agenda e os convites dependem de uma lista de contatos compartilhada entre contas.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'E-mail para convite',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Preparar convite'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: result,
      queryParameters: {'subject': 'Vamos conversar no Sol'},
    );
    message('Convite preparado: ${uri.toString()}');
  }

  Future<void> blockedUsers() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuários bloqueados'),
        content: const Text(
          'O Sol ainda não tem uma lista persistente de bloqueios no banco. Este controle não será apresentado como ativo até a tabela e as regras de segurança serem configuradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> visitors() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Visitantes'),
        content: const Text(
          'O banco atual não registra visitas de perfil. A lista ficará disponível quando o registro de visitas for implementado, para não mostrar dados inventados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> notifications() async {
    var push = (user?.userMetadata?['notifications_push'] as bool?) ?? true;
    var room = (user?.userMetadata?['notifications_room'] as bool?) ?? true;
    var friends =
        (user?.userMetadata?['notifications_friends'] as bool?) ?? true;
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
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'notifications_push': result[0],
            'notifications_room': result[1],
            'notifications_friends': result[2],
          },
        ),
      );
      message('Preferências salvas na conta.');
    } on AuthException catch (e) {
      message('Não foi possível salvar: ${e.message}');
    }
  }

  Future<void> language() async {
    final options = <String, String>{
      'pt': 'Português',
      'en': 'English',
      'ar': 'العربية',
      'es': 'Español',
    };
    var selected = (user?.userMetadata?['language'] ?? 'pt').toString();
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
    if (result == null || user == null) return;
    try {
      await supabase.auth.updateUser(
        UserAttributes(data: {'language': result}),
      );
      message(
        'Preferência de idioma salva. A tradução automática das telas será ativada quando o catálogo de idiomas for integrado.',
      );
    } on AuthException catch (e) {
      message('Não foi possível salvar: ${e.message}');
    }
  }

  Future<void> vip() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const WalletPage()));
  }

  Future<void> agencyHost() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agência / Host'),
        content: const Text(
          'A área de agência e host ainda precisa das tabelas de cadastro, aprovação e métricas. Não há dados de agência disponíveis para esta conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
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
            subtitle: 'Abrir carteira e saldo real',
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