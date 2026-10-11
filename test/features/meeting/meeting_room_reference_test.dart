import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';

void main() {
  const roomId = '5d75c4cc-5404-4f9a-91e8-b8596f31d2a2';

  group('MeetingRoomReference', () {
    test('uses an explicit verified UUID and preserves browser fallback', () {
      final webUri = Uri.parse(
        'https://riki-path-web.vercel.app/mentor-meeting/$roomId',
      );

      final result = MeetingRoomReference.resolve(
        roomId: roomId.toUpperCase(),
        webUri: webUri,
      );

      expect(result?.roomId, roomId);
      expect(result?.webUri, webUri);
    });

    test('extracts roomId from verified Web route path', () {
      final result = MeetingRoomReference.resolve(
        webUri: Uri.parse(
          'https://riki-path-web.vercel.app/meeting-room/$roomId',
        ),
      );

      expect(result?.roomId, roomId);
    });

    test('extracts roomId from the evidenced query contract', () {
      final result = MeetingRoomReference.resolve(
        webUri: Uri.parse(
          'https://riki-path-web.vercel.app/consultation-room?roomId=$roomId',
        ),
      );

      expect(result?.roomId, roomId);
    });

    test('rejects links without an authoritative UUID room identity', () {
      final result = MeetingRoomReference.resolve(
        webUri: Uri.parse(
          'https://riki-path-web.vercel.app/meeting-room/demo-room',
        ),
      );

      expect(result, isNull);
    });

    test('user UUID and trusted URL normalize to the same room', () {
      final fromUuid = MeetingRoomReference.fromUserInput(
        '  ${roomId.toUpperCase()}  ',
      );
      final fromUrl = MeetingRoomReference.fromUserInput(
        'https://riki-path-web.vercel.app/meeting-room/$roomId/',
      );

      expect(fromUuid?.roomId, roomId);
      expect(fromUrl?.roomId, roomId);
      expect(fromUuid?.roomId, fromUrl?.roomId);
      expect(
        fromUuid?.webUri,
        Uri.parse('https://riki-path-web.vercel.app/meeting-room/$roomId'),
      );
    });

    test('user input rejects unsafe, untrusted, and malformed values', () {
      for (final value in <String>[
        'not-a-room',
        'javascript:alert(1)',
        'file:///tmp/$roomId',
        'data:text/plain,$roomId',
        'https://example.com/meeting-room/$roomId',
        'https://riki-path-web.vercel.app/meeting-room/',
        'https://riki-path-web.vercel.app/other/$roomId',
        'https://riki-path-web.vercel.app/meeting-room/$roomId/extra',
        'https://riki-path-web.vercel.app/meeting-room/$roomId?source=test',
      ]) {
        expect(
          MeetingRoomReference.fromUserInput(value),
          isNull,
          reason: value,
        );
      }
    });

    test('consultation meetingLink resolves through the shared room model', () {
      final result = MeetingRoomReference.resolve(
        webUri: Uri.parse(
          'https://riki-path-web.vercel.app/mentor-meeting/$roomId',
        ),
      );

      expect(result?.roomId, roomId);
    });

    test('backend link resolver does not accept UUIDs in arbitrary paths', () {
      final result = MeetingRoomReference.resolve(
        webUri: Uri.parse(
          'https://riki-path-web.vercel.app/arbitrary/path/$roomId',
        ),
      );

      expect(result, isNull);
    });
  });
}
