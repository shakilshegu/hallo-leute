import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/state/cafe_controller.dart';

const _fallbackBg = Color(0xFFE2E8DF);
const _ink = Color(0xFF2B4739);

/// A café photo loaded through the backend proxy (`/api/v1/cafes/photo`),
/// which needs the Firebase Bearer header. Falls back to a coffee icon when
/// there's no photo or it fails to load.
class CafePhoto extends ConsumerWidget {
  const CafePhoto({
    super.key,
    required this.proxyPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// The `photoUrl` from a café response, e.g. `/api/v1/cafes/photo?ref=...`.
  final String? proxyPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    Widget child;

    final path = proxyPath;
    if (path == null || path.isEmpty) {
      child = _fallback();
    } else {
      final api = ref.read(cafeApiProvider);
      final headers = ref.watch(cafeImageHeadersProvider).valueOrNull;
      child = Image.network(
        api.cafePhotoUrl(path),
        width: width,
        height: height,
        fit: fit,
        headers: headers,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (ctx, w, progress) => progress == null ? w : _loading(),
      );
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: _fallbackBg,
        alignment: Alignment.center,
        child: const Icon(Icons.local_cafe, color: _ink),
      );

  Widget _loading() => Container(
        width: width,
        height: height,
        color: _fallbackBg,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
        ),
      );
}
