import 'package:flutter/material.dart';
import '../deployment_features.dart';
import '../chat_page.dart';
import '../profile.dart';
import '../your_journals.dart';
import 'activity_near_me.dart';
import 'gpt_summary.dart';

class BottomNavigationBarControl extends StatefulWidget {
  const BottomNavigationBarControl({super.key});
  @override
  State<BottomNavigationBarControl> createState() =>
      _BottomNavigationBarControlState();
}

class _BottomNavigationBarControlState
    extends State<BottomNavigationBarControl> {
  int _selectedIndex = 0;
  static const _pages = <Widget>[
    YourJournals(),
    GPTSummaryScreen(),
    if (DeploymentFeatures.aiEnabled) ChatPage(),
    ActivityNearMePage(),
    ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pages[_selectedIndex],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          label: 'Journal',
        ),
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outline),
          label: 'Reflect',
        ),
        if (DeploymentFeatures.aiEnabled)
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'AI companion',
          ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  );
}
