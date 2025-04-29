import 'package:flutter/material.dart';

class ChatList extends StatelessWidget {
  final List<Map<String, String>> messages;
  final String username;
  final ScrollController scrollController;
  final Function(int) onReloadMessage;
  final String searchKeyword;

  const ChatList({
    super.key,
    required this.messages,
    required this.username,
    required this.scrollController,
    required this.onReloadMessage,
    required this.searchKeyword,
  });

  List<TextSpan> highlightText(String text, String keyword) {
    if (keyword.isEmpty) {
      return [TextSpan(text: text)];
    }
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(RegExp.escape(keyword), caseSensitive: false);
    int start = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  int? findLatestBotMessageIndex() {
    for (int i = 0; i < messages.length; i++) {
      if (messages[i]['sender'] == 'bot') {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final latestBotMessageIndex = findLatestBotMessageIndex();

    return messages.isEmpty
        ? Center(
      child: Text(
        "Xin chào ${username.isEmpty ? 'bạn' : username}, tôi có thể giúp gì cho bạn?",
        style: TextStyle(
          fontSize: screenWidth * 0.045,
          color: Colors.grey,
        ),
      ),
    )
        : ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(screenWidth * 0.025),
      itemCount: messages.length,
      reverse: true,
      itemBuilder: (context, index) {
        final message = messages[index];
        bool isUser = message['sender'] == 'user';
        bool isLoadingMessage = message['isLoading'] == 'true';

        bool showReloadButton =
            !isUser && !isLoadingMessage && index == latestBotMessageIndex;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blueAccent : Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoadingMessage)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (isLoadingMessage) const SizedBox(width: 8),
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                              fontSize: screenWidth * 0.04,
                            ),
                            children: highlightText(message['text']!, searchKeyword),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isUser && !isLoadingMessage)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      message['model']!,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (showReloadButton)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: Colors.grey),
                      onPressed: () => onReloadMessage(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}