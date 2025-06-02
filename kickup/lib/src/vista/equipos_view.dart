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
  const EquiposView({Key? key}) : super(key: key);

  @override
  State<EquiposView> createState() => _EquiposViewState();
}

class _EquiposViewState extends State<EquiposView> {
  // Controladores para manejar la lógica 
  final EquipoController _equipoController = EquipoController();
  final AuthController _authController = AuthController();
  final TextEditingController _searchController = TextEditingController();
  
  // Listas para manejar equipos originales y filtrados
  List<EquipoModel> _equipos = [];
  List<EquipoModel> _equiposFiltrados = [];
  bool _isLoading = true;
  late final String? userId;

  @override
  void initState() {
    super.initState();
    // Configurar listener para filtrado en tiempo real
    _searchController.addListener(_filtrarEquipos);
    userId = FirebaseAuth.instance.currentUser?.uid;
    _cargarEquipos();
  }

  @override
  void dispose() {
    // Limpiar recursos para evitar memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /// Carga todos los equipos desde el controlador con manejo de errores
  Future<void> _cargarEquipos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final equipos = await _equipoController.obtenerEquipos();
      
      // Verificar que el widget sigue montado antes de actualizar estado
      if (mounted) {
        setState(() {
          _equipos = equipos;
          _equiposFiltrados = equipos; // Inicialmente mostrar todos
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Mostrar error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar equipos: $e')),
        );
      }
    }
  }

  /// Filtra equipos basado en el texto de búsqueda
  void _filtrarEquipos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _equiposFiltrados = _equipos
          .where((equipo) => equipo.nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  /// Navega al detalle del equipo y recarga la lista al volver
  void _navegarADetalleEquipo(String equipoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleEquipoView(
          equipoId: equipoId,
          userId: userId!,
        ),
      ),
    ).then((_) => _cargarEquipos()); // Recargar al volver
  }

  /// Navega a crear equipo y recarga si se creó exitosamente
  Future<void> _navegarACrearEquipo() async {
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
    Theme.of(context);
    
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
            _buildHeader(),           // Header con título y avatar
            _buildSearchBar(),        // Barra de búsqueda
            const SizedBox(height: 16),
            _buildAddButton(),        // Botón para añadir equipo
            const SizedBox(height: 16),
            _buildTeamsList(),        // Lista/Grid de equipos
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Índice fijo para la pestaña de equipos
        onTap: (index) {
          // Navegación simplificada usando rutas nombradas
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/partidos');
          } else if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/pistas');
          }
        },
      ),
    );
  }

  /// Construye el header con título y avatar del usuario
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Equipos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          // StreamBuilder para avatar en tiempo real
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
                final data = snapshot.data!.data() as Map<String, dynamic>;
                imageUrl = data['profileImageUrl'] as String?;
              }
              
              return GestureDetector(
                onTap: () => _authController.navigateToPerfil(context),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
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
    );
  }

  /// Construye la barra de búsqueda con estilo personalizado
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51), // Equivalente a withOpacity(0.2)
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
            prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  /// Construye el botón para añadir nuevo equipo
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: _navegarACrearEquipo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'AÑADIR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la lista de equipos con diferentes estados
  Widget _buildTeamsList() {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _equiposFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Estado vacío con icono y mensaje descriptivo
                      Icon(
                        Icons.group,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        // Mensaje diferente según si hay búsqueda activa
                        _searchController.text.isEmpty
                            ? 'No hay equipos disponibles'
                            : 'No se encontraron equipos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarEquipos, // Pull-to-refresh
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,        // 2 columnas
                      childAspectRatio: 0.85,   // Proporción de aspecto
                      crossAxisSpacing: 16,     // Espacio horizontal
                      mainAxisSpacing: 16,      // Espacio vertical
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
    );
  }
}

/// Widget personalizado para mostrar cada tarjeta de equipo
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
          // Contenedor principal de la imagen del equipo
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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        // Fallback en caso de error al cargar imagen
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
          // Tipo del equipo
          Text(
            tipo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          // Nombre del equipo con overflow handling
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Truncar texto largo
          ),
        ],
      ),
    );
  }
}