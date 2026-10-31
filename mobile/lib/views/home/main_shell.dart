import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../requests/my_requests_screen.dart';
import 'app_drawer.dart';
import 'home_screen.dart';

/// Holds the slide-out menu, the bottom navigation and the three tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0; // 0 = Home, 1 = My Requests, 2 = Profile

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeScreen(onSeeAll: () => _switchTab(1)), // See All → My Requests
      const MyRequestsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      drawer: const AppDrawer(), // the slide-out menu
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            activeIcon: Icon(Icons.assignment_turned_in),
            label: 'My Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
