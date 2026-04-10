class PickedConfigFile {
  const PickedConfigFile({
    required this.fileName,
    required this.content,
  });

  final String fileName;
  final String content;
}

abstract class FilePickerGateway {
  Future<PickedConfigFile?> pickConfigFile();
  Future<String?> pickCustomArbContent();

  /// Opens the platform save dialog; returns whether the user saved the file.
  Future<bool> saveArbFile(String content, {required String suggestedFileName});
}
