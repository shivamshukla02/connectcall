import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../calling/incoming_call_listener.dart';
import '../contacts/contacts_screen.dart';
import '../profile/profile_screen.dart';
import '../history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Contacts', 'Contacts', 'Calls', 'Profile'];

  Widget _body() {
    switch (_index) {
      case 0:
      case 1:
        return const ContactsScreen();
      case 2:
        return const HistoryScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const ContactsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IncomingCallListener(
      child: Scaffold(
        appBar: AppBar(title: Text(_index == 0 ? AppConstants.appName : _titles[_index])),
        body: _body(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.people_outline), label: 'Contacts'),
            NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Calls'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}



