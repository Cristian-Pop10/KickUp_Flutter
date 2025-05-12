import 'package:flutter/material.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'detalle_equipo_view.dart';
import 'bottom_nav_bar.dart';

class EquiposView extends StatefulWidget {
  final String userId;

  const EquiposView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<EquiposView> createState() => _EquiposViewState();
}

class _EquiposViewState extends State<EquiposView> {
  final EquipoController _equipoController = EquipoController();
  final TextEditingController _searchController = TextEditingController();
  List<EquipoModel> _equipos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEquipos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarEquipos() async {
    setState(() {
      _isLoading = true;
    });

    final equipos = await _equipoController.obtenerEquipos();

    setState(() {
      _equipos = equipos;
      _isLoading = false;
    });
  }

  void _navegarADetalleEquipo(String equipoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEquipoView(
          equipoId: equipoId,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EAD9), // Fondo verde claro
      body: Container(
        margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EFE6), // Fondo más claro para el contenido
          borderRadius: BorderRadius.circular(20),
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
                    'Equipos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/perfil');
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
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7D7D7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    // Lógica de búsqueda
                  },
                  decoration: const InputDecoration(
                    hintText: 'Buscar',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lista de equipos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _equipos.length,
                      itemBuilder: (context, index) {
                        final equipo = _equipos[index];
                        return _EquipoCard(
                          nombre: equipo.nombre,
                          tipo: equipo.tipo,
                          logoUrl: equipo.logoUrl,
                          onTap: () => _navegarADetalleEquipo(equipo.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Índice de la pantalla actual
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/partidos');
              break;
            case 1:
              // Ya estamos en esta pantalla
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/pistas');
              break;
          }
        },
      ),
    );
  }
}

// Widget para cada tarjeta de equipo
class _EquipoCard extends StatelessWidget {
  final String nombre;
  final String tipo;
  final String logoUrl;
  final VoidCallback onTap;

  const _EquipoCard({
    Key? key,
    required this.nombre,
    required this.tipo,
    required this.logoUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo del equipo
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
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
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tipo de fútbol
          Text(
            tipo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Nombre del equipo
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
