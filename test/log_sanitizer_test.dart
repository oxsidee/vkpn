import 'package:flutter_test/flutter_test.dart';
import 'package:vkpn/core/common/log_sanitizer.dart';

void main() {
  test('redacts vk-turn command arguments and call URLs', () {
    const line =
        'vk-turn cmd: /tmp/client -peer host:56000 -vk-link https://vk.ru/call/join/abc123?access_token=secret -listen 127.0.0.1:9000 -n 8';

    final sanitized = sanitizeLogLine(line);

    expect(sanitized, contains('-peer [REDACTED]'));
    expect(sanitized, contains('-vk-link [REDACTED]'));
    expect(sanitized, isNot(contains('host:56000')));
    expect(sanitized, isNot(contains('abc123')));
    expect(sanitized, isNot(contains('secret')));
  });

  test('redacts token-bearing assignments from process output', () {
    const line =
        'joinLink=https%3A%2F%2Ftelemost.example&anonymToken=anon123&session_key=session456&client_secret=secret789';

    final sanitized = sanitizeLogLine(line);

    expect(sanitized, contains('joinLink=[REDACTED]'));
    expect(sanitized, contains('anonymToken=[REDACTED]'));
    expect(sanitized, contains('session_key=[REDACTED]'));
    expect(sanitized, contains('client_secret=[REDACTED]'));
    expect(sanitized, isNot(contains('anon123')));
    expect(sanitized, isNot(contains('session456')));
    expect(sanitized, isNot(contains('secret789')));
  });

  test('redacts WireGuard secrets while preserving field names', () {
    const line = 'PrivateKey = abc123\nPresharedKey = def456';

    final sanitized = sanitizeLogLine(line);

    expect(sanitized, contains('PrivateKey = [REDACTED]'));
    expect(sanitized, contains('PresharedKey = [REDACTED]'));
    expect(sanitized, isNot(contains('abc123')));
    expect(sanitized, isNot(contains('def456')));
  });
}
