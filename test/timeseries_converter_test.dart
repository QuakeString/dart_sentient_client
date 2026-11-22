import 'package:test/test.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';

void main() {
  group('RestJsonConverter.toTimeseries', () {
    test('parses the stock ThingsBoard shape', () {
      final r = RestJsonConverter.toTimeseries({
        'temp': [
          {'ts': 1, 'value': 21.5}
        ],
        'on': [
          {'ts': 2, 'value': true}
        ],
      });
      expect(r.map((e) => e.getKey()), containsAll(['temp', 'on']));
      expect(r.firstWhere((e) => e.getKey() == 'temp').getValue(), 21.5);
    });

    test('unwraps the SENTIENT {"data": {...}} shape', () {
      final r = RestJsonConverter.toTimeseries({
        'data': {
          'temp': [
            {'ts': 1, 'value': 21.5}
          ],
          'dir': [
            {'ts': 3, 'value': 'up'}
          ],
        }
      });
      expect(r, hasLength(2));
      expect(r.firstWhere((e) => e.getKey() == 'dir').getValue(), 'up');
    });

    test('keeps a real key named "data"', () {
      final r = RestJsonConverter.toTimeseries({
        'data': [
          {'ts': 1, 'value': 7}
        ],
      });
      expect(r.single.getKey(), 'data');
      expect(r.single.getValue(), 7);
    });

    test('empty and null give an empty list', () {
      expect(RestJsonConverter.toTimeseries(null), isEmpty);
      expect(RestJsonConverter.toTimeseries({}), isEmpty);
      expect(RestJsonConverter.toTimeseries({'data': {}}), isEmpty);
    });
  });
}
