import 'dart:async';
import 'dart:io';

/// Flutter's test binding blocks real HTTP (every request comes back 400),
/// which makes any `Image.network` in the widget tree throw. The app's
/// screens use real network images throughout (a pre-existing UI pattern,
/// not something router/guard tests should have to work around one screen
/// at a time), so tests that pump full screens install this instead: an
/// [HttpOverrides] that serves a fixed 1x1 transparent PNG for every
/// request, so image widgets resolve instead of erroring.
class MockNetworkImagesHttpOverrides extends HttpOverrides {
  // Minimal valid 1x1 transparent PNG.
  static final List<int> _onePixelPng = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  // Swallow every other HttpClient/-Request/-Response member (headers,
  // autoUncompress, etc.) instead of throwing — this mock only needs to
  // satisfy the subset NetworkImage actually calls.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  // Swallow every other HttpClient/-Request/-Response member (headers,
  // autoUncompress, etc.) instead of throwing — this mock only needs to
  // satisfy the subset NetworkImage actually calls.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => MockNetworkImagesHttpOverrides._onePixelPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([
      MockNetworkImagesHttpOverrides._onePixelPng,
    ]).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  // Swallow every other HttpClient/-Request/-Response member (headers,
  // autoUncompress, etc.) instead of throwing — this mock only needs to
  // satisfy the subset NetworkImage actually calls.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
