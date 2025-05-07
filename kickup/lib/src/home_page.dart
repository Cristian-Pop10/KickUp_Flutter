import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(icon: Icon(Icons.sports_soccer_rounded), label: 'Partidos'),
    BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Equipos'),
    BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Pistas'),
  ];

  final List<Widget> destinations = [
    Scaffold(body: Center(child: Text('Partidos'))),
    Scaffold(body: Center(child: Text('Equipos'))),
    Scaffold(body: Center(child: Text('Pistas'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: destinations,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
