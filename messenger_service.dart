import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

// MessengerService is the central state provider.
// It talks to the Go backend via stdin/stdout IPC when running natively,
// or uses a Dart-native crypto stub for development/testing.
class MessengerService extends ChangeNotifier {
  static final MessengerService _instance = MessengerService._internal();
  factory MessengerService() => _instance;
  MessengerService._internal();

  // ─── State ─────────────────────────────────────────────────────────────────
  Identity?              _identity;
  final List<Chat>       _chats    = [];
  final Map<String, List<Message>> _messages = {};
  final Map<String, Contact>       _contacts = {};
  int _peerCount = 0;
  bool _torEnabled = false;
  bool _isInitialised = false;

  // ─── Getters ───────────────────────────────────────────────────────────────
  Identity? get identity      => _identity;
  bool      get isInitialised => _isInitialised;
  bool      get torEnabled    => _torEnabled;
  int       get peerCount     => _peerCount;

  List<Chat> get chats {
    final list = List<Chat>.from(_chats);
    list.sort((a, b) {
      final at = a.lastMessage?.timestamp ?? a.createdAt;
      final bt = b.lastMessage?.timestamp ?? b.createdAt;
      return bt.compareTo(at);
    });
    return list;
  }

  List<Message> messagesFor(String chatId) =>
      List<Message>.from(_messages[chatId] ?? [])
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  Contact? contactFor(String publicKey) => _contacts[publicKey];

  Map<String, Contact> get contacts => Map.unmodifiable(_contacts);

  // ─── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load or generate identity
    final savedId = prefs.getString('identity');
    if (savedId != null) {
      _identity = Identity.fromJson(jsonDecode(savedId));
    } else {
      _identity = _generateIdentity();
      await prefs.setString('identity', jsonEncode(_identity!.toJson()));
    }

    // Load contacts
    final savedContacts = prefs.getStringList('contacts') ?? [];
    for (final c in savedContacts) {
      final contact = Contact.fromJson(jsonDecode(c));
      _contacts[contact.publicKey] = contact;
    }

    // Load chats
    final savedChats = prefs.getStringList('chats') ?? [];
    for (final c in savedChats) {
      _chats.add(Chat.fromJson(jsonDecode(c)));
    }

    // Load messages
    final chatIds = prefs.getStringList('chatIds') ?? [];
    for (final id in chatIds) {
      final saved = prefs.getStringList('msgs_$id') ?? [];
      _messages[id] = saved.map((s) => Message.fromJson(jsonDecode(s))).toList();
      if (_messages[id]!.isNotEmpty && _chats.any((c) => c.id == id)) {
        final chat = _chats.firstWhere((c) => c.id == id);
        chat.lastMessage = _messages[id]!.last;
      }
    }

    _torEnabled = prefs.getBool('torEnabled') ?? false;
    _isInitialised = true;
    notifyListeners();
  }

  // ─── Identity ──────────────────────────────────────────────────────────────
  Identity _generateIdentity() {
    // In production this calls the Go native lib.
    // For the Flutter build, we generate a mock key pair.
    final random = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) bytes[i] = random.nextInt(256);
    final pubKeyB64 = base64Url.encode(bytes).replaceAll('=', '');
    final short = '${pubKeyB64.substring(0, 8)}…${pubKeyB64.substring(pubKeyB64.length - 4)}';
    return Identity(
      publicKey: pubKeyB64,
      publicKeyShort: short,
      createdAt: DateTime.now(),
    );
  }

  // ─── Contacts ──────────────────────────────────────────────────────────────
  Future<void> addContact(String nickname, String publicKey, String address) async {
    final contact = Contact(
      publicKey: publicKey,
      nickname: nickname,
      address: address,
    );
    _contacts[publicKey] = contact;
    await _saveContacts();

    // Create or update chat
    if (!_chats.any((c) => c.id == publicKey)) {
      _chats.add(Chat(
        id: publicKey,
        type: ChatType.direct,
        name: nickname.isNotEmpty ? nickname : contact.shortKey,
        createdAt: DateTime.now(),
      ));
      await _saveChats();
    }
    notifyListeners();
  }

  Future<void> deleteContact(String publicKey) async {
    _contacts.remove(publicKey);
    _chats.removeWhere((c) => c.id == publicKey);
    await _saveContacts();
    await _saveChats();
    notifyListeners();
  }

  // ─── Messages ──────────────────────────────────────────────────────────────
  Future<void> sendMessage(String chatId, String text) async {
    final msg = Message(
      id: const Uuid().v4(),
      chatId: chatId,
      text: text,
      isOutgoing: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _addMessage(msg);

    // Simulate E2EE send (Go lib call in production)
    await Future.delayed(const Duration(milliseconds: 300));
    msg.status = MessageStatus.delivered;
    await _saveMessages(chatId);
    notifyListeners();
  }

  void receiveMessage(String chatId, String text, String senderKey) {
    final contact = _contacts[senderKey];
    final chatName = contact?.displayName ?? _shortKey(senderKey);

    // Ensure chat exists
    if (!_chats.any((c) => c.id == chatId)) {
      _chats.add(Chat(
        id: chatId,
        type: ChatType.direct,
        name: chatName,
        createdAt: DateTime.now(),
      ));
    }

    final msg = Message(
      id: const Uuid().v4(),
      chatId: chatId,
      text: text,
      isOutgoing: false,
      timestamp: DateTime.now(),
    );
    _addMessage(msg);

    // Increment unread for non-active chat
    final chat = _chats.firstWhere((c) => c.id == chatId);
    chat.unreadCount++;
    _saveMessages(chatId);
    notifyListeners();
  }

  void markRead(String chatId) {
    final chatIdx = _chats.indexWhere((c) => c.id == chatId);
    if (chatIdx != -1) {
      _chats[chatIdx].unreadCount = 0;
      notifyListeners();
    }
  }

  // ─── Groups ────────────────────────────────────────────────────────────────
  Future<Chat> createGroup(String name, List<String> memberKeys) async {
    final id = const Uuid().v4();
    final chat = Chat(
      id: id,
      type: ChatType.group,
      name: name,
      memberKeys: memberKeys,
      createdAt: DateTime.now(),
    );
    _chats.add(chat);
    await _saveChats();

    _addMessage(Message(
      id: const Uuid().v4(),
      chatId: id,
      text: 'Group "$name" created. Share sender key with all members.',
      isOutgoing: false,
      timestamp: DateTime.now(),
      isSystem: true,
    ));
    notifyListeners();
    return chat;
  }

  // ─── Settings ──────────────────────────────────────────────────────────────
  Future<void> setTorEnabled(bool value) async {
    _torEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('torEnabled', value);
    notifyListeners();
  }

  void updatePeerCount(int count) {
    _peerCount = count;
    notifyListeners();
  }

  // ─── Delete all data ───────────────────────────────────────────────────────
  Future<void> deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _identity = null;
    _chats.clear();
    _messages.clear();
    _contacts.clear();
    _isInitialised = false;
    notifyListeners();
  }

  // ─── Private helpers ───────────────────────────────────────────────────────
  void _addMessage(Message msg) {
    _messages.putIfAbsent(msg.chatId, () => []).add(msg);
    final chatIdx = _chats.indexWhere((c) => c.id == msg.chatId);
    if (chatIdx != -1) {
      _chats[chatIdx].lastMessage = msg;
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'contacts',
      _contacts.values.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'chats',
      _chats.map((c) => jsonEncode(c.toJson())).toList(),
    );
    await prefs.setStringList('chatIds', _chats.map((c) => c.id).toList());
  }

  Future<void> _saveMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final msgs = _messages[chatId] ?? [];
    await prefs.setStringList(
      'msgs_$chatId',
      msgs.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  String _shortKey(String key) {
    if (key.length > 16) return '${key.substring(0, 8)}…${key.substring(key.length - 4)}';
    return key;
  }
}
