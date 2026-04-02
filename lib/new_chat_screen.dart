import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/messenger_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _nickCtrl    = TextEditingController();
  final _keyCtrl     = TextEditingController();
  final _addrCtrl    = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  bool _loading      = false;

  @override
  void dispose() {
    _nickCtrl.dispose();
    _keyCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final svc = context.read<MessengerService>();
    await svc.addContact(
      _nickCtrl.text.trim(),
      _keyCtrl.text.trim(),
      _addrCtrl.text.trim(),
    );
    setState(() => _loading = false);
    if (mounted) {
      final chat = svc.chats.firstWhere((c) => c.id == _keyCtrl.text.trim());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Yangi suhbat', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text(
                  'Kontaktingizdan uning public key va IP:port manzilini so\'rang. '
                  'Bularni xavfsiz kanal orqali (yuzma-yuz, Signal) almashing.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 28),

            _label('Laqab (ixtiyoriy)'),
            const SizedBox(height: 8),
            _field(
              controller: _nickCtrl,
              hint: 'Masalan: Ali, Do\'stim…',
              icon: Icons.person_outline,
              validator: (_) => null,
            ),
            const SizedBox(height: 20),

            _label('Public Key *'),
            const SizedBox(height: 8),
            _field(
              controller: _keyCtrl,
              hint: 'Base64 Ed25519 public key',
              icon: Icons.key_outlined,
              validator: (v) => (v == null || v.trim().length < 20) ? 'Noto\'g\'ri kalit' : null,
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste, color: AppTheme.accent, size: 18),
                onPressed: () async {
                  final d = await Clipboard.getData('text/plain');
                  if (d?.text != null) _keyCtrl.text = d!.text!.trim();
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kontaktingizning /id buyrug\'i chiqargan to\'liq addressi',
              style: TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
            const SizedBox(height: 20),

            _label('IP:Port *'),
            const SizedBox(height: 8),
            _field(
              controller: _addrCtrl,
              hint: 'Masalan: 192.168.1.5:4001',
              icon: Icons.router_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Manzil kiritish shart';
                if (!v.contains(':')) return 'Format: IP:port';
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Kontaktingiz Privacy Messenger ishga tushirgan qurilmaning IP va port raqami',
              style: TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _add,
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kontakt qo\'shish va suhbat boshlash',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(
    color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3,
  ));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textHint),
        filled: true,
        fillColor: AppTheme.bgSecondary,
        prefixIcon: Icon(icon, color: AppTheme.textHint, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.bgTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.bgTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
