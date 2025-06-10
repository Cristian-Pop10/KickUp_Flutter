import 'package:flutter/material.dart';
import 'package:kickup/src/componentes/app_styles.dart';
import 'package:kickup/src/vista/politica_privacidad_view.dart';
import 'package:kickup/src/vista/terminos_condiciones_view.dart';
import 'package:provider/provider.dart';
import 'package:kickup/src/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/** Vista de configuración de la aplicación.
   Permite al usuario gestionar preferencias como tema, notificaciones,
   acceder a información legal y realizar acciones de cuenta como eliminación.
   Integra con Firebase Auth y Firestore para operaciones de usuario. */
class ConfiguracionView extends StatefulWidget {
  const ConfiguracionView({super.key});

  @override
  State<ConfiguracionView> createState() => _ConfiguracionViewState();
}

class _ConfiguracionViewState extends State<ConfiguracionView> {
  /** Estado local para controlar si las notificaciones están activas */
  bool _notificacionesActivas = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECCIÓN DE APARIENCIA
          Text(
            'Apariencia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),

          /** Switch para alternar entre modo claro y oscuro.
             Se conecta con ThemeProvider para persistir la configuración. */
          SwitchListTile(
            title: Text(
              'Modo oscuro',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const Divider(height: 32),

          // SECCIÓN DE NOTIFICACIONES
          Text(
            'Notificaciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),

          /** Switch para activar/desactivar notificaciones push.
             Controla el estado local de notificaciones. */
          SwitchListTile(
            title: Text(
              'Activar notificaciones',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            value: _notificacionesActivas,
            onChanged: (value) {
              setState(() {
                _notificacionesActivas = value;
              });
            },
          ),
          const Divider(height: 32),

          // SECCIÓN DE OTROS AJUSTES
          Text(
            'Otros ajustes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),

          /** Enlace a términos y condiciones (placeholder) */
          ListTile(
            title: const Text('Términos y condiciones'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TerminosCondicionesView(),
                ),
              );
            },
          ),

          /** Enlace a política de privacidad (placeholder) */
          ListTile(
            title: const Text('Política de privacidad'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PoliticaPrivacidadView(),
                ),
              );
            },
          ),
          const Divider(height: 32),

          /** Botón para eliminar cuenta permanentemente.
             Implementa un flujo de confirmación de dos pasos:
             1. Confirmación de intención
             2. Reautenticación con contraseña
             
             Elimina tanto el documento de Firestore como la cuenta de Auth. */
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Borrar cuenta'),
            onPressed: () async {
              // Primer diálogo: Confirmación de intención
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Estás seguro?'),
                  content: const Text(
                      'Esta acción eliminará tu cuenta permanentemente. ¿Deseas continuar?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text('Borrar'),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final user = FirebaseAuth.instance.currentUser;

                  // Segundo diálogo: Reautenticación con contraseña
                  final passwordController = TextEditingController();
                  final passwordOk = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reautenticación'),
                      content: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Introduce tu contraseña'),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text('Continuar'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (passwordOk == true &&
                      user != null &&
                      user.email != null) {
                    // Reautenticar usuario
                    final cred = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(cred);

                    // Eliminar documento de Firestore antes de eliminar Auth
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(user.uid)
                        .delete();

                    // Eliminar cuenta de Firebase Auth
                    await user.delete();

                    // Navegar a login y limpiar stack de navegación
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  }
                } catch (e) {
                  // Mostrar error si algo falla en el proceso
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al borrar la cuenta: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
