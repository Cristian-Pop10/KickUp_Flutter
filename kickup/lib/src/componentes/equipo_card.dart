import 'package:flutter/material.dart';

/**  
 * Widget que representa una tarjeta de equipo en la aplicación.
 * Muestra la información básica de un equipo incluyendo su logo, nombre y tipo.
 * Soporta modo de selección para administradores con indicadores visuales. */
class EquipoCard extends StatelessWidget {

  /// Nombre del equipo a mostrar
  final String nombre;

  /// Tipo o categoría del equipo 
  final String tipo;

  /// URL de la imagen del logo del equipo
  final String logoUrl;

  /// Indica si el usuario actual es administrador
  final bool esAdmin;

  /// Indica si la vista está en modo selección
  final bool modoSeleccion;

  /// Indica si este equipo está seleccionado actualmente
  final bool seleccionado;

  /// Función a ejecutar cuando se toca la tarjeta
  final VoidCallback onTap;

  /// Función opcional a ejecutar cuando se mantiene presionada la tarjeta
  final VoidCallback? onLongPress;

  const EquipoCard({
    Key? key,
    required this.nombre,
    required this.tipo,
    required this.logoUrl,
    required this.esAdmin,
    required this.modoSeleccion,
    required this.seleccionado,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: seleccionado
                        ? Border.all(color: Colors.blue, width: 3)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: logoUrl.isNotEmpty
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.sports_soccer,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.sports_soccer,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tipo,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (esAdmin && modoSeleccion)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: seleccionado,
                  onChanged: (_) => onTap(),
                  activeColor: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
