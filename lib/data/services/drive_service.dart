import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;

import '../../core/constants/app_constants.dart';
import '../models/backup_snapshot.dart';
import '../models/json_response.dart';
import 'auth_service.dart';

/// [DriveService] — wraps the `googleapis` Drive client constrained to the
/// `appDataFolder` scope. Every method returns [JsonResponse] consistent
/// with the rest of the data layer.
class DriveService {
  DriveService({required this.authService});

  final AuthService authService;

  Future<drive.DriveApi?> _api() async {
    final client = await authService.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  Future<JsonResponse> findBackupFileId() async {
    try {
      final api = await _api();
      if (api == null) {
        return JsonResponse.failure(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }
      final result = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '${AppConstants.backupFileName}'",
        $fields: 'files(id, name, modifiedTime)',
      );
      final files = result.files;
      final id = (files == null || files.isEmpty) ? null : files.first.id;
      return JsonResponse.success(message: 'Found', data: id);
    } on drive.DetailedApiRequestError catch (e) {
      return JsonResponse.failure(
        message: 'Drive error: ${e.message ?? e.status}',
        statusCode: e.status ?? 500,
      );
    } catch (e) {
      return JsonResponse.failure(message: 'Drive error: $e');
    }
  }

  Future<JsonResponse> pullBackup(String fileId) async {
    try {
      final api = await _api();
      if (api == null) {
        return JsonResponse.failure(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return JsonResponse.success(
        message: 'Pulled',
        data: BackupSnapshot.fromJson(json),
      );
    } on drive.DetailedApiRequestError catch (e) {
      return JsonResponse.failure(
        message: 'Drive error: ${e.message ?? e.status}',
        statusCode: e.status ?? 500,
      );
    } catch (e) {
      return JsonResponse.failure(message: 'Pull failed: $e');
    }
  }

  Future<JsonResponse> pushBackup(
    BackupSnapshot snapshot, {
    String? existingFileId,
  }) async {
    try {
      final api = await _api();
      if (api == null) {
        return JsonResponse.failure(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }
      final bytes = utf8.encode(jsonEncode(snapshot.toJson()));
      final media = drive.Media(
        Stream<List<int>>.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );
      String id;
      if (existingFileId == null) {
        final created = await api.files.create(
          drive.File()
            ..name = AppConstants.backupFileName
            ..parents = ['appDataFolder'],
          uploadMedia: media,
        );
        id = created.id!;
      } else {
        final updated = await api.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        id = updated.id!;
      }
      return JsonResponse.success(message: 'Pushed', data: id);
    } on drive.DetailedApiRequestError catch (e) {
      return JsonResponse.failure(
        message: 'Drive error: ${e.message ?? e.status}',
        statusCode: e.status ?? 500,
      );
    } catch (e) {
      return JsonResponse.failure(message: 'Push failed: $e');
    }
  }

  Future<JsonResponse> deleteBackup(String fileId) async {
    try {
      final api = await _api();
      if (api == null) {
        return JsonResponse.failure(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }
      await api.files.delete(fileId);
      return JsonResponse.success(message: 'Deleted');
    } on drive.DetailedApiRequestError catch (e) {
      return JsonResponse.failure(
        message: 'Drive error: ${e.message ?? e.status}',
        statusCode: e.status ?? 500,
      );
    } catch (e) {
      return JsonResponse.failure(message: 'Delete failed: $e');
    }
  }
}
