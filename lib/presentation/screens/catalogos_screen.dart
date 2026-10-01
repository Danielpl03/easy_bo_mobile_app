import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/categoria.dart';
import 'package:easy_bo_mobile_app/models/departamento.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

// ─────────────────────────────────────────────────────────────────────────────
// Provider local para esta pantalla
// ─────────────────────────────────────────────────────────────────────────────

class _CatalogosState extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );
  final LocalStorageService _localStorage = LocalStorageService();

  List<Departamento> departamentos = [];
  List<Categoria> categorias = [];
  bool cargando = false;
  String? error;

  List<Categoria> categoriasDeDepto(int idDepartamento) =>
      categorias.where((c) => c.idDepartamento == idDepartamento).toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final deptos = await _supabaseService.getAllDepartamentos();
      final cats = await _supabaseService.getAllCategorias();
      departamentos = deptos..sort((a, b) => a.orden.compareTo(b.orden));
      categorias = cats;
    } on SocketException {
      error = 'Sin conexión a internet';
    } on PostgrestException catch (e) {
      error = 'Error Supabase: ${e.message}';
    } catch (e) {
      error = 'Error: $e';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  // ── Departamentos ──────────────────────────────────────────────────────────

  Future<String?> crearDepartamento({
    required String nombre,
    required int orden,
    required bool web,
  }) async {
    try {
      final response =
          await SupabaseConfig.client
              .from('departamentos')
              .insert({'departamento': nombre, 'orden': orden, 'web': web})
              .select()
              .single();
      final nuevo = Departamento.fromJson(response);
      departamentos.add(nuevo);
      departamentos.sort((a, b) => a.orden.compareTo(b.orden));
      await _sincronizarDeptos();
      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editarDepartamento(Departamento depto) async {
    try {
      await SupabaseConfig.client
          .from('departamentos')
          .update({
            'departamento': depto.nombre,
            'orden': depto.orden,
            'web': depto.web,
          })
          .eq('id_departamento', depto.idDepartamento);
      final idx = departamentos.indexWhere(
        (d) => d.idDepartamento == depto.idDepartamento,
      );
      if (idx != -1) departamentos[idx] = depto;
      departamentos.sort((a, b) => a.orden.compareTo(b.orden));
      await _sincronizarDeptos();
      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> eliminarDepartamento(int idDepartamento) async {
    final tieneCategorias = categorias.any(
      (c) => c.idDepartamento == idDepartamento,
    );
    if (tieneCategorias) {
      return 'No se puede eliminar: el departamento tiene categorías asociadas.';
    }
    try {
      await SupabaseConfig.client
          .from('departamentos')
          .delete()
          .eq('id_departamento', idDepartamento);
      departamentos.removeWhere((d) => d.idDepartamento == idDepartamento);
      await _sincronizarDeptos();
      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Categorías ─────────────────────────────────────────────────────────────

  Future<String?> crearCategoria({
    required String nombre,
    required int idDepartamento,
    required bool web,
  }) async {
    try {
      final response =
          await SupabaseConfig.client
              .from('categorias')
              .insert({
                'nombre': nombre,
                'id_departamento': idDepartamento,
                'web': web,
              })
              .select()
              .single();
      final nueva = Categoria.fromJson(response);
      categorias.add(nueva);
      await _sincronizarCats();
      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editarCategoria(Categoria cat) async {
    try {
      await SupabaseConfig.client
          .from('categorias')
          .update({
            'nombre': cat.nombre,
            'id_departamento': cat.idDepartamento,
            'web': cat.web,
          })
          .eq('id_categoria', cat.idCategoria);
      final idx = categorias.indexWhere(
        (c) => c.idCategoria == cat.idCategoria,
      );
      if (idx != -1) categorias[idx] = cat;
      await _sincronizarCats();
      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> eliminarCategoria(int idCategoria) async {
    try {
      await SupabaseConfig.client
          .from('categorias')
          .delete()
          .eq('id_categoria', idCategoria);
      categorias.removeWhere((c) => c.idCategoria == idCategoria);
      await _sincronizarCats();
      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Sincronización local ───────────────────────────────────────────────────

  Future<void> _sincronizarDeptos() async {
    await _localStorage.saveDepartamentos(departamentos);
  }

  Future<void> _sincronizarCats() async {
    await _localStorage.saveCategorias(categorias);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extensión en SupabaseService para obtener TODOS los registros (sin filtro web)
// ─────────────────────────────────────────────────────────────────────────────

extension SupabaseServiceCatalogosExt on SupabaseService {
  Future<List<Departamento>> getAllDepartamentos() async {
    final response = await SupabaseConfig.client
        .from('departamentos')
        .select()
        .order('orden');
    return (response as List).map((j) => Departamento.fromJson(j)).toList();
  }

  Future<List<Categoria>> getAllCategorias() async {
    final response = await SupabaseConfig.client
        .from('categorias')
        .select()
        .order('nombre');
    return (response as List).map((j) => Categoria.fromJson(j)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal
// ─────────────────────────────────────────────────────────────────────────────

class CatalogosScreen extends StatefulWidget {
  const CatalogosScreen({super.key});

  @override
  State<CatalogosScreen> createState() => _CatalogosScreenState();
}

class _CatalogosScreenState extends State<CatalogosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final _CatalogosState _state;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _state = _CatalogosState();
    _state.cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _state,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catálogos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar desde servidor',
              onPressed: _state.cargar,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.category_outlined), text: 'Departamentos'),
              Tab(icon: Icon(Icons.label_outline), text: 'Categorías'),
            ],
          ),
        ),
        body: Consumer<_CatalogosState>(
          builder: (context, state, _) {
            if (state.cargando) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return _ErrorView(error: state.error!, onRetry: state.cargar);
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _DepartamentosTab(state: state),
                _CategoriasTab(state: state),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<_CatalogosState>(
          builder: (context, state, _) {
            if (state.cargando) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed:
                  () =>
                      _tabController.index == 0
                          ? _mostrarFormDepartamento(context, state)
                          : _mostrarFormCategoria(context, state),
              icon: const Icon(Icons.add),
              label: AnimatedBuilder(
                animation: _tabController,
                builder:
                    (_, __) => Text(
                      _tabController.index == 0 ? 'Departamento' : 'Categoría',
                    ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Diálogos ───────────────────────────────────────────────────────────────

  void _mostrarFormDepartamento(
    BuildContext context,
    _CatalogosState state, {
    Departamento? depto,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => _DialogoDepartamento(
            state: state,
            departamento: depto,
            onGuardado: () {
              // Refresca el ProductosProvider para que los filtros también se actualicen
              if (context.mounted) {
                context.read<ProductosProvider>().getCatalogos(
                  forceUpdate: true,
                );
              }
            },
          ),
    );
  }

  void _mostrarFormCategoria(
    BuildContext context,
    _CatalogosState state, {
    Categoria? cat,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => _DialogoCategoria(
            state: state,
            categoria: cat,
            onGuardado: () {
              if (context.mounted) {
                context.read<ProductosProvider>().getCatalogos(
                  forceUpdate: true,
                );
              }
            },
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Departamentos
// ─────────────────────────────────────────────────────────────────────────────

class _DepartamentosTab extends StatelessWidget {
  const _DepartamentosTab({required this.state});
  final _CatalogosState state;

  @override
  Widget build(BuildContext context) {
    if (state.departamentos.isEmpty) {
      return const _EmptyView(mensaje: 'No hay departamentos registrados.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.departamentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final depto = state.departamentos[i];
        final cantCats = state.categoriasDeDepto(depto.idDepartamento).length;
        return _DepartamentoCard(
          departamento: depto,
          cantCategorias: cantCats,
          onEditar: () => _editar(context, depto),
          onEliminar: () => _eliminar(context, depto),
        );
      },
    );
  }

  void _editar(BuildContext context, Departamento depto) {
    showDialog(
      context: context,
      builder: (_) => _DialogoDepartamento(state: state, departamento: depto),
    );
  }

  Future<void> _eliminar(BuildContext context, Departamento depto) async {
    final confirmar = await _confirmarEliminacion(
      context,
      'departamento',
      depto.nombre,
    );
    if (!confirmar || !context.mounted) return;

    final error = await state.eliminarDepartamento(depto.idDepartamento);
    if (context.mounted) {
      _mostrarResultado(context, error, 'Departamento eliminado');
      if (error == null) {
        context.read<ProductosProvider>().getCatalogos(forceUpdate: true);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Categorías
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriasTab extends StatefulWidget {
  const _CategoriasTab({required this.state});
  final _CatalogosState state;

  @override
  State<_CategoriasTab> createState() => _CategoriasTabState();
}

class _CategoriasTabState extends State<_CategoriasTab> {
  int? _deptoFiltro;

  List<Categoria> get _catsFiltradas {
    if (_deptoFiltro == null) return widget.state.categorias;
    return widget.state.categoriasDeDepto(_deptoFiltro!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deptos = widget.state.departamentos;
    final cats = _catsFiltradas..sort((a, b) => a.nombre.compareTo(b.nombre));

    return Column(
      children: [
        // Filtro por departamento
        if (deptos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<int?>(
              value: _deptoFiltro,
              decoration: InputDecoration(
                labelText: 'Filtrar por departamento',
                prefixIcon: const Icon(Icons.filter_list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los departamentos'),
                ),
                ...deptos.map(
                  (d) => DropdownMenuItem(
                    value: d.idDepartamento,
                    child: Text(d.nombre),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _deptoFiltro = v),
            ),
          ),
        const SizedBox(height: 8),

        // Contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${cats.length} categoría${cats.length != 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child:
              cats.isEmpty
                  ? const _EmptyView(mensaje: 'No hay categorías registradas.')
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final cat = cats[i];
                      final nombreDepto =
                          widget.state.departamentos
                              .firstWhere(
                                (d) => d.idDepartamento == cat.idDepartamento,
                                orElse:
                                    () => Departamento(
                                      idDepartamento: 0,
                                      nombre: 'Desconocido',
                                    ),
                              )
                              .nombre;
                      return _CategoriaCard(
                        categoria: cat,
                        nombreDepartamento: nombreDepto,
                        onEditar: () => _editar(context, cat),
                        onEliminar: () => _eliminar(context, cat),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void _editar(BuildContext context, Categoria cat) {
    showDialog(
      context: context,
      builder: (_) => _DialogoCategoria(state: widget.state, categoria: cat),
    );
  }

  Future<void> _eliminar(BuildContext context, Categoria cat) async {
    final confirmar = await _confirmarEliminacion(
      context,
      'categoría',
      cat.nombre,
    );
    if (!confirmar || !context.mounted) return;

    final error = await widget.state.eliminarCategoria(cat.idCategoria);
    if (context.mounted) {
      _mostrarResultado(context, error, 'Categoría eliminada');
      if (error == null) {
        context.read<ProductosProvider>().getCatalogos(forceUpdate: true);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards
// ─────────────────────────────────────────────────────────────────────────────

class _DepartamentoCard extends StatelessWidget {
  const _DepartamentoCard({
    required this.departamento,
    required this.cantCategorias,
    required this.onEditar,
    required this.onEliminar,
  });

  final Departamento departamento;
  final int cantCategorias;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${departamento.orden}',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          departamento.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.label_outline,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$cantCategorias categoría${cantCategorias != 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _ChipWeb(activo: departamento.web),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: onEditar,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Eliminar',
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  const _CategoriaCard({
    required this.categoria,
    required this.nombreDepartamento,
    required this.onEditar,
    required this.onEliminar,
  });

  final Categoria categoria;
  final String nombreDepartamento;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.label_outline,
            color: theme.colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                nombreDepartamento,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _ChipWeb(activo: categoria.web),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: onEditar,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Eliminar',
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipWeb extends StatelessWidget {
  const _ChipWeb({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            activo
                ? Colors.green.withOpacity(0.12)
                : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              activo
                  ? Colors.green.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.4),
        ),
      ),
      child: Text(
        activo ? 'Web' : 'Oculto',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: activo ? Colors.green[700] : Colors.grey[600],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo Departamento
// ─────────────────────────────────────────────────────────────────────────────

class _DialogoDepartamento extends StatefulWidget {
  const _DialogoDepartamento({
    required this.state,
    this.departamento,
    this.onGuardado,
  });

  final _CatalogosState state;
  final Departamento? departamento;
  final VoidCallback? onGuardado;

  @override
  State<_DialogoDepartamento> createState() => _DialogoDepartamentoState();
}

class _DialogoDepartamentoState extends State<_DialogoDepartamento> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ordenCtrl;
  late bool _web;
  bool _guardando = false;

  bool get esEdicion => widget.departamento != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(
      text: widget.departamento?.nombre ?? '',
    );
    _ordenCtrl = TextEditingController(
      text:
          widget.departamento?.orden.toString() ??
          (widget.state.departamentos.length + 1).toString(),
    );
    _web = widget.departamento?.web ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ordenCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final nombre = _nombreCtrl.text.trim();
    final orden = int.tryParse(_ordenCtrl.text.trim()) ?? 0;

    String? error;
    if (esEdicion) {
      final actualizado = Departamento(
        idDepartamento: widget.departamento!.idDepartamento,
        nombre: nombre,
        orden: orden,
        web: _web,
      );
      error = await widget.state.editarDepartamento(actualizado);
    } else {
      error = await widget.state.crearDepartamento(
        nombre: nombre,
        orden: orden,
        web: _web,
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      _mostrarResultado(context, error, '');
    } else {
      widget.onGuardado?.call();
      Navigator.pop(context);
      _mostrarResultado(
        context,
        null,
        esEdicion ? 'Departamento actualizado' : 'Departamento creado',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Icon(
                      esEdicion
                          ? Icons.edit_outlined
                          : Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      esEdicion ? 'Editar Departamento' : 'Nuevo Departamento',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: _inputDecoration(
                    'Nombre',
                    Icons.category_outlined,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                ),
                const SizedBox(height: 16),

                // Orden
                TextFormField(
                  controller: _ordenCtrl,
                  decoration: _inputDecoration('Orden', Icons.sort),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                ),
                const SizedBox(height: 16),

                // Visible en web
                SwitchListTile(
                  title: const Text('Visible en web'),
                  subtitle: Text(
                    _web
                        ? 'Se muestra en la tienda online'
                        : 'Oculto en la tienda online',
                  ),
                  value: _web,
                  onChanged: (v) => setState(() => _web = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _guardando ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child:
                            _guardando
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(esEdicion ? 'Actualizar' : 'Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo Categoría
// ─────────────────────────────────────────────────────────────────────────────

class _DialogoCategoria extends StatefulWidget {
  const _DialogoCategoria({
    required this.state,
    this.categoria,
    this.onGuardado,
  });

  final _CatalogosState state;
  final Categoria? categoria;
  final VoidCallback? onGuardado;

  @override
  State<_DialogoCategoria> createState() => _DialogoCategoriaState();
}

class _DialogoCategoriaState extends State<_DialogoCategoria> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  int? _idDepartamento;
  late bool _web;
  bool _guardando = false;

  bool get esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.categoria?.nombre ?? '');
    _idDepartamento = widget.categoria?.idDepartamento;
    _web = widget.categoria?.web ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final nombre = _nombreCtrl.text.trim();

    String? error;
    if (esEdicion) {
      final actualizada = Categoria(
        idCategoria: widget.categoria!.idCategoria,
        idDepartamento: _idDepartamento!,
        nombre: nombre,
        web: _web,
      );
      error = await widget.state.editarCategoria(actualizada);
    } else {
      error = await widget.state.crearCategoria(
        nombre: nombre,
        idDepartamento: _idDepartamento!,
        web: _web,
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      _mostrarResultado(context, error, '');
    } else {
      widget.onGuardado?.call();
      Navigator.pop(context);
      _mostrarResultado(
        context,
        null,
        esEdicion ? 'Categoría actualizada' : 'Categoría creada',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Icon(
                      esEdicion
                          ? Icons.edit_outlined
                          : Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      esEdicion ? 'Editar Categoría' : 'Nueva Categoría',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: _inputDecoration('Nombre', Icons.label_outline),
                  textCapitalization: TextCapitalization.words,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                ),
                const SizedBox(height: 16),

                // Departamento
                DropdownButtonFormField<int>(
                  value: _idDepartamento,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    'Departamento',
                    Icons.category_outlined,
                  ),
                  items:
                      widget.state.departamentos
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.idDepartamento,
                              child: Text(
                                d.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _idDepartamento = v),
                  validator:
                      (v) => v == null ? 'Selecciona un departamento' : null,
                ),
                const SizedBox(height: 16),

                // Visible en web
                SwitchListTile(
                  title: const Text('Visible en web'),
                  subtitle: Text(
                    _web
                        ? 'Se muestra en la tienda online'
                        : 'Oculto en la tienda online',
                  ),
                  value: _web,
                  onChanged: (v) => setState(() => _web = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _guardando ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child:
                            _guardando
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(esEdicion ? 'Actualizar' : 'Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers globales del archivo
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

Future<bool> _confirmarEliminacion(
  BuildContext context,
  String tipo,
  String nombre,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Confirmar eliminación'),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar el $tipo "$nombre"?\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
  );
  return result ?? false;
}

void _mostrarResultado(BuildContext context, String? error, String exito) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error != null ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(error ?? exito)),
        ],
      ),
      backgroundColor: error != null ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Vistas auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
