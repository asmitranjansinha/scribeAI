import 'package:ai_note_taker/models/calendar_event.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

class CalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'https://www.googleapis.com/auth/calendar'],
  );

  Future<List<CalendarEvent>> getGoogleCalendarEvents(
    DateTime start,
    DateTime end,
  ) async {
    try {
      print('Starting Google Sign-In process...');

      // Check if user is already signed in
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      print('Current user: ${currentUser?.email}');

      // If not signed in, attempt to sign in
      if (currentUser == null) {
        print('No current user, attempting sign in...');
        currentUser = await _googleSignIn.signIn();
        if (currentUser == null) {
          throw Exception('User cancelled sign-in or sign-in failed');
        }
        print('Sign-in successful: ${currentUser.email}');
      }

      // Get authentication
      print('Getting authentication...');
      final GoogleSignInAuthentication googleAuth =
          await currentUser.authentication;

      if (googleAuth.accessToken == null) {
        throw Exception('Failed to get access token');
      }

      print('Authentication successful, creating API client...');

      // Create authenticated client
      final authHeaders = {
        'Authorization': 'Bearer ${googleAuth.accessToken}',
        'Content-Type': 'application/json',
      };

      final authenticatedClient = GoogleAuthClient(authHeaders);
      final calendarApi = calendar.CalendarApi(authenticatedClient);

      print('Fetching calendar events...');

      // Fetch events
      final events = await calendarApi.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 50,
      );

      print('Found ${events.items?.length ?? 0} events');

      return events.items?.map((googleEvent) {
            return CalendarEvent(
              id: googleEvent.id ?? '',
              title: googleEvent.summary ?? 'No Title',
              description: googleEvent.description ?? '',
              start: googleEvent.start?.dateTime ?? googleEvent.start?.date,
              end: googleEvent.end?.dateTime ?? googleEvent.end?.date,
              isAllDay: googleEvent.start?.date != null,
              location: googleEvent.location ?? '',
            );
          }).toList() ??
          [];
    } on PlatformException catch (e) {
      print('Platform exception: ${e.code} - ${e.message} - ${e.details}');

      String errorMessage;
      switch (e.code) {
        case 'sign_in_failed':
          errorMessage =
              'Google Sign-In failed. Please check your Google Cloud Console configuration:\n'
              '1. Ensure Google Calendar API is enabled\n'
              '2. Verify OAuth 2.0 client is configured with correct SHA-1 fingerprint\n'
              '3. Check that package name matches your app';
          break;
        case 'network_error':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        case 'sign_in_canceled':
          errorMessage = 'Sign-in was cancelled by user.';
          break;
        default:
          errorMessage = 'Sign-in error: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('General error: $e');

      if (e.toString().contains('ApiException: 10')) {
        throw Exception(
          'Google configuration error (DEVELOPER_ERROR).\n\n'
          'Please ensure:\n'
          '1. Google Calendar API is enabled in Google Cloud Console\n'
          '2. OAuth 2.0 client ID is configured for Android\n'
          '3. SHA-1 fingerprint is added to the OAuth client\n'
          '4. Package name matches exactly\n\n'
          'Run this command to get your SHA-1:\n'
          'keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android',
        );
      }

      rethrow;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
