import 'package:flutter_test/flutter_test.dart';
import 'package:jepo/models/incident_alert.dart';

void main() {
  group('IncidentAlert', () {
    test('fromJson parses complete alert', () {
      final json = <String, dynamic>{
        'id': 1,
        'id_usuario': 42,
        'latitud': 10.12345678,
        'longitud': -70.98765432,
        'url_audio_contexto': 'https://example.com/audio.mp3',
        'fecha_hora': '2026-04-26T10:00:00.000Z',
        'es_proactiva': true,
      };

      final alert = IncidentAlert.fromJson(json);

      expect(alert.id, 1);
      expect(alert.idUsuario, 42);
      expect(alert.latitud, closeTo(10.12345678, 0.000000001));
      expect(alert.longitud, closeTo(-70.98765432, 0.000000001));
      expect(alert.urlAudioContexto, 'https://example.com/audio.mp3');
      expect(alert.esProactiva, isTrue);
      expect(alert.fechaHora, isNotNull);
      expect(alert.fechaHora!.isUtc, isTrue);
    });

    test('fromJson handles null/missing fields', () {
      final json = <String, dynamic>{
        'latitud': 0.0,
        'longitud': 0.0,
      };

      final alert = IncidentAlert.fromJson(json);

      expect(alert.id, isNull);
      expect(alert.idUsuario, isNull);
      expect(alert.esProactiva, isFalse);
    });

    test('toJson round-trips correctly', () {
      final alert = IncidentAlert(
        id: 5,
        idUsuario: 10,
        latitud: 10.12345678,
        longitud: -70.98765432,
        urlAudioContexto: null,
        fechaHora: DateTime.utc(2026, 4, 26, 10, 0),
        esProactiva: true,
      );

      final json = alert.toJson();
      expect(json['id'], 5);
      expect(json['id_usuario'], 10);
      expect(json['es_proactiva'], true);
      expect(json['latitud'], closeTo(10.12345678, 0.000000001));
    });
  });

  group('CreateIncidentAlertDto', () {
    test('toJson includes clientEventId when set', () {
      final dto = CreateIncidentAlertDto(
        latitud: 10.5,
        longitud: -70.5,
        urlAudioContexto: null,
        fechaHora: DateTime.utc(2026, 4, 26),
        esProactiva: true,
        clientEventId: 'test-event-123',
      );

      final json = dto.toJson();
      expect(json['client_event_id'], 'test-event-123');
      expect(json['es_proactiva'], true);
    });

    test('toJson omits clientEventId when null', () {
      final dto = CreateIncidentAlertDto(
        latitud: 10.5,
        longitud: -70.5,
        urlAudioContexto: null,
        fechaHora: DateTime.utc(2026, 4, 26),
        esProactiva: false,
      );

      final json = dto.toJson();
      expect(json.containsKey('client_event_id'), isFalse);
    });

    test('toJson omits empty urlAudioContexto', () {
      final dto = CreateIncidentAlertDto(
        latitud: 10.5,
        longitud: -70.5,
        urlAudioContexto: '',
        fechaHora: DateTime.utc(2026, 4, 26),
        esProactiva: false,
      );

      final json = dto.toJson();
      expect(json.containsKey('url_audio_contexto'), isFalse);
    });

    test('normalizes coordinates to 8 decimals', () {
      final dto = CreateIncidentAlertDto(
        latitud: 10.123456789123,
        longitud: -70.987654321987,
        urlAudioContexto: null,
        fechaHora: DateTime.utc(2026, 4, 26),
        esProactiva: true,
      );

      final json = dto.toJson();
      // Should be truncated to 8 decimals
      final lat = json['latitud'] as double;
      final lng = json['longitud'] as double;
      expect(lat.toStringAsFixed(8), '10.12345679');
      expect(lng.toStringAsFixed(8), '-70.98765432');
    });

    test('fromJson round-trips preserving clientEventId', () {
      final original = CreateIncidentAlertDto(
        latitud: 10.5,
        longitud: -70.5,
        urlAudioContexto: 'https://ex.com',
        fechaHora: DateTime.utc(2026, 4, 26, 10),
        esProactiva: true,
        clientEventId: 'abc-123',
      );

      final json = original.toJson();
      final restored = CreateIncidentAlertDto.fromJson(json);

      expect(restored.clientEventId, 'abc-123');
      expect(restored.esProactiva, true);
      expect(restored.latitud, closeTo(10.5, 0.000000001));
    });
  });

  group('UpdateIncidentAlertDto', () {
    test('toJson only includes set fields', () {
      final dto = UpdateIncidentAlertDto(
        latitud: 10.5,
        esProactiva: false,
      );

      final json = dto.toJson();
      expect(json.containsKey('latitud'), isTrue);
      expect(json.containsKey('es_proactiva'), isTrue);
      expect(json.containsKey('longitud'), isFalse);
      expect(json.containsKey('fecha_hora'), isFalse);
    });

    test('toJson is empty when all fields are null', () {
      const dto = UpdateIncidentAlertDto();
      final json = dto.toJson();
      expect(json, isEmpty);
    });
  });

  group('IncidentAlertCreateResult', () {
    test('fromJson parses complete result with contacts', () {
      final json = <String, dynamic>{
        'alerta': {
          'id': 1,
          'id_usuario': 42,
          'latitud': 10.5,
          'longitud': -70.5,
          'fecha_hora': '2026-04-26T10:00:00.000Z',
          'es_proactiva': true,
        },
        'contactosNotificar': [
          {
            'id': 1,
            'id_usuario': 42,
            'nombre_contacto': 'Mom',
            'telefono_contacto': '584144019911',
            'prioridad': 1,
          },
        ],
        'notificaciones': {'sms': 1, 'push': 0},
      };

      final result = IncidentAlertCreateResult.fromJson(json);

      expect(result.alerta, isNotNull);
      expect(result.alerta!.id, 1);
      expect(result.contactosNotificar, hasLength(1));
      expect(result.contactosNotificar[0].nombreContacto, 'Mom');
    });

    test('handles empty contacts list', () {
      final json = <String, dynamic>{
        'alerta': null,
        'contactosNotificar': <dynamic>[],
      };

      final result = IncidentAlertCreateResult.fromJson(json);
      expect(result.alerta, isNull);
      expect(result.contactosNotificar, isEmpty);
    });
  });
}
