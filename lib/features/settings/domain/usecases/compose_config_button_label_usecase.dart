class ConfigButtonLabelResult {
  const ConfigButtonLabelResult({
    required this.showImportLabel,
    this.fileName,
  });

  final bool showImportLabel;
  final String? fileName;
}

class ComposeConfigButtonLabelUseCase {
  ConfigButtonLabelResult call({
    required String wgConfigText,
    required String? configFileName,
  }) {
    if (wgConfigText.trim().isEmpty) {
      return const ConfigButtonLabelResult(showImportLabel: true);
    }
    return ConfigButtonLabelResult(
      showImportLabel: false,
      fileName: (configFileName == null || configFileName.isEmpty)
          ? 'inline'
          : configFileName,
    );
  }
}
