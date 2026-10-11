import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool createAccount = false;

  Future<void> submit() async {
    final address = email.text.trim();
    final pass = password.text;
    if (address.isEmpty || pass.length < 6) {
      _message('Informe o e-mail e uma senha com pelo menos 6 caracteres.');
      return;
    }
    setState(() => busy = true);
    try {
      if (createAccount) {
        await supabase.auth.signUp(email: address, password: pass);
        if (mounted) _message('Cadastro enviado. Se a confirmação por e-mail estiver ativa, confirme seu e-mail antes de entrar.');
      } else {
        await supabase.auth.signInWithPassword(email: address, password: pass);
      }
    } on AuthException catch (e) {
      if (mounted) _message(e.message);
    } catch (e) {
      if (mounted) _message('Falha ao acessar o serviço: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wb_sunny_outlined, size: 58, color: Color(0xffffd35a)),
    const SizedBox(height: 10),
    const Text('SOL', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 5)),
    const SizedBox(height: 8),
    Text(createAccount ? 'Criar conta' : 'Entrar', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
    const SizedBox(height: 20),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
    const SizedBox(height: 16),
    SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Aguarde…' : createAccount ? 'Criar conta' : 'Entrar'))),
    TextButton(onPressed: busy ? null : () => setState(() => createAccount = !createAccount), child: Text(createAccount ? 'Já tenho conta' : 'Ainda não tenho conta')),
    const Text('O acesso depende da configuração de autenticação do Supabase.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
  ]))))));
}
