import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../domain/message_thread.dart';

/// Direct Messages View featuring calm, asynchronous communication (Issue #27).
/// Supports calm digest batching, non-urgent messaging, and unread counts
/// without red badges or stressful notification triggers.
class BelongMessagesView extends HookWidget {
  const BelongMessagesView({
    super.key,
    this.initialThreads,
  });

  final List<MessageThread>? initialThreads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final threads = useState<List<MessageThread>>(
      initialThreads ?? MessageThread.sampleThreads(),
    );
    final calmDigestEnabled = useState(true);
    final activeThread = useState<MessageThread?>(null);
    final replyController = useTextEditingController();

    void sendReply() {
      final text = replyController.text.trim();
      if (text.isEmpty || activeThread.value == null) return;

      final newMsg = DirectMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'You',
        isFromMe: true,
        content: text,
        sentAt: DateTime.now(),
      );

      final current = activeThread.value!;
      final updatedMessages = [...current.messages, newMsg];
      final updatedThread = current.copyWith(
        messages: updatedMessages,
        previewSnippet: text,
        lastActivity: DateTime.now(),
        unreadCount: 0,
      );

      threads.value = threads.value
          .map((t) => t.id == updatedThread.id ? updatedThread : t)
          .toList();
      activeThread.value = updatedThread;
      replyController.clear();
    }

    if (activeThread.value != null) {
      return _buildThreadDetail(
        context,
        theme,
        activeThread.value!,
        replyController,
        sendReply,
        () => activeThread.value = null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Calm Digest Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCECE4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.spa_outlined, color: Color(0xFF2E6B56), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Calm Batched Digest is ${calmDigestEnabled.value ? "Active (quiet daily summary)" : "Disabled (realtime alerts)"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1E4638),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: calmDigestEnabled.value,
                activeTrackColor: const Color(0xFF2E6B56),
                onChanged: (val) => calmDigestEnabled.value = val,
              ),
            ],
          ),
        ),

        // Conversation List Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Direct Messages',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${threads.value.length} conversations',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Thread List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: threads.value.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
            itemBuilder: (context, index) {
              final thread = threads.value[index];
              return ListTile(
                key: Key('thread-${thread.id}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8ECEF),
                  foregroundColor: const Color(0xFF2C3E50),
                  child: Text(
                    thread.avatarInitials,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.participantName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (thread.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E6B56),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    thread.previewSnippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: thread.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                      fontWeight: thread.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () {
                  final updated = thread.copyWith(unreadCount: 0);
                  activeThread.value = updated;
                  threads.value = threads.value
                      .map((t) => t.id == thread.id ? updated : t)
                      .toList();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThreadDetail(
    BuildContext context,
    ThemeData theme,
    MessageThread thread,
    TextEditingController replyController,
    VoidCallback onSendReply,
    VoidCallback onBack,
  ) {
    return Column(
      children: [
        // Thread App Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('back-to-messages-list'),
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE8ECEF),
                child: Text(thread.avatarInitials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  thread.participantName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Message History
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: thread.messages.length,
            itemBuilder: (context, index) {
              final msg = thread.messages[index];
              return Align(
                alignment: msg.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: msg.isFromMe ? const Color(0xFF2E6B56) : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: msg.isFromMe ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Reply Input Bar
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('reply-message-field'),
                    controller: replyController,
                    decoration: InputDecoration(
                      hintText: 'Type a calm reply...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF7F9FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    onSubmitted: (_) => onSendReply(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('send-reply-button'),
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF2E6B56)),
                  onPressed: onSendReply,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
