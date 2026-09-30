class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  ChatMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}
