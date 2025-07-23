import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

Future<String> enregistrerFichierUniversel({
  required Uint8List bytes,
  required String nomFichier,
}) async {
  Directory? directory;

  if (kIsWeb) {
    throw UnsupportedError("Non supporté sur le web.");
  }

  if (Platform.isAndroid) {
    // Demande permission de stockage
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      throw Exception("Permission refusée pour écrire dans le stockage.");
    }

    // Utilise le répertoire externe privé de l'app
    directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("Impossible d'accéder au répertoire externe.");
    }

    final customDir = Directory('${directory.path}/FlutterDocs');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    final filePath = '${customDir.path}/$nomFichier';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  // iOS ou autres
  directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$nomFichier';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}
