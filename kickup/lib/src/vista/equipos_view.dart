import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/vista/crear_equipo_view.dart';
import '../controlador/equipo_controller.dart';
import '../modelo/equipo_model.dart';
import 'detalle_equipo_view.dart';
import '../componentes/bottom_nav_bar.dart';
import '../controlador/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquiposView extends StatefulWidget {
  const EquiposView({
    Key? key,
  }) : super(key: key);

  @override
  State<EquiposView> createState() => _EquiposViewState();
}

class _EquiposViewState extends State<EquiposView> {
  final EquipoController _equipoController = EquipoController();
  final AuthController _authController = AuthController();
  final TextEditingController _searchController = TextEditingController();
  List<EquipoModel> _equipos = [];
  List<EquipoModel> _equiposFiltrados = [];
  bool _isLoading = true;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarEquipos);
    userId = FirebaseAuth.instance.currentUser?.uid;
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
      _equiposFiltrados = equipos;
      _isLoading = false;
    });
  }

  void _filtrarEquipos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _equiposFiltrados = _equipos
          .where((equipo) => equipo.nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  void _navegarADetalleEquipo(String equipoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEquipoView(
          equipoId: equipoId,
          userId: userId!,
        ),
      ),
    );
  }

  void _navegarACrearEquipo() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CrearEquipoView(userId: userId!),
      ),
    );

    if (result == true) {
      _cargarEquipos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Container(
        margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Equipos',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      String? imageUrl;
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        imageUrl = data['profileImageUrl'] as String?;
                      }
                      return GestureDetector(
                        onTap: () {
                          _authController.navigateToPerfil(context);
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white, // Fondo blanco del contenedor
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 208, 208, 208)
                          .withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).iconTheme.color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    filled: true, 
                    fillColor:Theme.of(context).scaffoldBackgroundColor, 
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _navegarACrearEquipo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AÑADIR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _equiposFiltrados.isEmpty
                      ? const Center(child: Text('No se encontraron equipos.'))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _equiposFiltrados.length,
                          itemBuilder: (context, index) {
                            final equipo = _equiposFiltrados[index];
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
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/partidos');
              break;
            case 1:
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
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: (logoUrl.isNotEmpty)
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
