import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../profile/presentation/belong_members_directory_view.dart';
import '../domain/message_thread.dart';

/// Direct Messages View featuring calm, asynchronous communication (Issue #288).
/// Supports message searching, thread list with avatars, dates, subjects,
/// and cute "Add Msg" compose modal with multi-recipient autocomplete member selection.
class BelongMessagesView extends HookWidget {
  const BelongMessagesView({
    super.key,
    this.initialThreads,
    this.onBackToHome,
  });

  final List<MessageThread>? initialThreads;
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final threads = useState<List<MessageThread>>(
      initialThreads ?? MessageThread.sampleThreads(),
    );
    final calmDigestEnabled = useState(true);
    final activeThread = useState<MessageThread?>(null);
    final searchQuery = useState('');
    final searchController = useTextEditingController();
    final replyController = useTextEditingController();

    // Filter threads by search query across sender name, subject, and preview
    final filteredThreads = threads.value.where((t) {
      final q = searchQuery.value.trim().toLowerCase();
      if (q.isEmpty) return true;
      final nameMatch = t.participantName.toLowerCase().contains(q);
      final subjectMatch = (t.subject ?? '').toLowerCase().contains(q);
      final snippetMatch = t.previewSnippet.toLowerCase().contains(q);
      return nameMatch || subjectMatch || snippetMatch;
    }).toList();

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

    void openNewMessageModal() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _NewMessageModalSheet(
          onSendMessage: (recipients, subject, content) {
            final now = DateTime.now();
            final participantName = recipients.length == 1
                ? recipients.first.name
                : '${recipients.first.name} & ${recipients.length - 1} others';
            final initials = recipients.first.initials;

            final newThread = MessageThread(
              id: 'thread-${now.millisecondsSinceEpoch}',
              participantName: participantName,
              avatarInitials: initials,
              subject: subject.trim().isEmpty ? null : subject.trim(),
              messageType: recipients.length > 1 ? 'Group' : 'Direct',
              recipientNames: recipients.map((r) => r.name).toList(),
              previewSnippet: content,
              lastActivity: now,
              unreadCount: 0,
              messages: [
                DirectMessage(
                  id: 'msg-${now.millisecondsSinceEpoch}',
                  senderName: 'You',
                  isFromMe: true,
                  content: content,
                  sentAt: now,
                ),
              ],
            );

            threads.value = [newThread, ...threads.value];
            activeThread.value = newThread;
          },
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Messages'),
        leading: onBackToHome != null
            ? IconButton(
                key: const Key('messages-back-button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackToHome,
              )
            : null,
        actions: [
          // Cute & clear Add Msg icon button
          IconButton(
            key: const Key('add_new_message_button'),
            tooltip: 'New Message',
            icon: const Icon(
              Icons.maps_ugc_rounded,
              size: 23,
            ),
            onPressed: openNewMessageModal,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Messages Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: TextField(
              key: const Key('search_messages_input'),
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search messages, subjects, or members...',
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        key: const Key('clear_search_messages_button'),
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                ),
              ),
              onChanged: (val) => searchQuery.value = val,
            ),
          ),

          // Calm Digest Banner
          Container(
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCECE4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.spa_outlined, color: Color(0xFF2E6B56), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calm Batched Digest is ${calmDigestEnabled.value ? "Active (quiet daily summary)" : "Disabled (realtime alerts)"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1E4638),
                      fontSize: 11,
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conversations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${filteredThreads.length} conversation${filteredThreads.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Thread List
          Expanded(
            child: filteredThreads.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        searchQuery.value.isNotEmpty
                            ? 'No messages matching "${searchQuery.value}".'
                            : 'No conversations yet.\nTap the message icon above to start one.',
                        key: const Key('empty_messages_placeholder'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: filteredThreads.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                    itemBuilder: (context, index) {
                      final thread = filteredThreads[index];
                      return ListTile(
                        key: Key('thread-${thread.id}'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: CircleAvatar(
                          backgroundColor: primary.withValues(alpha: 0.12),
                          foregroundColor: primary,
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
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (thread.messageType != null) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  thread.messageType!,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                            Text(
                              thread.formattedDate(),
                              key: Key('thread_date_${thread.id}'),
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                            ),
                            if (thread.unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${thread.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            thread.subject != null
                                ? '${thread.subject}: ${thread.previewSnippet}'
                                : thread.previewSnippet,
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
      ),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('back-to-messages-list'),
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                thread.avatarInitials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    thread.participantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (thread.subject != null)
                    Text(
                      thread.subject!,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message History
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                final msg = thread.messages[index];
                return Align(
                  alignment:
                      msg.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isFromMe
                          ? theme.colorScheme.primary
                          : const Color(0xFFF1F3F4),
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
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
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
                    icon: Icon(
                      Icons.send_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: onSendReply,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compose modal sheet supporting single or multi-recipient autocomplete selection
/// with Member Name as title and Member Profile Tagline as subtitle.
class _NewMessageModalSheet extends HookWidget {
  const _NewMessageModalSheet({
    required this.onSendMessage,
  });

  final void Function(
    List<DevFellowshipMember> recipients,
    String subject,
    String content,
  ) onSendMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final selectedRecipients = useState<List<DevFellowshipMember>>([]);
    final recipientQuery = useState('');
    final recipientSearchController = useTextEditingController();
    final subjectController = useTextEditingController();
    final contentController = useTextEditingController();

    // Filter available members excluding already selected ones
    final availableMembers = kDevFellowshipMembers.where((m) {
      final notAlreadySelected = !selectedRecipients.value.any((s) => s.name == m.name);
      final q = recipientQuery.value.trim().toLowerCase();
      if (q.isEmpty) return notAlreadySelected;
      final nameMatches = m.name.toLowerCase().contains(q);
      final taglineMatches = m.effectiveTagline.toLowerCase().contains(q);
      return notAlreadySelected && (nameMatches || taglineMatches);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.maps_ugc_rounded, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'New Message',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Selected Recipients Chips
            if (selectedRecipients.value.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: selectedRecipients.value.map((m) {
                  return InputChip(
                    key: Key('selected_recipient_chip_${m.name}'),
                    avatar: CircleAvatar(
                      child: Text(m.initials, style: const TextStyle(fontSize: 10)),
                    ),
                    label: Text(m.name, style: const TextStyle(fontSize: 11.5)),
                    onDeleted: () {
                      selectedRecipients.value = selectedRecipients.value
                          .where((s) => s.name != m.name)
                          .toList();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Recipient Autocomplete Input
            TextField(
              key: const Key('recipient_search_input'),
              controller: recipientSearchController,
              decoration: InputDecoration(
                hintText: selectedRecipients.value.isEmpty
                    ? 'Search members (single or multiple)...'
                    : 'Add another recipient...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.person_search_rounded, size: 18),
                isDense: true,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => recipientQuery.value = val,
            ),
            const SizedBox(height: 6),

            // Autocomplete Member Dropdown List
            if (availableMembers.isNotEmpty)
              Material(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableMembers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final member = availableMembers[idx];
                      return ListTile(
                        key: Key('member_picker_item_${member.name}'),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(member.initials, style: const TextStyle(fontSize: 10)),
                        ),
                        // Title: Member Name
                        title: Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        // Subtitle: Member's Profile Tagline!
                        subtitle: Text(
                          member.effectiveTagline,
                          key: Key('member_tagline_${member.name}'),
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        onTap: () {
                          selectedRecipients.value = [...selectedRecipients.value, member];
                          recipientSearchController.clear();
                          recipientQuery.value = '';
                        },
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // Subject Field
            TextField(
              key: const Key('new_message_subject_input'),
              controller: subjectController,
              decoration: InputDecoration(
                hintText: 'Subject (optional)',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                isDense: true,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Content Field
            TextField(
              key: const Key('new_message_content_input'),
              controller: contentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your calm, unhurried message...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Send Button
            ElevatedButton.icon(
              key: const Key('send_new_message_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (selectedRecipients.value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one recipient.')),
                  );
                  return;
                }
                if (contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a message content.')),
                  );
                  return;
                }

                onSendMessage(
                  selectedRecipients.value,
                  subjectController.text,
                  contentController.text.trim(),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
