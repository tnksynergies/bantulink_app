import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';

class ProfileFile {
  const ProfileFile(this.bytes, this.name);
  final Uint8List bytes;
  final String name;
}

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  /// Cree (POST) ou met a jour (POST + _method=PUT) le profil particulier.
  /// Multipart : fonctionne aussi sur le web (bytes, pas de chemin disque).
  Future<void> saveParticulier({
    required Map<String, dynamic> fields,
    required bool isUpdate,
    ProfileFile? image,
    ProfileFile? cv,
    ProfileFile? lettre,
  }) async {
    Future<FormData> build(bool update) async {
      final map = <String, dynamic>{...fields};
      map['is_visible'] =
          (fields['is_visible'] == true || fields['is_visible'] == 1) ? 1 : 0;
      if (update) map['_method'] = 'PUT';
      final fd = FormData.fromMap(map);
      if (image != null) {
        fd.files.add(MapEntry('image_profil_file',
            MultipartFile.fromBytes(image.bytes, filename: image.name)));
      }
      if (cv != null) {
        fd.files.add(MapEntry(
            'cv_file', MultipartFile.fromBytes(cv.bytes, filename: cv.name)));
      }
      if (lettre != null) {
        fd.files.add(MapEntry('lettre_motivation_file',
            MultipartFile.fromBytes(lettre.bytes, filename: lettre.name)));
      }
      return fd;
    }

    try {
      await _dio.post('/profile/particulier', data: await build(isUpdate));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // Filets de securite si l'etat du profil etait mal detecte
      if (!isUpdate && code == 409) {
        await _dio.post('/profile/particulier', data: await build(true));
        return;
      }
      if (isUpdate && code == 404) {
        await _dio.post('/profile/particulier', data: await build(false));
        return;
      }
      throw ApiException.fromDio(e);
    }
  }
}
