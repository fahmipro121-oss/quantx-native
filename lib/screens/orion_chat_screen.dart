import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../theme.dart';

class OrionChatScreen extends StatefulWidget {
  final Account account;
  final ApiService api;
  const OrionChatScreen({super.key, required this.account, required this.api});

  @override
  State<OrionChatScreen> createState() => _OrionChatScreenState();
}

class _OrionChatScreenState extends State<OrionChatScreen> {
  final List<ChatMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _thinking = false;
  DateTime? _lockedUntil;

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _thinking || _isLocked) return;
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _inputCtrl.clear();
      _thinking = true;
    });
    _scrollToBottom();

    // Konteks 8 balasan terakhir, sama kayak versi web (js/app.js: .slice(-8)),
    // TANPA pesan yang baru aja ditambahin di atas (itu dikirim lewat
    // `message`, bukan ikut di `history`).
    final history = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1).length > 8
            ? _messages.sublist(_messages.length - 1 - 8, _messages.length - 1)
            : _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];

    final result = await widget.api.sendOrionChat(message: text, history: history);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      if (result.ok) {
        _messages.add(ChatMessage(role: 'assistant', text: result.reply ?? ''));
      } else if (result.error == 'RATE_LIMITED') {
        _lockedUntil = result.unlockAt != null
            ? DateTime.fromMillisecondsSinceEpoch(result.unlockAt!)
            : DateTime.now().add(const Duration(seconds: 90));
      } else {
        _messages.add(ChatMessage(
          role: 'assistant',
          text: result.error == 'NOT_CONFIGURED'
              ? '⚠️ Orion belum aktif — hubungi admin.'
              : '⚠️ Orion lagi ada gangguan koneksi ke server. Coba lagi sebentar lagi.',
        ));
      }
    });
    _scrollToBottom();
  }

  bool get _isLocked => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = QuantXColors.forRole(widget.account.role);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: QuantXColors.bg,
        title: const Text('ORION AI', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Apa yang mau kamu tanyain soal market?',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(14),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _bubble(_messages[i], roleColor),
                  ),
          ),
          if (_thinking)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: QuantXColors.accent),
                  ),
                  SizedBox(width: 10),
                  Text('Orion lagi mikir...', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                ],
              ),
            ),
          if (_isLocked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Limit chat harian kamu abis. Coba lagi nanti.',
                style: const TextStyle(color: Color(0xFFFFB84D), fontSize: 12.5),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      enabled: !_isLocked,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Tanya Orion...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: QuantXColors.accent),
                    onPressed: _isLocked ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m, Color roleColor) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? roleColor.withOpacity(0.85) : QuantXColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: isUser ? null : Border.all(color: QuantXColors.line),
        ),
        child: Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
      ),
    );
  }
}
