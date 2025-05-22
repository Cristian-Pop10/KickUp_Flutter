import 'package:flutter/material.dart';
import 'package:flutter_application/src/controlador/auth_controller.dart';
import 'package:flutter_application/src/controlador/partido_controller.dart';
import 'package:flutter_application/src/modelo/partido_model.dart';
import 'package:flutter_application/src/vista/detalle_partido_view.dart';
import 'package:flutter_application/src/vista/crear_partido_view.dart';
import '../componentes/bottom_nav_bar.dart';

class PartidosView extends StatefulWidget {
  final String userId;

  const PartidosView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<PartidosView> createState() => _PartidosViewState();
}

class _PartidosViewState extends State<PartidosView> {
  final PartidoController _partidoController = PartidoController();
  final AuthController _authController =
      AuthController(); // Instancia del AuthController
  final TextEditingController _searchController = TextEditingController();
  List<PartidoModel> _partidos = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final List<Widget> _screens = []; // Aquí puedes definir las pantallas
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarPartidos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarPartidos() async {
    setState(() {
      _isLoading = true;
    });

    final partidos = await _partidoController.obtenerPartidos();

    setState(() {
      _partidos = partidos;
      _isLoading = false;
    });
  }

  Future<void> _buscarPartidos(String query) async {
    setState(() {
      _isSearching = true;
    });

    final resultados = await _partidoController.buscarPartidos(query);

    setState(() {
      _partidos = resultados;
      _isSearching = false;
    });
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day;
    final mes = _obtenerNombreMes(fecha.month);
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia de $mes,$anio - $hora:$minuto';
  }

  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes - 1];
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navegar a la pantalla correspondiente
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/partidos');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/equipos');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/pistas');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EAD9), // Fondo verde claro
      body: Container(
        margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EFE6), // Fondo más claro para el contenido
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            // Espacio en la parte superior
            const SizedBox(height: 16),

            // Encabezado con el título y el botón de perfil
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Listado partidos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _authController.navigateToPerfil(context);
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                  ),
                ],
              ),
            ),

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D7D7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _buscarPartidos,
                        decoration: InputDecoration(
                          hintText: 'Buscar',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final partidoCreado = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => CrearPartidoView(userId: widget.userId),
                        ),
                      );

                      // Si se creó un partido, recargar la lista
                      if (partidoCreado == true) {
                        _cargarPartidos();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'crear partido',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9A7A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista de partidos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _partidos.length,
                      itemBuilder: (context, index) {
                        final partido = _partidos[index];
                        return _PartidoCard(
                          fecha: _formatearFecha(partido.fecha),
                          tipo: partido.tipo,
                          lugar: partido.lugar,
                          completo: partido.completo,
                          faltantes: partido.jugadoresFaltantes,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DetallePartidoView(
                                  partidoId: partido.id,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}

// Widget para cada tarjeta de partido
class _PartidoCard extends StatelessWidget {
  final String fecha;
  final String tipo;
  final String lugar;
  final bool completo;
  final int faltantes;
  final VoidCallback onTap;

  const _PartidoCard({
    Key? key,
    required this.fecha,
    required this.tipo,
    required this.lugar,
    required this.completo,
    required this.faltantes,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD2C9A0), // Color beige para las tarjetas
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  fecha,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$tipo $lugar',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              completo ? 'Completo' : 'Faltan $faltantes',
              style: TextStyle(
                color: completo ? Colors.grey : Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
