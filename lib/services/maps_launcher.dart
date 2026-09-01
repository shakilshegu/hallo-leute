import 'package:url_launcher/url_launcher.dart';

/// Opens the platform maps app at a café's location. Uses the Google Maps
/// universal URL (works on Android, iOS and web); `placeId` makes it land on
/// the exact business card when available.
Future<bool> openCafeInMaps({
  required double latitude,
  required double longitude,
  String? name,
  String? placeId,
}) async {
  final query = name != null && name.isNotEmpty
      ? Uri.encodeComponent(name)
      : '$latitude,$longitude';
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1'
    '&query=$query'
    '${placeId != null && placeId.isNotEmpty ? '&query_place_id=$placeId' : ''}',
  );
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
