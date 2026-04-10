import 'package:equatable/equatable.dart';

class SettingsFormState extends Equatable {
  const SettingsFormState({
    this.vkCallLink = '',
    this.proxyPortText = '56000',
    this.threadsText = '8',
    this.excludedAppPackages = '',
    this.localeCode,
    this.customArbContent,
    this.useUdp = true,
    this.useTurnMode = true,
  });

  final String vkCallLink;
  final String proxyPortText;
  final String threadsText;
  final String excludedAppPackages;
  final String? localeCode;
  final String? customArbContent;
  final bool useUdp;
  final bool useTurnMode;

  SettingsFormState copyWith({
    String? vkCallLink,
    String? proxyPortText,
    String? threadsText,
    String? excludedAppPackages,
    String? localeCode,
    String? customArbContent,
    bool clearCustomArb = false,
    bool? useUdp,
    bool? useTurnMode,
  }) {
    return SettingsFormState(
      vkCallLink: vkCallLink ?? this.vkCallLink,
      proxyPortText: proxyPortText ?? this.proxyPortText,
      threadsText: threadsText ?? this.threadsText,
      excludedAppPackages: excludedAppPackages ?? this.excludedAppPackages,
      localeCode: localeCode ?? this.localeCode,
      customArbContent: clearCustomArb
          ? null
          : (customArbContent ?? this.customArbContent),
      useUdp: useUdp ?? this.useUdp,
      useTurnMode: useTurnMode ?? this.useTurnMode,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    vkCallLink,
    proxyPortText,
    threadsText,
    excludedAppPackages,
    localeCode,
    customArbContent,
    useUdp,
    useTurnMode,
  ];
}
