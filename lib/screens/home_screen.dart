import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'sections_screen.dart';
import 'rulings_screen.dart';
import 'mtr_ipg_screen.dart';
import 'credits_screen.dart';
import 'search_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _bookmarksKey = GlobalKey<BookmarksScreenState>();

  List<Widget> get _screens => [
    const SectionsScreen(),
    const RulingsScreen(),
    const MtrIpgScreen(),
    BookmarksScreen(key: _bookmarksKey),
    const CreditsScreen(),
  ];

  static const List<String> _titles = [
    'Rules',
    'Rulings',
    'MTR/IPG',
    'Bookmarks',
    'Credits',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getAppBarActions() {
    // Rules (0) has search
    if (_selectedIndex == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            );
          },
          tooltip: 'Search',
        ),
      ];
    }
    // Bookmarks (3) has edit button
    if (_selectedIndex == 3) {
      return [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            _bookmarksKey.currentState?.toggleEditMode();
          },
          tooltip: 'Edit bookmarks',
        ),
      ];
    }
    // Other tabs have no actions
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _getAppBarActions(),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Rules',
          ),
          NavigationDestination(
            icon: Transform.rotate(
              angle: pi,
              child: const Icon(Icons.style_outlined),
            ),
            selectedIcon: Transform.rotate(
              angle: pi,
              child: const Icon(Icons.style),
            ),
            label: 'Rulings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'MTR/IPG',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          const NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Credits',
          ),
        ],
      ),
    );
  }
}
