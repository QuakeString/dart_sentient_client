import 'package:test/test.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';

void main() {
  test('reInit moves the WebSocket to the new server too', () async {
    final client = ThingsboardClient('https://old.example');
    final oldWs = client.getTelemetryService();
    expect(client.apiEndpoint, 'https://old.example');

    try {
      await client.reInit('https://new.example');
    } catch (_) {
      // No stored session and no server here: init() may fail; the
      // endpoint switch has happened before it.
    }

    expect(client.apiEndpoint, 'https://new.example');
    expect(identical(client.getTelemetryService(), oldWs), isFalse);
  });

  test('reInit to the same server keeps the WebSocket service', () async {
    final client = ThingsboardClient('https://same.example');
    final ws = client.getTelemetryService();
    try {
      await client.reInit('https://same.example');
    } catch (_) {}
    expect(identical(client.getTelemetryService(), ws), isTrue);
  });
}
