import 'package:flutter_test/flutter_test.dart';
import 'package:vkpn/core/platform/windows_wg_host_route_bypass.dart';

void main() {
  test('parseWindowsExcludedRouteTokens keeps hostnames and IPv4', () {
    expect(
      parseWindowsExcludedRouteTokens('8.8.8.8, api.steampowered.com'),
      <String>['8.8.8.8', 'api.steampowered.com'],
    );
  });

  test('parseWindowsExcludedRouteTokens skips Android package ids', () {
    expect(
      parseWindowsExcludedRouteTokens('com.discord\n1.2.3.4'),
      <String>['1.2.3.4'],
    );
  });

  test('parseWindowsExcludedRouteTokens skips paths and exe', () {
    expect(
      parseWindowsExcludedRouteTokens(r'C:\foo\bar.exe, example.org'),
      <String>['example.org'],
    );
  });
}
