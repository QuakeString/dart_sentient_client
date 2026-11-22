import 'package:test/test.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';

// Frames captured from a SENTIENT server (saf.invenia.in).
void main() {
  group('SubscriptionUpdate.fromJson', () {
    test('reads typed values (numbers, booleans) as text', () {
      final u = SubscriptionUpdate.fromJson({
        'subscriptionId': 1,
        'errorCode': 0,
        'data': {
          'ACTUAL-WEIGHT-VF2': [
            [1795366320555, 0.0]
          ],
          '0m_strap_malfunction': [
            [1795366320555, false]
          ],
        }
      });
      expect(u.data['ACTUAL-WEIGHT-VF2']!.single.value, '0'); // sent as 0.0; shown like REST
      expect(u.data['ACTUAL-WEIGHT-VF2']!.single.ts, 1795366320555);
      expect(u.data['0m_strap_malfunction']!.single.value, 'false');
    });

    test('still reads ThingsBoard string values', () {
      final u = SubscriptionUpdate.fromJson({
        'subscriptionId': 1,
        'errorCode': 0,
        'data': {
          '2_Hz_clock': [
            [1786246611275, 'false']
          ]
        }
      });
      expect(u.data['2_Hz_clock']!.single.value, 'false');
    });

    test('auth reply and subscription ack parse without data', () {
      final auth = SubscriptionUpdate.fromJson({
        'subscriptionId': 0,
        'errorCode': 0,
        'data': {'authSuccess': true, 'userId': 'u', 'tenantId': 't'}
      });
      expect(auth.data, isEmpty);
      final ack = SubscriptionUpdate.fromJson({
        'subscriptionId': 1,
        'errorCode': 0,
        'data': {'cmdId': 1, 'subscriptionId': 1}
      });
      expect(ack.data, isEmpty);
    });
  });

  test('whole doubles read like the REST API, others unchanged', () {
    expect(TsValue.fromJsonList([1, 12.0]).value, '12');
    expect(TsValue.fromJsonList([1, 394459.0]).value, '394459');
    expect(TsValue.fromJsonList([1, 11.858001]).value, '11.858001');
    expect(TsValue.fromJsonList([1, false]).value, 'false');
    expect(TsValue.fromJsonList([1, 7]).value, '7');
    expect(TsValue.fromJson({'ts': 1, 'value': 3.0}).value, '3');
  });
}
