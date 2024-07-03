import 'package:firebase/model/globals.dart';
import 'package:firebase/view/chat_screen.dart';
import 'package:firebase/view/connection_list.dart';
import 'package:firebase/view/recent_chats.dart';
import 'package:firebase/view/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase/model/globals.dart' as globals;


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
static final List<Widget> _widgetOptions = <Widget>[
  const ConnectionsList(),
  const ConversationsList(),  
  UserProfile(userId: Credentials.userid, isEditable: true),
];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Connections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_sharp),
            label: 'Recent chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
