import 'package:flutter/material.dart';

enum NavBarItem {
  partidos,
  equipos,
  pistas,
}

class BottomNavBar extends StatelessWidget {
  final NavBarItem selectedItem;
  final String userId;

  const BottomNavBar({
    Key? key,
    required this.selectedItem,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: const Color(0xFF5A9A7A), // Verde oscuro para la barra de navegación
      child: Row(
        children: [
          Expanded(
            child: _NavBarItem(
              icon: Icons.sports_soccer,
              label: 'Partidos',
              isSelected: selectedItem == NavBarItem.partidos,
              onTap: () {
                if (selectedItem != NavBarItem.partidos) {
                  Navigator.of(context).pushReplacementNamed(
                    '/partidos',
                    arguments: userId,
                  );
                }
              },
            ),
          ),
          Expanded(
            child: _NavBarItem(
              icon: Icons.people,
              label: 'Equipos',
              isSelected: selectedItem == NavBarItem.equipos,
              onTap: () {
                if (selectedItem != NavBarItem.equipos) {
                  Navigator.of(context).pushReplacementNamed(
                    '/equipos',
                    arguments: userId,
                  );
                }
              },
            ),
          ),
          Expanded(
            child: _NavBarItem(
              icon: Icons.place,
              label: 'Pistas',
              isSelected: selectedItem == NavBarItem.pistas,
              onTap: () {
                if (selectedItem != NavBarItem.pistas) {
                  // Cuando implementes la pantalla de pistas, descomenta esta línea
                  // Navigator.of(context).pushReplacementNamed('/pistas');
                  
                  // Por ahora, solo mostramos un mensaje
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente: Pistas')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para cada ítem de la barra de navegación
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
