import 'package:flutter/material.dart';
import 'dart:math' as math;

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> 
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _rippleController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rippleAnimation;
  
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    
    // Controlador para el deslizamiento del blob
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Controlador para el efecto de rebote
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Controlador para el efecto ripple
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    );
    
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );
    
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    );
    
    _slideController.forward();
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _slideController.reset();
      _bounceController.reset();
      _rippleController.reset();
      
      _slideController.forward();
      _bounceController.forward();
      _rippleController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Efecto de blob animado de fondo
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final double startPosition = _previousIndex / 3;
              final double endPosition = widget.currentIndex / 3;
              final double position = Tween<double>(
                begin: startPosition,
                end: endPosition,
              ).evaluate(_slideAnimation);
              
              return Positioned(
                top: 10,
                bottom: 10,
                left: MediaQuery.of(context).size.width * position + 20,
                width: MediaQuery.of(context).size.width / 3 - 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(51),
                        Colors.white.withAlpha(25),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withAlpha(25),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Efecto ripple al tocar
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              return Positioned(
                top: 35 - (30 * _rippleAnimation.value),
                left: (MediaQuery.of(context).size.width / 3 * widget.currentIndex) + 
                      (MediaQuery.of(context).size.width / 6) - (30 * _rippleAnimation.value),
                width: 60 * _rippleAnimation.value,
                height: 60 * _rippleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha((255 * (1 - _rippleAnimation.value)).round()),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Elementos de navegación
          Row(
            children: [
              _buildNavItem(0, Icons.sports_soccer, 'Partidos'),
              _buildNavItem(1, Icons.people, 'Equipos'),
              _buildNavItem(2, Icons.place, 'Pistas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = widget.currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        child: AnimatedBuilder(
          animation: Listenable.merge([_bounceAnimation, _slideAnimation]),
          builder: (context, child) {
            // Animación de rebote para el elemento seleccionado
            final double bounceValue = isSelected ? _bounceAnimation.value : 1.0;
            final double scaleValue = isSelected 
                ? 1.0 + (0.15 * math.sin(bounceValue * math.pi))
                : 1.0;
            
            return Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono con animación de rebote y rotación
                  Transform.scale(
                    scale: scaleValue,
                    child: Transform.rotate(
                      angle: isSelected ? 0.1 * math.sin(_bounceAnimation.value * math.pi * 2) : 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: isSelected ? BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withAlpha(76),
                              Colors.transparent,
                            ],
                          ),
                        ) : null,
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // Texto con animación de aparición
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.7,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: isSelected ? 13 : 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  
                  // Indicador de puntos animados
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (dotIndex) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200 + (dotIndex * 50)),
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: isSelected ? 4 : 2,
                          height: isSelected ? 4 : 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected 
                                ? Colors.white.withAlpha(200)
                                : Colors.transparent,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}