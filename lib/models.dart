import 'dart:convert';

// ─── Identity ─────────────────────────────────────────────────────────────────

class Identity {
  final String publicKey;   // base64 Ed25519 — user's address
  final String publicKeyShort;
  final DateTime createdAt;

  const Identity({
    required this.publicKey,
    required this.publicKeyShort,
    required this.createdAt,
  });

  String get initials {
    if (publicKeyShort.length >= 2) return publicKeyShort.substring(0, 2).toUpperCase();
    return 'ME';
  }

  Map<String, dynamic> toJson() => {
    'publicKey': publicKey,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Identity.fromJson(Map<String, dynamic> j) => Identity(
    publicKey: j['publicKey'] as String,
    publicKeyShort: (j['publicKey'] as String).length > 12
        ? '${(j['publicKey'] as String).substring(0, 8)}…${(j['publicKey'] as String).substring((j['publicKey'] as String).length - 4)}'
        : j['publicKey'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

// ─── Contact ──────────────────────────────────────────────────────────────────

class Contact {
  final String publicKey;
  String nickname;
  final String address;   // host:port for direct TCP
  bool isOnline;
  DateTime? lastSeen;

  Contact({
    required this.publicKey,
    required this.nickname,
    required this.address,
    this.isOnline = false,
    this.lastSeen,
  });

  String get displayName => nickname.isNotEmpty ? nickname : shortKey;

  String get shortKey {
    if (publicKey.length > 16) {
      return '${publicKey.substring(0, 8)}…${publicKey.substring(publicKey.length - 4)}';
    }
    return publicKey;
  }

  String get initials {
    final n = displayName.trim();
    if (n.isEmpty) return '??';
    final parts = n.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'publicKey': publicKey,
    'nickname': nickname,
    'address': address,
    'lastSeen': lastSeen?.toIso8601String(),
  };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    publicKey: j['publicKey'] as String,
    nickname: j['nickname'] as String? ?? '',
    address: j['address'] as String? ?? '',
    lastSeen: j['lastSeen'] != null ? DateTime.parse(j['lastSeen'] as String) : null,
  );
}

// ─── Message ──────────────────────────────────────────────────────────────────

enum MessageStatus { sending, sent, delivered, failed }

class Message {
  final String id;
  final String chatId;
  final String text;
  final bool isOutgoing;
  final DateTime timestamp;
  MessageStatus status;
  final bool isSystem;

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.isOutgoing,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isSystem = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'text': text,
    'isOutgoing': isOutgoing,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'isSystem': isSystem,
  };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'] as String,
    chatId: j['chatId'] as String,
    text: j['text'] as String,
    isOutgoing: j['isOutgoing'] as bool,
    timestamp: DateTime.parse(j['timestamp'] as String),
    status: MessageStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => MessageStatus.sent,
    ),
    isSystem: j['isSystem'] as bool? ?? false,
  );
}

// ─── Chat ─────────────────────────────────────────────────────────────────────

enum ChatType { direct, group }

class Chat {
  final String id;           // peerPublicKey (direct) or groupId (group)
  final ChatType type;
  final String name;
  final List<String> memberKeys;  // for groups
  Message? lastMessage;
  int unreadCount;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.type,
    required this.name,
    this.memberKeys = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
  });

  String get shortId {
    if (id.length > 16) return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
    return id;
  }

  String get initials {
    final n = name.trim();
    if (n.isEmpty) return type == ChatType.group ? 'G' : '??';
    if (type == ChatType.group) return n.substring(0, 1).toUpperCase();
    final parts = n.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'memberKeys': memberKeys,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Chat.fromJson(Map<String, dynamic> j) => Chat(
    id: j['id'] as String,
    type: ChatType.values.firstWhere((t) => t.name == j['type'], orElse: () => ChatType.direct),
    name: j['name'] as String,
    memberKeys: (j['memberKeys'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

// ─── Group ────────────────────────────────────────────────────────────────────

class Group {
  final String id;
  final String name;
  final List<String> memberKeys;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.memberKeys,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'memberKeys': memberKeys,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Group.fromJson(Map<String, dynamic> j) => Group(
    id: j['id'] as String,
    name: j['name'] as String,
    memberKeys: (j['memberKeys'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
