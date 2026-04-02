import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/messenger_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<MessengerService>();
    final id  = svc.identity;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sozlamalar', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(children: [

        // ── Identity ──────────────────────────────────────────────────────────
        _Section('Mening identifikatorim'),
        if (id != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(color: AppTheme.bgTertiary, shape: BoxShape.circle),
                    child: Center(child: Text(id.initials, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.accent,
                    ))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Public Key (mening adresim)', style: TextStyle(
                      fontSize: 11, color: AppTheme.textHint, letterSpacing: 0.3,
                    )),
                    const SizedBox(height: 4),
                    Text(id.publicKeyShort, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.accent,
                    )),
                  ])),
                ]),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.divider, height: 1),
                const SizedBox(height: 12),
                SelectableText(
                  id.publicKey,
                  style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary,
                    fontFamily: 'monospace', height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _ActionBtn(
                    icon: Icons.copy,
                    label: 'Nusxa olish',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: id.publicKey));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Public key nusxa olindi'),
                        backgroundColor: AppTheme.bgTertiary,
                        duration: Duration(seconds: 2),
                      ));
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionBtn(
                    icon: Icons.share,
                    label: 'Ulashish',
                    onTap: () {
                      // Share plugin bilan ulashish
                    },
                  )),
                ]),
                const SizedBox(height: 4),
                const Text(
                  'Bu adresingizni kontaktlaringizga yuboring. '
                  'Telefon raqami yoki email kerak emas.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textHint, height: 1.4),
                ),
              ]),
            ),
          ),
        ],

        // ── Network ───────────────────────────────────────────────────────────
        _Section('Tarmoq'),
        _Tile(
          icon: Icons.router_outlined,
          title: 'Ulangan peerlar',
          subtitle: '${svc.peerCount} ta aktiv peer',
          trailing: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: svc.peerCount > 0 ? AppTheme.green : AppTheme.textHint,
              shape: BoxShape.circle,
            ),
          ),
        ),
        _SwitchTile(
          icon: Icons.security,
          iconColor: const Color(0xFF7B61FF),
          title: 'Tor routing',
          subtitle: svc.torEnabled
              ? 'Barcha ulanishlar Tor orqali'
              : 'IP manzil ko\'rinadi',
          value: svc.torEnabled,
          onChanged: (v) => svc.setTorEnabled(v),
        ),
        if (svc.torEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFF7B61FF), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Tor uchun qurilmada Tor Browser yoki Orbot o\'rnatilgan bo\'lishi kerak',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB3A8FF)),
                )),
              ]),
            ),
          ),

        // ── Xavfsizlik ───────────────────────────────────────────────────────
        _Section('Xavfsizlik'),
        _InfoCard(items: const [
          _InfoItem(icon: Icons.lock, color: AppTheme.accent, label: 'End-to-End Encryption', desc: 'X3DH + Double Ratchet (Signal protokoli)'),
          _InfoItem(icon: Icons.refresh, color: AppTheme.green, label: 'Perfect Forward Secrecy', desc: 'Har xabar yangi kalit bilan shifrlangan'),
          _InfoItem(icon: Icons.verified_user, color: AppTheme.orange, label: 'Nol server', desc: 'Markaziy server yo\'q, hech kim kuzatmaydi'),
          _InfoItem(icon: Icons.storage, color: Color(0xFF7B61FF), label: 'Shifrlangan storage', desc: 'Barcha ma\'lumotlar AES-256-GCM bilan'),
        ]),

        // ── Xavfli zona ──────────────────────────────────────────────────────
        _Section('Xavfli zona'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever, color: AppTheme.red),
            label: const Text('Barcha ma\'lumotlarni o\'chirish',
                style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w600)),
            onPressed: () => _confirmDelete(context, svc),
          ),
        ),
        const SizedBox(height: 32),
        const Center(child: Text(
          'PrivMsg v1.0.0 — Hech qanday server, hech qanday log',
          style: TextStyle(fontSize: 11, color: AppTheme.textHint),
        )),
        const SizedBox(height: 24),
      ]),
    );
  }

  void _confirmDelete(BuildContext context, MessengerService svc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Ishonchingiz komilmi?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Barcha xabarlar, kontaktlar va kalit ma\'lumotlar o\'chiriladi. '
          'Bu amalni qaytarib bo\'lmaydi.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () async {
              await svc.deleteAllData();
              if (ctx.mounted) {
                Navigator.of(ctx).popUntil((r) => r.isFirst);
              }
            },
            child: const Text('O\'chirish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title.toUpperCase(), style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: AppTheme.accent, letterSpacing: 0.8,
    )),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _Tile({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: AppTheme.bgSecondary,
    leading: Icon(icon, color: AppTheme.accent),
    title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
    subtitle: Text(subtitle, style: AppTheme.caption),
    trailing: trailing,
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: AppTheme.bgSecondary,
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: iconColor, size: 20),
    ),
    title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
    subtitle: Text(subtitle, style: AppTheme.caption),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.accent,
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppTheme.bgTertiary),
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    icon: Icon(icon, color: AppTheme.accent, size: 16),
    label: Text(label, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
    onPressed: onTap,
  );
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: items.map((item) => ListTile(
        dense: true,
        leading: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.color, size: 17),
        ),
        title: Text(item.label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(item.desc, style: AppTheme.caption),
      )).toList()),
    ),
  );
}

class _InfoItem {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;
  const _InfoItem({required this.icon, required this.color, required this.label, required this.desc});
}
