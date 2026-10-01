import 'package:easy_bo_mobile_app/models/categoria.dart';
import 'package:easy_bo_mobile_app/models/departamento.dart';
import 'package:easy_bo_mobile_app/models/moneda.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ProductoFormDialog extends StatefulWidget {
  const ProductoFormDialog({super.key, this.producto});

  final Producto? producto;

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _costoCtrl;
  late final Map<int, TextEditingController> _precioCtrls;

  int? _idDepartamento;
  int? _idCategoria;
  late bool _ipv;
  late bool _activo;
  late bool _combo;
  late bool _web;
  bool _guardando = false;

  bool get esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _codigoCtrl = TextEditingController(text: p?.codigo ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _costoCtrl = TextEditingController(
      text: p?.costo != null ? p!.costo.toString() : '',
    );
    _idDepartamento = p?.idDepartamento;
    _idCategoria = p?.idCategoria;
    _ipv = p?.ipv ?? false;
    _activo = p?.activo ?? true;
    _combo = p?.combo ?? false;
    _web = p?.web ?? true;
    _precioCtrls = {};
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _codigoCtrl.dispose();
    _barcodeCtrl.dispose();
    _costoCtrl.dispose();
    for (final ctrl in _precioCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _inicializarPrecios(List<Moneda> monedas) {
    for (final moneda in monedas) {
      if (_precioCtrls.containsKey(moneda.idMoneda)) continue;
      final precioExistente = widget.producto?.precios
          .where((pr) => pr.idMoneda == moneda.idMoneda)
          .firstOrNull;
      _precioCtrls[moneda.idMoneda] = TextEditingController(
        text:
            precioExistente != null && precioExistente.precio > 0
                ? precioExistente.precio.toString()
                : '',
      );
    }
  }

  Map<int, double> _leerPrecios() {
    final precios = <int, double>{};
    for (final entry in _precioCtrls.entries) {
      final valor = double.tryParse(entry.value.text.trim().replaceAll(',', '.'));
      if (valor != null && valor > 0) {
        precios[entry.key] = valor;
      }
    }
    return precios;
  }

  List<Departamento> _departamentosDropdown(ProductosProvider provider) {
    final map = <int, Departamento>{};
    for (final d in provider.departamentos) {
      map[d.idDepartamento] = d;
    }
    final producto = widget.producto;
    if (producto != null && !map.containsKey(producto.idDepartamento)) {
      map[producto.idDepartamento] = Departamento(
        idDepartamento: producto.idDepartamento,
        nombre: 'Departamento ${producto.idDepartamento}',
        web: false,
      );
    }
    return map.values.toList()..sort((a, b) => a.orden.compareTo(b.orden));
  }

  List<Categoria> _categoriasDropdown(ProductosProvider provider) {
    if (_idDepartamento == null) return [];
    final map = <int, Categoria>{};
    for (final c in provider.categorias) {
      if (c.idDepartamento == _idDepartamento) {
        map[c.idCategoria] = c;
      }
    }
    final producto = widget.producto;
    if (producto?.idCategoria != null &&
        producto!.idDepartamento == _idDepartamento &&
        !map.containsKey(producto.idCategoria)) {
      map[producto.idCategoria!] = Categoria(
        idCategoria: producto.idCategoria!,
        idDepartamento: producto.idDepartamento,
        nombre: 'Categoría ${producto.idCategoria}',
        web: false,
      );
    }
    return map.values.toList()..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  int? _departamentoSeleccionado(List<Departamento> deptos) {
    if (_idDepartamento == null) return null;
    return deptos.any((d) => d.idDepartamento == _idDepartamento)
        ? _idDepartamento
        : null;
  }

  int? _categoriaSeleccionada(List<Categoria> cats) {
    if (_idCategoria == null) return null;
    return cats.any((c) => c.idCategoria == _idCategoria) ? _idCategoria : null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idDepartamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un departamento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final precios = _leerPrecios();
    if (precios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese al menos un precio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    final provider = context.read<ProductosProvider>();
    final costo = num.tryParse(_costoCtrl.text.trim().replaceAll(',', '.'));

    String? error;
    if (esEdicion) {
      error = await provider.editarProducto(
        productoOriginal: widget.producto!,
        descripcion: _descripcionCtrl.text,
        codigo: _codigoCtrl.text,
        idDepartamento: _idDepartamento!,
        ipv: _ipv,
        idCategoria: _idCategoria,
        activo: _activo,
        barcode: _barcodeCtrl.text,
        costo: costo,
        combo: _combo,
        web: _web,
        idMonedaCosto: widget.producto!.idMonedaCosto,
        preciosPorMoneda: precios,
      );
    } else {
      error = await provider.crearProducto(
        descripcion: _descripcionCtrl.text,
        codigo: _codigoCtrl.text,
        idDepartamento: _idDepartamento!,
        ipv: _ipv,
        idCategoria: _idCategoria,
        activo: _activo,
        barcode: _barcodeCtrl.text,
        costo: costo,
        combo: _combo,
        web: _web,
        preciosPorMoneda: precios,
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esEdicion ? 'Producto actualizado' : 'Producto creado',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosProvider = context.watch<ProductosProvider>();
    final monedasProvider = context.watch<MonedasProvider>();
    final theme = Theme.of(context);
    final monedas = monedasProvider.monedas;

    if (monedas.isNotEmpty) {
      _inicializarPrecios(monedas);
    }

    final categorias = _categoriasDropdown(productosProvider);
    final departamentos = _departamentosDropdown(productosProvider);
    final idDepartamentoSeleccionado = _departamentoSeleccionado(departamentos);
    final idCategoriaSeleccionada = _categoriaSeleccionada(categorias);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Icon(
                    esEdicion ? Icons.edit_outlined : Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _descripcionCtrl,
                        decoration: _inputDecoration(
                          'Descripción',
                          Icons.inventory_2_outlined,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Campo requerido'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codigoCtrl,
                        decoration: _inputDecoration(
                          'Código',
                          Icons.tag_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeCtrl,
                        decoration: _inputDecoration(
                          'Código de barras',
                          Icons.qr_code,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      if (departamentos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'No hay departamentos disponibles. Sincronice los catálogos primero.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      DropdownButtonFormField<int>(
                        decoration: _inputDecoration(
                          'Departamento',
                          Icons.category_outlined,
                        ),
                        value: idDepartamentoSeleccionado,
                        items:
                            departamentos.map((depto) {
                              return DropdownMenuItem(
                                value: depto.idDepartamento,
                                child: Text(depto.nombre),
                              );
                            }).toList(),
                        onChanged:
                            (value) => setState(() {
                              _idDepartamento = value;
                              if (_idCategoria != null &&
                                  !categorias.any(
                                    (c) => c.idCategoria == _idCategoria,
                                  )) {
                                _idCategoria = null;
                              }
                            }),
                        validator: (v) => v == null ? 'Campo requerido' : null,
                      ),
                      if (categorias.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int?>(
                          decoration: _inputDecoration(
                            'Categoría',
                            Icons.label_outline,
                          ),
                          value: idCategoriaSeleccionada,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Sin categoría'),
                            ),
                            ...categorias.map(
                              (cat) => DropdownMenuItem<int?>(
                                value: cat.idCategoria,
                                child: Text(cat.nombre),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _idCategoria = value),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costoCtrl,
                        decoration: _inputDecoration(
                          'Costo',
                          Icons.attach_money,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Precios', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (monedas.isEmpty)
                        Text(
                          'Cargando monedas...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        )
                      else
                        ...monedas.map((moneda) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _precioCtrls[moneda.idMoneda],
                              decoration: _inputDecoration(
                                'Precio ${moneda.siglas}',
                                Icons.sell_outlined,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.,]'),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Activo'),
                        value: _activo,
                        onChanged: (v) => setState(() => _activo = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('Visible en web'),
                        value: _web,
                        onChanged: (v) => setState(() => _web = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('IPV'),
                        value: _ipv,
                        onChanged: (v) => setState(() => _ipv = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('Combo'),
                        value: _combo,
                        onChanged: (v) => setState(() => _combo = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _guardando
                                      ? null
                                      : () => Navigator.pop(context),
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
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

void mostrarProductoFormDialog(BuildContext context, {Producto? producto}) {
  showDialog(
    context: context,
    builder: (_) => ProductoFormDialog(producto: producto),
  );
}
