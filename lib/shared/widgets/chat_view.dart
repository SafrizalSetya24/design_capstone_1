import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';
import 'package:sipintar/core/utils/format.dart';
import 'package:sipintar/data/models/misc_models.dart';

class ChatView extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool loading;
  final List<String> suggestions;
  final ValueChanged<String> onSend;
  const ChatView(
      {super.key,
      required this.messages,
      required this.loading,
      required this.suggestions,
      required this.onSend});
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant ChatView old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? s]) {
    final t = (s ?? _text.text).trim();
    if (t.isEmpty || widget.loading) return;
    widget.onSend(t);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.messages.isEmpty;
    return Column(children: [
      Expanded(
        child: empty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.blue.withValues(alpha: 0.12),
                        child: const Icon(Icons.smart_toy_outlined,
                            size: 34, color: AppColors.blue)),
                    const SizedBox(height: 14),
                    const Text('Asisten SIPINTAR',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text(
                        'Tanyakan seputar inventaris, stok, dan peminjaman. Jawaban disusun dari data dummy (simulasi).',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary)),
                  ]),
                ),
              )
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: widget.messages.length,
                itemBuilder: (_, i) => _Bubble(m: widget.messages[i]),
              ),
      ),
      if (widget.loading)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Asisten sedang menyusun jawaban...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final s in widget.suggestions)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _send(s)),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _text,
              onSubmitted: _send,
              textInputAction: TextInputAction.send,
              decoration:
                  const InputDecoration(hintText: 'Tulis pertanyaan Anda...'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size(52, 52)),
            tooltip: 'Kirim',
            onPressed: widget.loading ? null : _send,
            icon: const Icon(Icons.send_rounded),
          ),
        ]),
      ),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble({required this.m});
  @override
  Widget build(BuildContext context) {
    final me = m.fromUser;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: me ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(me ? 16 : 4),
            bottomRight: Radius.circular(me ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.text,
              style: TextStyle(
                  color: me ? Colors.white : AppColors.textPrimary,
                  height: 1.4)),
          const SizedBox(height: 4),
          Text(Fmt.time(m.time),
              style: TextStyle(
                  fontSize: 10,
                  color: me ? Colors.white70 : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
