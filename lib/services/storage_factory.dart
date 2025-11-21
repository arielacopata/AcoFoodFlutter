import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'storage_service.dart';
import 'sqlite_storage_service.dart';
import 'firestore_storage_service.dart';

class StorageFactory {
  static StorageService? _instance;

  static StorageService get instance {
    if (_instance == null) {
      if (kIsWeb) {
        print('🌐 Usando FirestoreStorageService'); // Debug
        _instance = FirestoreStorageService();
      } else {
        print('📱 Usando SQLiteStorageService'); // Debug
        _instance = SQLiteStorageService();
      }
    }
    return _instance!;
  }

  // Para testing: permite cambiar la implementación
  static void setInstance(StorageService service) {
    _instance = service;
  }
}
