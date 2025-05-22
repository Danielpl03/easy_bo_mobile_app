enum TipoMensaje { succes, error, loading }

class Mensaje {
  String mensaje = '';
  TipoMensaje tipoMensaje = TipoMensaje.loading;

  Mensaje({this.mensaje = '', this.tipoMensaje = TipoMensaje.loading});
}