import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase/view/chat_screen.dart';

class ConversationsList extends StatefulWidget {
  const ConversationsList({Key? key}) : super(key: key);

  @override
  _ConversationsListState createState() => _ConversationsListState();
}

class _ConversationsListState extends State<ConversationsList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getUserConversations() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No conversations yet'),
            );
          }

          final conversations = snapshot.data!.docs;
          List<Widget> conversationWidgets = [];

          for (var doc in conversations) {
            var conversation = doc.data() as Map<String, dynamic>;
            var chatId = doc.id;
            var participants = conversation['participants'] as List<dynamic>;
            var currentUserUid = _auth.currentUser!.uid;
            var otherParticipantId = participants.firstWhere(
              (id) => id != currentUserUid,
              orElse: () => null,
            );

            // Skip if otherParticipantId is not found
            if (otherParticipantId == null) continue;

            var lastMessage = conversation['lastMessage'] ?? 'No messages yet';
            var timestamp = conversation['lastMessageTime'] as Timestamp?;
            String time = timestamp != null
                ? '${timestamp.toDate().hour}:${timestamp.toDate().minute}'
                : '';

            conversationWidgets.add(
              FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherParticipantId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    // Skip rendering the ListTile if user is not found
                    return const SizedBox.shrink();
                  }

                  var user = userSnapshot.data!.data() as Map<String, dynamic>;
                  var displayName = user['displayName'] ?? 'Unknown User';
                  var photoURL = user['photoURL'] ?? 'https://via.placeholder.com/150';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(photoURL),
                    ),
                    title: Text(displayName),
                    subtitle: Text(lastMessage),
                    trailing: Text(time),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipientId: otherParticipantId,
                            recipientName: displayName,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }

          return ListView(
            children: conversationWidgets,
          );
        },
      ),
    );
  }
}
