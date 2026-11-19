import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/calendar/application/mentor_calendar_controller.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_api_paths.dart';
import 'package:rikipath_mobile/features/mentor/data/mentor_schedule_v3_repository.dart';

void main() {
  group('Mentor ScheduleV3 Conflict Preview & Google Calendar', () {
    test(
      'previewTeachingConflicts posts intervals to canonical conflict-preview path and maps conflicts',
      () async {
        late RequestOptions captured;
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              captured = options;
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, Object?>{
                    'isSuccess': true,
                    'result': <String, Object?>{
                      'isValid': false,
                      'conflicts': [
                        <String, Object?>{
                          'code': 'COHORT_SESSION_OVERLAP',
                          'sessionNumber': 2,
                          'proposedStartUtc': '2026-11-25T02:00:00Z',
                          'proposedEndUtc': '2026-11-25T03:30:00Z',
                          'commitmentKind': 'CohortSession',
                          'cohortId': 44,
                          'cohortName': 'JLPT N4 Tối',
                          'message': 'Trùng lịch dạy lớp JLPT N4 Tối',
                        },
                      ],
                    },
                  },
                ),
              );
            },
          ),
        );

        final repo = ApiMentorScheduleV3Repository(
          ApiClient(dio, const ApiErrorMapper()),
        );
        final report = await repo.previewTeachingConflicts(
          intervals: [
            (
              startUtc: DateTime.utc(2026, 11, 25, 2, 0),
              endUtc: DateTime.utc(2026, 11, 25, 3, 30),
            ),
          ],
          excludeCohortId: 12,
        );

        expect(captured.path, MentorApiPaths.scheduleV3ConflictPreview);
        expect(captured.method, 'POST');
        expect(report.isValid, isFalse);
        expect(report.conflicts, hasLength(1));
        expect(report.conflicts.single.code, 'COHORT_SESSION_OVERLAP');
        expect(report.conflicts.single.cohortName, 'JLPT N4 Tối');
      },
    );

    test(
      'MentorGoogleCalendarController fetches status, connects, syncs and disconnects',
      () async {
        final calls = <String>[];
        var connected = false;
        final dio = Dio(BaseOptions(baseUrl: 'https://qa.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add('${options.method} ${options.path}');
              if (options.method == 'GET' &&
                  options.path == MentorApiPaths.mentorCalendar) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{
                        'configured': true,
                        'connected': connected,
                        'lastSyncedAt': '2026-11-18T05:00:00Z',
                      },
                    },
                  ),
                );
                return;
              }
              if (options.method == 'POST' &&
                  options.path == MentorApiPaths.mentorCalendarConnect) {
                connected = true;
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{
                      'isSuccess': true,
                      'result': <String, Object?>{
                        'url': 'https://accounts.google.com/o/oauth2/auth?x=1',
                      },
                    },
                  ),
                );
                return;
              }
              if (options.method == 'POST' &&
                  options.path == MentorApiPaths.mentorCalendarSync) {
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{'isSuccess': true},
                  ),
                );
                return;
              }
              if (options.method == 'DELETE' &&
                  options.path == MentorApiPaths.mentorCalendar) {
                connected = false;
                handler.resolve(
                  Response<Object?>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, Object?>{'isSuccess': true},
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        final container = ProviderContainer(
          overrides: [
            authenticatedUserIdProvider.overrideWithValue(7),
            apiClientProvider.overrideWithValue(
              ApiClient(dio, const ApiErrorMapper()),
            ),
          ],
        );
        addTearDown(container.dispose);
        final keepAlive = container.listen(
          mentorGoogleCalendarControllerProvider,
          (_, _) {},
        );
        addTearDown(keepAlive.close);

        final status0 = await container.read(
          mentorGoogleCalendarControllerProvider.future,
        );
        expect(status0.configured, isTrue);
        expect(status0.connected, isFalse);

        final url = await container
            .read(mentorGoogleCalendarControllerProvider.notifier)
            .connect();
        expect(url, contains('accounts.google.com'));

        await container
            .read(mentorGoogleCalendarControllerProvider.notifier)
            .syncNow();
        await container
            .read(mentorGoogleCalendarControllerProvider.notifier)
            .disconnect();

        expect(calls, contains('POST ${MentorApiPaths.mentorCalendarConnect}'));
        expect(calls, contains('POST ${MentorApiPaths.mentorCalendarSync}'));
        expect(calls, contains('DELETE ${MentorApiPaths.mentorCalendar}'));
      },
    );
  });
}
