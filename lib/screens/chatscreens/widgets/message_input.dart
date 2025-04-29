import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final Future<List<String>>? modelNamesFuture;
  final String? selectedChatbot;
  final TextEditingController messageController;
  final Function(String) onChatbotSelected;
  final VoidCallback onSendMessage;

  const MessageInput({
    super.key,
    required this.modelNamesFuture,
    required this.selectedChatbot,
    required this.messageController,
    required this.onChatbotSelected,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.025),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder<List<String>>(
            future: modelNamesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return const Icon(Icons.error, color: Colors.red);
              }
              final modelNames = snapshot.data ?? [];
              if (modelNames.isEmpty) {
                return const Text('No models available');
              }

              return PopupMenuButton<String>(
                offset: const Offset(0, -150),
                icon: selectedChatbot != null
                    ? Image.asset(
                  'assets/icons/${selectedChatbot!.toLowerCase()}_icon.png',
                  width: screenWidth * 0.06,
                  height: screenWidth * 0.06,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
                )
                    : const Icon(Icons.error),
                onSelected: onChatbotSelected,
                itemBuilder: (BuildContext context) {
                  return modelNames.map((String chatbot) {
                    return PopupMenuItem<String>(
                      value: chatbot,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/icons/${chatbot.toLowerCase()}_icon.png',
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(chatbot),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: selectedChatbot != null
                    ? 'Nhắn tin cho $selectedChatbot'
                    : 'Chọn một chatbot',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)),
                contentPadding:
                EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              ),
              onSubmitted: (value) => onSendMessage(),
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSendMessage,
          ),
        ],
      ),
    );
  }
}