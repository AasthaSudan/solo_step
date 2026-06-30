import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({
    super.key,
    required this.navigationShell,
  });

  void _onNavigationItemSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use a NavigationRail for larger screens (tablets/desktops)
            // and a bottom NavigationBar for smaller screens (phones)
            if (constraints.maxWidth > 600) {
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _onNavigationItemSelected,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.map_outlined),
                        selectedIcon: Icon(Icons.map),
                        label: Text('Trips'),
                      ),

                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Profile'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: navigationShell,
                  ),
                ],
              );
            }

            // Bottom navigation for typical mobile view
            return navigationShell;
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onNavigationItemSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Trips',
                ),

                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }
}
