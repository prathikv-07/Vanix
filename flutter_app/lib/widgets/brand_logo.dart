import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/vanix_theme.dart';

/// The MyBovine wordmark — the same `vanix-logo.svg` the prototype loads from
/// mybovine.ai. prototype.html references it in three places (the splash at
/// 250px wide, and the owner + farmer dashboard headers at 32px tall), so the
/// fetch result is cached statically and shared rather than re-requested per
/// screen.
///
/// Falls back to a styled text wordmark when the SVG can't be fetched (offline,
/// tests, unexpected response), so nothing ever renders blank.
class BrandLogo extends StatefulWidget {
  final double? width;
  final double? height;

  /// Font size for the text fallback. Chosen per call site so the fallback is
  /// roughly the same visual weight as the SVG it stands in for.
  final double fallbackFontSize;

  /// Fallback "My" colour — white over the hero video, ink on a light header.
  final Color? fallbackPrimaryColor;

  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.fallbackFontSize = 19,
    this.fallbackPrimaryColor,
  });

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> {
  static const _url = 'https://mybovine.ai/assets/logos/vanix-logo.svg';

  /// Shared across every BrandLogo instance — fetched at most once per run.
  static String? _cachedSvg;
  static Future<String?>? _inFlight;

  String? _svg;

  @override
  void initState() {
    super.initState();
    _svg = _cachedSvg;
    if (_svg == null) _load();
  }

  Future<void> _load() async {
    _inFlight ??= _fetch();
    final body = await _inFlight;
    if (body != null && mounted) setState(() => _svg = body);
  }

  static Future<String?> _fetch() async {
    try {
      final client = HttpClient();
      final res = await (await client.getUrl(Uri.parse(_url))).close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        client.close();
        // Only accept something that really is SVG — never hand markup we
        // haven't validated to the parser.
        if (body.contains('<svg')) {
          _cachedSvg = body;
          return body;
        }
        return null;
      }
      client.close();
    } catch (_) {
      // Keep the text fallback.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    if (svg != null) return SvgPicture.string(svg, width: widget.width, height: widget.height);

    final primary = widget.fallbackPrimaryColor ?? VanixColors.textPrimary;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'My', style: TextStyle(fontSize: widget.fallbackFontSize, fontWeight: FontWeight.w700, color: primary)),
        TextSpan(text: 'Bovine', style: TextStyle(fontSize: widget.fallbackFontSize, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
      ]),
    );
  }
}
