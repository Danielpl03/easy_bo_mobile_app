import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CompanySelectionScreen extends StatefulWidget {
  final VoidCallback? onCompanySelected;

  const CompanySelectionScreen({super.key, this.onCompanySelected});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  String _getCompanyDisplayName(String key) {
    // Convertir la clave a un nombre más legible
    switch (key.toLowerCase()) {
      case 'default':
        return 'Configuración por Defecto';
      case 'la_calzada':
        return 'La Calzada';
      case 'ml_soluciones':
        return '';
      default:
        // Convertir snake_case a título legible
        return key
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final enteredKey = _keyController.text.trim().toLowerCase();

    if (!SupabaseConfig.isValidConfigKey(enteredKey)) {
      setState(() {
        _errorMessage =
            'La clave ingresada no es válida. Por favor, verifica e intenta nuevamente.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Establecer la clave de configuración
      await SupabaseConfig.setConfigKey(enteredKey);

      // Inicializar Supabase con la clave seleccionada
      await SupabaseConfig.initialize();

      // Inicializar package_info_plus
      await PackageInfo.fromPlatform();

      if (mounted) {
        // Llamar al callback para que la app cambie a MyApp
        widget.onCompanySelected?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Error al conectar con la base de datos: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableKeys = SupabaseConfig.getAvailableConfigKeys();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo y título
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Selección de Empresa',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa la clave de tu empresa',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Campo de clave
                TextFormField(
                  controller: _keyController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Clave de Empresa',
                    // hintText: 'Ej: la_calzada, default',
                    prefixIcon: Icon(Icons.vpn_key),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa la clave de tu empresa';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Lista de claves disponibles (solo visualización)
                // if (availableKeys.isNotEmpty) ...[
                //   Text(
                //     'Claves disponibles:',
                //     style: Theme.of(context).textTheme.titleSmall?.copyWith(
                //           fontWeight: FontWeight.bold,
                //         ),
                //   ),
                //   const SizedBox(height: 12),
                //   ...availableKeys.map((key) {
                //     return Padding(
                //       padding: const EdgeInsets.only(bottom: 8.0),
                //       child: Container(
                //         padding: const EdgeInsets.all(12),
                //         decoration: BoxDecoration(
                //           color: Theme.of(context).primaryColor.withOpacity(0.1),
                //           borderRadius: BorderRadius.circular(8),
                //           border: Border.all(
                //             color: Theme.of(context).primaryColor.withOpacity(0.3),
                //           ),
                //         ),
                //         child: Row(
                //           children: [
                //             Icon(
                //               Icons.check_circle_outline,
                //               color: Theme.of(context).primaryColor,
                //               size: 20,
                //             ),
                //             const SizedBox(width: 12),
                //             Expanded(
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text(
                //                     _getCompanyDisplayName(key),
                //                     style: const TextStyle(
                //                       fontWeight: FontWeight.bold,
                //                     ),
                //                   ),
                //                   Text(
                //                     key,
                //                     style: TextStyle(
                //                       fontSize: 12,
                //                       color: Theme.of(context)
                //                           .textTheme
                //                           .bodySmall
                //                           ?.color,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     );
                //   }),
                //   const SizedBox(height: 24),
                // ],

                // Botón de continuar
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'Continuar',
                            style: TextStyle(fontSize: 16),
                          ),
                ),

                const SizedBox(height: 16),

                // Mensaje de error
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
