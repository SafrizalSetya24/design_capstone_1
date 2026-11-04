import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Halaman chatbot (simulasi). Akses mengikuti hak akses role yang diatur Admin.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser!;
    final settings = context.watch<SettingsStore>();
    if (!settings.can(user.role, 'chatbot')) {
      return const AppPage(
        title: 'Asisten AI',
        body: EmptyState(icon: Icons.lock_outline, title: 'Chatbot belum diaktifkan', message: 'Akses chatbot untuk role Anda belum diaktifkan oleh Admin.'),
      );
    }
    final chat = context.watch<ChatStore>();
    final s = chat.active;

    return AppPage(
      title: 'Asisten SIPINTAR',
      actions: [
        IconButton(tooltip: 'Percakapan baru', icon: const Icon(Icons.add_comment_outlined), onPressed: chat.newChat),
        if (MediaQuery.of(context).size.width < 900)
          IconButton(
            tooltip: 'Riwayat percakapan',
            icon: const Icon(Icons.history),
            onPressed: () => showModalBottomSheet(
                context: context, showDragHandle: true, builder: (_) => SizedBox(height: 420, child: _HistoryList(onPick: () => Navigator.of(context).pop()))),
          ),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final chatView = ChatView(messages: s.messages, loading: chat.loading, suggestions: chat.suggestions(user.role), onSend: chat.send);
        if (!wide) return chatView;
        return Row(children: [
          Container(
              width: 300,
              decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: AppColors.border))),
              child: const _HistoryList()),
          Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: chatView))),
        ]);
      }),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final VoidCallback? onPick;
  const _HistoryList({this.onPick});
  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatStore>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Riwayat percakapan', style: TextStyle(fontWeight: FontWeight.w800))),
      Expanded(
        child: ListView(children: [
          for (final s in chat.sessions)
            ListTile(
              selected: s.id == chat.active.id,
              selectedTileColor: AppColors.blue.withOpacity(0.08),
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(Fmt.ago(s.updated), style: const TextStyle(fontSize: 12)),
              trailing: IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => chat.deleteSession(s)),
              onTap: () {
                chat.open(s);
                onPick?.call();
              },
            ),
        ]),
      ),
    ]);
  }
}
