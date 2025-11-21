import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> savePdf(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$filename';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

