import 'package:flutter/material.dart';

import 'attraction_list_screen.dart';
import 'bookmark_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'trip_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  static const List<String> _titles = [
    'JelajahMY',
    'Attractions',
    'Trips',
    'Bookmarks',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(
        onExplorePressed: () {
          _selectTab(1);
        },
      ),
      const AttractionListScreen(),
      const TripListScreen(),
      const BookmarkScreen(),
      const ProfileScreen(),
    ];
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 1 || _selectedIndex == 2 || _selectedIndex == 3
          ? null
          : AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Attractions',
          ),
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
