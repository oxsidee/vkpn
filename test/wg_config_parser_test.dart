import 'package:flutter_test/flutter_test.dart';
import 'package:vkpn/domain/wg_config_parser.dart';

void main() {
  const sample = '''
[Interface]
Address = 10.0.0.3/32
PrivateKey = testPrivate
DNS = 1.1.1.1

[Peer]
PublicKey = testPublic
AllowedIPs = 0.0.0.0/0
Endpoint = 194.180.206.205:51820
PersistentKeepalive = 25
''';

  test('parse extracts endpoint and keys', () {
    final parser = WgConfigParser();
    final parsed = parser.parse(sample);
    expect(parsed.interface.privateKey, 'testPrivate');
    expect(parsed.peer.endpointHost, '194.180.206.205');
    expect(parsed.peer.endpointPort, 51820);
  });

  test('rewrite endpoint to local host and port', () {
    final parser = WgConfigParser();
    final rewritten = parser.rewriteEndpoint(sample, host: '127.0.0.1', port: 9000);
    expect(rewritten.contains('Endpoint = 127.0.0.1:9000'), isTrue);
  });

  test('mergeExcludedApplications inserts line in Interface', () {
    final parser = WgConfigParser();
    final out = parser.mergeExcludedApplications(sample, <String>['com.example.app']);
    expect(out.contains('ExcludedApplications = com.example.app'), isTrue);
  });

  test('mergeExcludedApplications merges with existing', () {
    final parser = WgConfigParser();
    const withExcluded = '''
[Interface]
Address = 10.0.0.3/32
PrivateKey = testPrivate
ExcludedApplications = com.old.app

[Peer]
PublicKey = testPublic
AllowedIPs = 0.0.0.0/0
Endpoint = 194.180.206.205:51820
''';
    final out = parser.mergeExcludedApplications(withExcluded, <String>['com.new.app']);
    expect(out.contains('ExcludedApplications = com.old.app, com.new.app'), isTrue);
  });
}
