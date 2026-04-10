import 'dart:convert' show utf8;
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_selector/file_selector.dart' as file_selector;

import '../domain/contracts/file_picker_gateway.dart';

class FilePickerGatewayImpl implements FilePickerGateway {
  static Future<String?> _readPlatformFileText(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!, allowMalformed: true);
    }
    final String? path = file.path;
    if (!kIsWeb && path != null && path.isNotEmpty) {
      try {
        return await File(path).readAsString();
      } on Object {
        return null;
      }
    }
    return null;
  }

  static const file_selector.XTypeGroup _macOsConfigTypeGroup =
      file_selector.XTypeGroup(
        label: 'WireGuard config',
        extensions: <String>['conf', 'txt'],
        uniformTypeIdentifiers: <String>['public.text'],
      );

  static const file_selector.XTypeGroup _macOsArbTypeGroup =
      file_selector.XTypeGroup(
        label: 'ARB',
        extensions: <String>['arb'],
        uniformTypeIdentifiers: <String>['public.text'],
      );

  @override
  Future<PickedConfigFile?> pickConfigFile() async {
    if (Platform.isMacOS) {
      final file = await file_selector.openFile(
        acceptedTypeGroups: const <file_selector.XTypeGroup>[_macOsConfigTypeGroup],
        confirmButtonText: 'Import',
      );
      if (file == null) {
        return null;
      }
      final text = await file.readAsString();
      return PickedConfigFile(fileName: file.name, content: text);
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const <String>['conf', 'txt'],
    );
    final PlatformFile? file =
        (result == null || result.files.isEmpty) ? null : result.files.first;
    if (file == null) {
      return null;
    }
    final String? text = await _readPlatformFileText(file);
    if (text == null) {
      return null;
    }
    return PickedConfigFile(fileName: file.name, content: text);
  }

  @override
  Future<String?> pickCustomArbContent() async {
    if (Platform.isMacOS) {
      final file = await file_selector.openFile(
        acceptedTypeGroups: const <file_selector.XTypeGroup>[_macOsArbTypeGroup],
        confirmButtonText: 'Open',
      );
      if (file == null) {
        return null;
      }
      return file.readAsString();
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const <String>['arb'],
    );
    final PlatformFile? file =
        (result == null || result.files.isEmpty) ? null : result.files.first;
    if (file == null) {
      return null;
    }
    return _readPlatformFileText(file);
  }

  @override
  Future<bool> saveArbFile(
    String content, {
    required String suggestedFileName,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    if (Platform.isMacOS) {
      final savePath = await file_selector.getSaveLocation(
        suggestedName: suggestedFileName,
        acceptedTypeGroups: const <file_selector.XTypeGroup>[_macOsArbTypeGroup],
      );
      if (savePath == null) {
        return false;
      }
      final file = file_selector.XFile.fromData(
        bytes,
        name: savePath.path.split('/').last,
      );
      await file.saveTo(savePath.path);
      return true;
    }
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save .arb',
      fileName: suggestedFileName,
      type: FileType.custom,
      allowedExtensions: const <String>['arb'],
      bytes: bytes,
    );
    return path != null;
  }
}
