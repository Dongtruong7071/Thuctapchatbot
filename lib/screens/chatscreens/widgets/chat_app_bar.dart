import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatAppBarState extends ChangeNotifier {
  String _systemPrompt =
      'Bạn là một trợ lý thông minh, trả lời với giọng điệu thân thiện và ngắn gọn.';
  String _tone = 'Trung tính';
  String _responseLength = 'Trung bình';

  String get systemPrompt => _systemPrompt;
  String get tone => _tone;
  String get responseLength => _responseLength;

  void updateSettings({
    required String systemPrompt,
    required String tone,
    required String responseLength,
  }) {
    _systemPrompt = systemPrompt;
    _tone = tone;
    _responseLength = responseLength;
    notifyListeners();
  }

  void resetSettings() {
    _systemPrompt =
    'Bạn là một trợ lý thông minh, trả lời với giọng điệu thân thiện và ngắn gọn.';
    _tone = 'Trung tính';
    _responseLength = 'Trung bình';
    notifyListeners();
  }

  Map<String, String> getSettings() {
    return {
      'systemPrompt': _systemPrompt,
      'tone': _tone,
      'responseLength': _responseLength,
    };
  }
}

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onNewChat;
  final VoidCallback onSettings;
  final VoidCallback onRenameChat;
  final VoidCallback onDeleteChat;
  final VoidCallback onSignOut;
  final VoidCallback onToggleSearch;
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  const ChatAppBar({
    super.key,
    required this.scaffoldKey,
    required this.onNewChat,
    required this.onSettings,
    required this.onRenameChat,
    required this.onDeleteChat,
    required this.onSignOut,
    required this.onToggleSearch,
    required this.isSearching,
    required this.searchController,
    required this.onSearchChanged,
  });

  void _showSettingsDialog(BuildContext context) {
    final chatAppBarState = Provider.of<ChatAppBarState>(context, listen: false);
    final TextEditingController systemPromptController = TextEditingController(
      text: chatAppBarState.systemPrompt,
    );
    String selectedTone = chatAppBarState.tone;
    String selectedLength = chatAppBarState.responseLength;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cài đặt'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Prompt:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: systemPromptController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Nhập System Prompt...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                        ),
                        scrollPhysics: const BouncingScrollPhysics(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Giọng điệu:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedTone,
                      isExpanded: true,
                      items: <String>['Nghiêm túc', 'Trung tính', 'Cảm xúc', 'Cường điệu']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTone = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Độ dài câu trả lời:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedLength,
                      isExpanded: true,
                      items: <String>['Ngắn', 'Trung bình', 'Dài']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLength = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    chatAppBarState.updateSettings(
                      systemPrompt: systemPromptController.text,
                      tone: selectedTone,
                      responseLength: selectedLength,
                    );
                    onSettings();
                    Navigator.pop(context);
                    print(
                        'Cài đặt đã lưu: systemPrompt=${chatAppBarState.systemPrompt}, tone=${chatAppBarState.tone}, responseLength=${chatAppBarState.responseLength}');
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatAppBarState = Provider.of<ChatAppBarState>(context, listen: false);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: isSearching
          ? TextField(
        controller: searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm tin nhắn...',
          border: InputBorder.none,
        ),
        onChanged: (value) => onSearchChanged(),
      )
          : const Text(
        'Ứng dụng Chatbot',
        style: TextStyle(color: Colors.black, fontSize: 18),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.black),
          onPressed: onToggleSearch,
        ),
        if (!isSearching) ...[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              onNewChat();
              chatAppBarState.resetSettings();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Đăng xuất') {
                onSignOut();
              } else if (value == 'Cài đặt') {
                _showSettingsDialog(context);
              } else if (value == 'Đổi tên đoạn chat') {
                onRenameChat();
              } else if (value == 'Xóa bỏ đoạn chat') {
                onDeleteChat();
                chatAppBarState.resetSettings();
              }
            },
            itemBuilder: (BuildContext context) {
              return {
                'Cài đặt',
                'Đổi tên đoạn chat',
                'Xóa bỏ đoạn chat',
                'Đăng xuất',
              }.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}