import 'package:flutter/material.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../biofeedback/presentation/pages/biofeedback_page.dart';
import '../../../mood_detection/presentation/pages/mood_selection_page.dart';
import '../../../audio_healing/presentation/pages/audio_healing_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';

/// Main Navigation Page with Bottom Navigation and IndexedStack for state preservation.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // Pages loaded for each tab - using IndexedStack preserves state
  final List<Widget> _pages = const [
    DashboardPage(),
    BiofeedbackPage(),
    MoodSelectionPage(),
    AudioHealingPage(),
    ChatPage(),
  ];

  // Navigation destinations with appropriate icons for mental wellness
  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_outline),
      selectedIcon: Icon(Icons.favorite),
      label: 'Biofeedback',
    ),
    NavigationDestination(
      icon: Icon(Icons.mood_outlined),
      selectedIcon: Icon(Icons.mood),
      label: 'Mood',
    ),
    NavigationDestination(
      icon: Icon(Icons.headphones_outlined),
      selectedIcon: Icon(Icons.headphones),
      label: 'Audio',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
    ),
  ];

  void _onDestinationSelected(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
        height: 70,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shadowColor: Colors.black26,
        elevation: 8,
      ),
    );
  }
}
