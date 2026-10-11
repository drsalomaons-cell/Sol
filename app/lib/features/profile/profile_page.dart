import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(radius: 42, backgroundColor: Color(0xff172b55), child: Icon(Icons.person, size: 44)),
            const SizedBox(height: 12),
            const Center(child: Text('UsuÃ¡rio Sol', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            const Center(child: Text('Perfil â€¢ seguranÃ§a â€¢ contatos', style: TextStyle(color: Colors.white54))),
            const SizedBox(height: 20),
            _item(Icons.edit, 'Editar perfil'),
            _item(Icons.shield_outlined, 'SeguranÃ§a'),
            _item(Icons.people_outline, 'Amigos e contatos'),
            _item(Icons.block, 'UsuÃ¡rios bloqueados'),
            _item(Icons.visibility_outlined, 'Visitantes'),
            _item(Icons.notifications_none, 'NotificaÃ§Ãµes'),
            _item(Icons.language, 'Idioma'),
            _item(Icons.workspace_premium, 'VIP e decoraÃ§Ã£o'),
            _item(Icons.apartment, 'AgÃªncia / Host'),
          ],
        ),
      );

  static Widget _item(IconData icon, String title) => Card(
        color: const Color(0xff0b1429),
        child: ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right)),
      );
}

