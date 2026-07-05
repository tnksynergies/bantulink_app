import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

/// Wrapper cross-platform (mobile + web) pour un fichier a uploader.
/// On stocke les bytes directement, ce qui evite MultipartFile.fromFile
/// qui echoue sur Flutter web (dart:io absent).
class UploadFile {
  const UploadFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  static Future<UploadFile> fromXFile(XFile x) async {
    final bytes = await x.readAsBytes();
    return UploadFile(name: x.name, bytes: bytes);
  }

  /// Necessite `withData: true` cote FilePicker pour que `bytes` soit rempli
  /// sur toutes les plateformes.
  static UploadFile? fromPlatformFile(PlatformFile p) {
    final b = p.bytes;
    if (b == null) return null;
    return UploadFile(name: p.name, bytes: b);
  }

  MultipartFile toMultipart() => MultipartFile.fromBytes(bytes, filename: name);
}
