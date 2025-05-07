import 'package:flutter/material.dart';
import 'package:ungdungchatbot/models/conversation.dart';

class ChatDrawer extends StatelessWidget {
  final String username;
  final List<Conversation> filteredChatGroups;
  final String selectedChat;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final Function(Conversation) onChatSelected;
  final VoidCallback onRenameAccount;
  final VoidCallback onSignOut;

  const ChatDrawer({
    super.key,
    required this.username,
    required this.filteredChatGroups,
    required this.selectedChat,
    required this.searchController,
    required this.onSearch,
    required this.onChatSelected,
    required this.onRenameAccount,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final displayName = username.isEmpty ? 'bạn' : username;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.03,
                horizontal: screenWidth * 0.05,
              ),
              color: Colors.blueAccent,
              child: Text(
                'Xin chào, $displayName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đoạn chat',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => onSearch(),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...filteredChatGroups.map((chat) {
                    return ListTile(
                      leading: const Icon(
                        Icons.chat,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        chat.title ?? 'Đoạn chat mới',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: selectedChat == (chat.title ?? 'Đoạn chat mới')
                              ? Colors.blueAccent
                              : Colors.black,
                          fontWeight: selectedChat == (chat.title ?? 'Đoạn chat mới')
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: selectedChat == (chat.title ?? 'Đoạn chat mới'),
                      onTap: () {
                        onChatSelected(chat);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                  if (filteredChatGroups.isEmpty)
                    ListTile(
                      title: Text(
                        'Không tìm thấy đoạn chat',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: Colors.blueAccent,
              ),
              title: Text(
                'Đổi tên tài khoản',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              onTap: () {
                Navigator.pop(context);
                onRenameAccount();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.redAccent,
              ),
              title: Text(
                'Đăng xuất',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.redAccent,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onSignOut();
              },
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}