import 'package:flutter/material.dart';
import 'package:flutter_application/src/controlador/auth_controller.dart';
import 'package:flutter_application/src/controlador/partido_controller.dart';
import 'package:flutter_application/src/modelo/partido_model.dart';
import 'package:flutter_application/src/vista/detalle_partido_view.dart';


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EAD9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFD7EAD9),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EFE6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              // Usar el AuthController para navegar a la pantalla de perfil
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
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide:
                                        BorderSide.none, // Sin borde visible
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
                            onPressed: () {
                              // Aquí iría la lógica para crear un nuevo partido
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
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                                    // Navegar a la pantalla de detalles del partido
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetallePartidoView(
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
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFD2C9A0), // Color beige para el botón de calendario
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text(
                          'CALENDARIO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        onTap: () {
                          // Aquí iría la lógica para ver el calendario
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Barra de navegación inferior
            Container(
              height: 60,
              padding: const EdgeInsets.only(bottom: 15),
              color: const Color(
                  0xFF5A9A7A), // Verde oscuro para la barra de navegación
              child: Row(
                children: [
                  Expanded(
                    child: _NavBarItem(
                      icon: Icons.sports_soccer,
                      label: 'Partidos',
                      isSelected: true,
                      onTap: () {},
                    ),
                  ),
                  Expanded(
                    child: _NavBarItem(
                      icon: Icons.people,
                      label: 'Equipos',
                      isSelected: false,
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/equipos');
                      },
                    ),
                  ),
                  Expanded(
                    child: _NavBarItem(
                      icon: Icons.place,
                      label: 'Pistas',
                      isSelected: false,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
