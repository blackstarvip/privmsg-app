import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/messenger_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    context.read<MessengerService>().markRead(widget.chat.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    await context.read<MessengerService>().sendMessage(widget.chat.id, text);
    setState(() => _sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<MessengerService>();
    final messages = svc.messagesFor(widget.chat.id);
    final contact = svc.contactFor(widget.chat.id);
    final name = contact?.displayName ?? widget.chat.name;
    final isGroup = widget.chat.type == ChatType.group;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accent),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _showInfo(context, svc, name, isGroup),
          child: Row(children: [
            _avatar(widget.chat.initials, isGroup),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                ), overflow: TextOverflow.ellipsis),
                Text(
                  isGroup
                      ? '${widget.chat.memberKeys.length} a\'zo'
                      : (contact?.isOnline == true ? 'onlayn' : 'E2EE shifrlangan'),
                  style: AppTheme.caption.copyWith(
                    color: contact?.isOnline == true ? AppTheme.green : AppTheme.textHint,
                  ),
                ),
              ],
            )),
          ]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: Column(children: [
        // Security banner
        Container(
          color: AppTheme.bgTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.lock, size: 13, color: AppTheme.accent),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Xabarlar X3DH + Double Ratchet bilan shifrlangan. Hech kim o\'qiy olmaydi.',
              style: AppTheme.caption.copyWith(color: AppTheme.textHint),
            )),
          ]),
        ),
        // Messages
        Expanded(child: messages.isEmpty
            ? const _EmptyChat()
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (ctx, i) {
                  final msg = messages[i];
                  final prevMsg = i > 0 ? messages[i - 1] : null;
                  final showDate = prevMsg == null ||
                      !_sameDay(prevMsg.timestamp, msg.timestamp);
                  return Column(children: [
                    if (showDate) _DateDivider(date: msg.timestamp),
                    _MessageBubble(msg: msg),
                  ]);
                },
              )),
        // Input bar
        _InputBar(
          controller: _textCtrl,
          sending: _sending,
          onSend: _send,
        ),
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _avatar(String initials, bool isGroup) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: isGroup ? AppTheme.surfaceLight : AppTheme.bgTertiary,
        shape: BoxShape.circle,
      ),
      child: Center(child: Text(initials, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: isGroup ? Colors.white : AppTheme.accent,
      ))),
    );
  }

  void _showInfo(BuildContext context, MessengerService svc, String name, bool isGroup) {
    final contact = svc.contactFor(widget.chat.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isGroup ? AppTheme.surfaceLight : AppTheme.bgTertiary,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(
              widget.chat.initials,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                color: isGroup ? Colors.white : AppTheme.accent),
            )),
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTheme.title.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(widget.chat.shortId, style: AppTheme.caption),
          const SizedBox(height: 16),
          if (contact != null) ...[
            ListTile(
              leading: const Icon(Icons.key, color: AppTheme.accent),
              title: const Text('Public Key', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              subtitle: Text(contact.publicKey, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontFamily: 'monospace')),
              trailing: IconButton(
                icon: const Icon(Icons.copy, color: AppTheme.accent, size: 18),
                onPressed: () => Clipboard.setData(ClipboardData(text: contact.publicKey)),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppTheme.textHint, borderRadius: BorderRadius.circular(2)),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: AppTheme.red),
          title: const Text('Suhbatni o\'chirish', style: TextStyle(color: AppTheme.red)),
          onTap: () { Navigator.pop(context); Navigator.pop(context); },
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgTertiary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg.text, style: AppTheme.caption, textAlign: TextAlign.center),
      );
    }

    final isOut = msg.isOutgoing;
    return Padding(
      padding: EdgeInsets.only(
        left: isOut ? 52 : 0,
        right: isOut ? 0 : 52,
        top: 2, bottom: 2,
      ),
      child: Align(
        alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => Clipboard.setData(ClipboardData(text: msg.text)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOut ? AppTheme.bubbleOut : AppTheme.bubbleIn,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(16),
                topRight:    const Radius.circular(16),
                bottomLeft:  Radius.circular(isOut ? 16 : 4),
                bottomRight: Radius.circular(isOut ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: isOut ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.text, style: AppTheme.message),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(DateFormat('HH:mm').format(msg.timestamp), style: AppTheme.time),
                  if (isOut) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.status == MessageStatus.delivered ? Icons.done_all : Icons.done,
                      size: 13,
                      color: msg.status == MessageStatus.delivered ? AppTheme.accent : AppTheme.textHint,
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (now.difference(date).inDays == 0) {
      label = 'Bugun';
    } else if (now.difference(date).inDays == 1) {
      label = 'Kecha';
    } else {
      label = DateFormat('d MMMM, yyyy').format(date);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: AppTheme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label, style: AppTheme.caption),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.divider)),
      ]),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 5, minLines: 1,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Xabar yozing…',
                hintStyle: const TextStyle(color: AppTheme.textHint),
                filled: true,
                fillColor: AppTheme.bgTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: sending ? AppTheme.accentDark : AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 12),
        Text('Xabarlar shifrlangan', style: AppTheme.subtitle),
        const SizedBox(height: 4),
        Text('Hech kim o\'qiy olmaydi', style: AppTheme.caption),
      ],
    ));
  }
}
