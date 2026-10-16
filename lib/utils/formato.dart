import 'package:intl/intl.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
final _kg = NumberFormat('#,##0.##', 'es_MX');

String moneda(num valor) => _moneda.format(valor);

String kilos(num kg) => '${_kg.format(kg)} kg';

/// Folio con formato #025.
String folio(int numero) => '#${numero.toString().padLeft(3, '0')}';

String _capitalizar(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

String fechaLarga(DateTime f) => _capitalizar(DateFormat("EEEE d 'de' MMMM", 'es_MX').format(f));

String fechaCorta(DateTime f) => DateFormat('d MMM yyyy', 'es_MX').format(f);

String fechaHora(DateTime f) => DateFormat("d MMM, HH:mm", 'es_MX').format(f);

String diaSemanaCorto(DateTime f) => _capitalizar(DateFormat('EEE', 'es_MX').format(f)).replaceAll('.', '');

String mesCorto(DateTime f) => _capitalizar(DateFormat('MMM', 'es_MX').format(f)).replaceAll('.', '');
