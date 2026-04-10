import 'package:flutter_test/flutter_test.dart';
import 'package:vkpn/features/home/domain/entities/home_error_code.dart';
import 'package:vkpn/features/home/domain/usecases/map_home_error_message_usecase.dart';
import 'package:vkpn/features/settings/domain/usecases/compose_config_button_label_usecase.dart';

void main() {
  test('maps home error codes to l10n keys', () {
    final usecase = MapHomeErrorMessageUseCase();
    expect(usecase(HomeErrorCode.wgConfigRequired), 'wgConfigRequired');
    expect(usecase(HomeErrorCode.vpnPermissionRequired), 'vpnPermissionRequired');
  });

  test('composes config button label state', () {
    final usecase = ComposeConfigButtonLabelUseCase();
    final empty = usecase(wgConfigText: '   ', configFileName: null);
    expect(empty.showImportLabel, isTrue);
    final loaded = usecase(wgConfigText: '[Interface]', configFileName: 'vpn.conf');
    expect(loaded.showImportLabel, isFalse);
    expect(loaded.fileName, 'vpn.conf');
  });
}
