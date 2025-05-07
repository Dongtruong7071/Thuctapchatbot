import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ungdungchatbot/screens/chatscreens/widgets/chat_app_bar.dart';
import 'package:ungdungchatbot/screens/chatscreens/widgets/chat_drawer.dart';
import 'package:ungdungchatbot/screens/chatscreens/widgets/chat_list.dart';
import 'package:ungdungchatbot/screens/chatscreens/widgets/message_input.dart';

import 'package:ungdungchatbot/services/authen_service.dart';
import 'package:ungdungchatbot/services/n8n_service.dart';
import 'package:ungdungchatbot/services/supabase_service.dart';

import 'controller/chat_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatController(
            AuthenService(),
            SupabaseService(),
            ApiService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatAppBarState(),
        ),
      ],
      child: const _ChatScreenContent(),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  const _ChatScreenContent();

  @override
  _ChatScreenContentState createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSearching = false;
  bool _showScrollDownButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showScrollDownButton = _scrollController.hasClients &&
            _scrollController.offset > 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _messageSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatController, ChatAppBarState>(
      builder: (context, controller, chatAppBarState, child) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: ChatAppBar(
            scaffoldKey: _scaffoldKey,
            onNewChat: () {
              controller.startNewChat();
            },
            onSettings: () {
              print("Cài đặt clicked");
            },
            onRenameChat: () => controller.renameChat(context),
            onDeleteChat: () => controller.deleteChat(context),
            onSignOut: () async {
              setState(() => _isLoading = true);
              await controller.signOut(context);
              setState(() => _isLoading = false);
            },
            onToggleSearch: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _messageSearchController.clear();
                  controller.searchMessages('');
                }
              });
            },
            isSearching: _isSearching,
            searchController: _messageSearchController,
            onSearchChanged: () {
              controller.searchMessages(_messageSearchController.text);
            },
          ),
          drawer: ChatDrawer(
            username: controller.username,
            filteredChatGroups: controller.filteredChatGroups,
            selectedChat: controller.selectedChat,
            searchController: _searchController,
            onSearch: () => controller.searchChats(_searchController.text),
            onChatSelected: (chat) {
              controller.selectChat(chat);
            },
            onRenameAccount: () => controller.renameAccount(context),
            onSignOut: () async {
              setState(() => _isLoading = true);
              await controller.signOut(context);
              setState(() => _isLoading = false);
            },
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Expanded(
                  child: ChatList(
                    messages: controller.filteredMessages,
                    username: controller.username,
                    scrollController: _scrollController,
                    onReloadMessage: (index) {
                      controller.reloadMessage(index, _scrollToBottom, context);
                    },
                    searchKeyword: controller.searchKeyword,
                  ),
                ),
                MessageInput(
                  modelNamesFuture: controller.modelNamesFuture,
                  selectedChatbot: controller.selectedChatbot,
                  messageController: _messageController,
                  onChatbotSelected: (newValue) {
                    controller.selectedChatbot = newValue;
                  },
                  onSendMessage: () async {
                    try {
                      final settings = chatAppBarState.getSettings();
                      print('Cài đặt khi gửi tin nhắn: $settings');
                      await controller.sendMessage(
                        messageController: _messageController,
                        scrollToBottom: _scrollToBottom,
                        systemPrompt: settings['systemPrompt']!,
                        tone: settings['tone']!,
                        responseLength: settings['responseLength']!,
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString())),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: _showScrollDownButton
              ? FloatingActionButton(
            mini: true,
            onPressed: _scrollToBottom,
            child: const Icon(Icons.arrow_downward),
          )
              : null,
        );
      },
    );
  }
}