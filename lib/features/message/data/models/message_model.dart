class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ConversationModel {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfileImage;
  final String lastMessage;
  final int unreadCount;
  final DateTime lastMessageAt;

  ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfileImage,
    required this.lastMessage,
    required this.unreadCount,
    required this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final otherUser = json['otherUser'] as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id: json['id'] ?? json['conversationId'] ?? '',
      otherUserId: otherUser['id'] ?? '',
      otherUserName: otherUser['name'] ?? 'Unknown User',
      otherUserProfileImage: otherUser['profileImage'],
      lastMessage: json['lastMessage'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : DateTime.now(),
    );
  }
}
