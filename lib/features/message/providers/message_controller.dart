import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message_model.dart';
import '../data/services/message_service.dart';

final messageServiceProvider = Provider<MessageService>(
  (ref) => MessageService(),
);

final conversationsControllerProvider =
    AsyncNotifierProvider<ConversationsController, List<ConversationModel>>(
      ConversationsController.new,
    );

class ConversationsController extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    return await ref.read(messageServiceProvider).getConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(messageServiceProvider).getConversations(),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final chatControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatController, List<dynamic>>(
      ChatController.new,
    );

class ChatController extends AsyncNotifier<List<dynamic>> {
  String? _conversationId;
  String? _receiverId;

  String? get conversationId => _conversationId;

  @override
  Future<List<dynamic>> build() async {
    return [];
  }

  Future<void> loadMessages(
    String conversationId,
    String receiverId, {
    bool silent = false,
  }) async {
    _conversationId = conversationId;
    _receiverId = receiverId;

    if (!silent) {
      state = const AsyncLoading();
    }

    try {
      final messages = await ref
          .read(messageServiceProvider)
          .getMessages(conversationId);
      state = AsyncData(messages);
    } catch (e, st) {
      if (!silent || state.hasError || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<String> startChatWithUser(String receiverId) async {
    state = const AsyncLoading();
    _receiverId = receiverId;
    try {
      final conversationId = await ref
          .read(messageServiceProvider)
          .startOrGetConversation(receiverId);
      _conversationId = conversationId;
      await loadMessages(conversationId, receiverId);
      ref.read(conversationsControllerProvider.notifier).refresh();
      return conversationId;
    } catch (e, st) {
      _conversationId = null;
      state = AsyncError(e, st);
      return '';
    }
  }

  Future<void> sendMessage(String content) async {
    if (_receiverId == null) return;

    try {
      await ref
          .read(messageServiceProvider)
          .sendMessage(receiverId: _receiverId!, content: content);

      _conversationId ??= await ref
          .read(messageServiceProvider)
          .startOrGetConversation(_receiverId!);

      if (_conversationId != null) {
        await loadMessages(_conversationId!, _receiverId!, silent: true);
      }

      ref.read(conversationsControllerProvider.notifier).refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead() async {
    if (_conversationId != null) {
      try {
        await ref.read(messageServiceProvider).markAsRead(_conversationId!);
        ref.read(conversationsControllerProvider.notifier).refresh();
      } catch (_) {}
    }
  }
}
