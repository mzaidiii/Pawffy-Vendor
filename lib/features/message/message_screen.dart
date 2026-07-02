import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawffy/main.dart';
import '../home/home_screen.dart';
import 'chat_screen.dart';
import 'providers/message_controller.dart';
import 'data/models/message_model.dart';

class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({super.key});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (dateToCheck == today) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'MESSAGES',
                style: GoogleFonts.barlow(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.barlow(
                    color: isDark ? AppColors.white : AppColors.black,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: GoogleFonts.barlow(
                      color: const Color(0xFF888888),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF888888),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.orange,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEEEEEE),
              thickness: 1,
              height: 1,
            ),

            Expanded(
              child: conversationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading conversations',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.barlow(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(conversationsControllerProvider.notifier)
                              .refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (conversations) {
                  final filtered = conversations
                      .where(
                        (c) => c.otherUserName.toLowerCase().contains(
                          _searchQuery,
                        ),
                      )
                      .toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: AppColors.orange,
                    onRefresh: () => ref
                        .read(conversationsControllerProvider.notifier)
                        .refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF1F1F1),
                        indent: 76,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        final conversation = filtered[index];
                        return _buildConversationItem(conversation, isDark);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(ConversationModel conversation, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.orange.withOpacity(0.1),
        backgroundImage:
            conversation.otherUserProfileImage != null &&
                conversation.otherUserProfileImage!.isNotEmpty
            ? NetworkImage(conversation.otherUserProfileImage!)
            : null,
        child:
            conversation.otherUserProfileImage == null ||
                conversation.otherUserProfileImage!.isEmpty
            ? Text(
                conversation.otherUserName.isNotEmpty
                    ? conversation.otherUserName[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              )
            : null,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              conversation.otherUserName,
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageAt),
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage.isNotEmpty
                    ? conversation.lastMessage
                    : 'No messages yet',
                style: GoogleFonts.barlow(
                  fontSize: 13,
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: conversation.unreadCount > 0
                      ? (isDark ? AppColors.white : AppColors.black)
                      : AppColors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: GoogleFonts.barlow(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversation.id,
              receiverId: conversation.otherUserId,
              receiverName: conversation.otherUserName,
              receiverProfileImage: conversation.otherUserProfileImage,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No chats found',
              style: GoogleFonts.barlow(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching for something else'
                  : 'Book a service and start a\nconversation with a provider',
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            if (_searchQuery.isEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore Services',
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_outward, size: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
