import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/messenger_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'settings_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<MessengerService>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        leading: _searching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.accent),
                onPressed: () => setState(() { _searching = false; _query = ''; _searchCtrl.clear(); }),
              )
            : IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.textSecondary),
                onPressed: () => _showDrawer(context),
              ),
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Qidirish…',
                  hintStyle: TextStyle(color: AppTheme.textHint),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PrivMsg', style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                  )),
                  Row(children: [
                    Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: AppTheme.green, shape: BoxShape.circle,
                      ),
                    ),
                    Text('${svc.peerCount} peers', style: AppTheme.caption),
                    if (svc.torEnabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('TOR', style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.accent,
                          letterSpacing: 0.5,
                        )),
                      ),
                    ],
                  ]),
                ],
              ),
        actions: [
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.search, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _searching = true),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [Tab(text: 'Suhbatlar'), Tab(text: 'Kontaktlar')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChatsTab(query: _query),
          _ContactsTab(query: _query),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen())),
      ),
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.textHint, borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppTheme.accent),
            title: const Text('Sozlamalar', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add_outlined, color: AppTheme.accent),
            title: const Text('Guruh yaratish', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () { Navigator.pop(context); _createGroup(context); },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _createGroup(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Guruh yaratish', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'Guruh nomi'),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () async {
              final svc = context.read<MessengerService>();
              final chat = await svc.createGroup(nameCtrl.text.trim(), []);
              Navigator.pop(ctx);
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
              }
            },
            child: const Text('Yaratish'),
          ),
        ],
      ),
    );
  }
}

// ─── Chats tab ────────────────────────────────────────────────────────────────

class _ChatsTab extends StatelessWidget {
  final String query;
  const _ChatsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<MessengerService>();
    final chats = svc.chats.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
             c.lastMessage?.text.toLowerCase().contains(query) == true;
    }).toList();

    if (chats.isEmpty) {
      return _EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Suhbatlar yo\'q',
        subtitle: 'Yangi suhbat boshlash uchun\ntahrirlash tugmasini bosing',
      );
    }

    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider, indent: 72),
      itemBuilder: (context, i) => _ChatTile(chat: chats[i]),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<MessengerService>();
    final contact = svc.contactFor(chat.id);
    final name = contact?.displayName ?? chat.name;
    final lastMsg = chat.lastMessage;
    final isGroup = chat.type == ChatType.group;

    return InkWell(
      onTap: () {
        svc.markRead(chat.id);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          _Avatar(initials: chat.initials, isGroup: isGroup, size: 52),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(name, style: AppTheme.title.copyWith(fontSize: 16), overflow: TextOverflow.ellipsis)),
                if (lastMsg != null)
                  Text(
                    _formatTime(lastMsg.timestamp),
                    style: AppTheme.time.copyWith(
                      color: chat.unreadCount > 0 ? AppTheme.accent : AppTheme.textHint,
                    ),
                  ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                if (lastMsg?.isOutgoing == true)
                  const Icon(Icons.done_all, size: 14, color: AppTheme.accent),
                if (lastMsg?.isOutgoing == true) const SizedBox(width: 3),
                Expanded(child: Text(
                  lastMsg?.text ?? 'Xabar yo\'q',
                  style: AppTheme.subtitle.copyWith(
                    color: lastMsg == null ? AppTheme.textHint : AppTheme.textSecondary,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
                if (chat.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${chat.unreadCount}', style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
                    )),
                  ),
              ]),
            ],
          )),
        ]),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays == 0) return DateFormat('HH:mm').format(t);
    if (now.difference(t).inDays < 7) return DateFormat('E').format(t);
    return DateFormat('dd.MM').format(t);
  }
}

// ─── Contacts tab ─────────────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  final String query;
  const _ContactsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<MessengerService>();
    final contacts = svc.contacts.values.where((c) {
      if (query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(query) ||
             c.publicKey.toLowerCase().contains(query);
    }).toList();

    if (contacts.isEmpty) {
      return _EmptyState(
        icon: Icons.person_add_outlined,
        title: 'Kontaktlar yo\'q',
        subtitle: 'Yangi kontakt qo\'shish uchun\ntahrirlash tugmasini bosing',
      );
    }

    return ListView.separated(
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider, indent: 72),
      itemBuilder: (context, i) {
        final c = contacts[i];
        return ListTile(
          leading: _Avatar(initials: c.initials, isGroup: false, size: 48),
          title: Text(c.displayName, style: AppTheme.title.copyWith(fontSize: 15)),
          subtitle: Text(c.shortKey, style: AppTheme.caption),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: c.isOnline ? AppTheme.green : AppTheme.textHint,
                shape: BoxShape.circle,
              ),
            ),
          ]),
          onTap: () {
            final chat = svc.chats.firstWhere(
              (ch) => ch.id == c.publicKey,
              orElse: () => Chat(
                id: c.publicKey, type: ChatType.direct,
                name: c.displayName, createdAt: DateTime.now(),
              ),
            );
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
          },
        );
      },
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final bool isGroup;
  final double size;
  const _Avatar({required this.initials, required this.isGroup, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: isGroup ? AppTheme.surfaceLight : AppTheme.bgTertiary,
        shape: BoxShape.circle,
      ),
      child: Center(child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: isGroup ? Colors.white : AppTheme.accent,
        ),
      )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: AppTheme.textHint),
        const SizedBox(height: 16),
        Text(title, style: AppTheme.title.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTheme.subtitle, textAlign: TextAlign.center),
      ],
    ));
  }
}
