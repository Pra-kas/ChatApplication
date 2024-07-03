import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/view/chat_screen.dart';
import 'package:firebase/view/user_profile.dart';
import 'package:flutter/material.dart';

class ConnectionsList extends StatefulWidget {
  const ConnectionsList({super.key});

  @override
  State<ConnectionsList> createState() => _ConnectionsListState();
}

class _ConnectionsListState extends State<ConnectionsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showBottomSheet(BuildContext context, String userId, String displayName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfile(userId: userId, isEditable: false),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Start Chat'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        recipientId: userId,
                        recipientName: displayName,
                        id: null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    user['photoURL'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                title: Text(user['displayName'] ?? 'User $index'),
                onTap: () {
                  _showBottomSheet(context, users[index].id, user['displayName'] ?? 'User');
                },
              );
            },
          );
        },
      ),
    );
  }
}
