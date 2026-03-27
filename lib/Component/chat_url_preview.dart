import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Metadata lấy từ URL (Open Graph / HTML meta)
class UrlMetadata {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? favicon;

  const UrlMetadata({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.favicon,
  });

  bool get hasPreview =>
      title != null || description != null || imageUrl != null;

  @override
  String toString() =>
      'UrlMetadata(url: $url, title: $title, image: $imageUrl)';
}

/// Fetch Open Graph metadata từ URL
class UrlMetadataFetcher {
  static final _cache = <String, UrlMetadata>{};

  /// Kiểm tra text có phải URL không
  static bool isUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.contains(' ') && !trimmed.startsWith('http')) return false;

    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('www.') ||
        RegExp(
          r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}([\/?#][^\s]*)?$',
          caseSensitive: false,
        ).hasMatch(trimmed);
  }

  /// Tìm URL đầu tiên trong text
  static String? extractFirstUrl(String text) {
    final regex = RegExp(
      r'(https?://[^\s]+)|(www\.[^\s]+)|((?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:[/?#][^\s]*)?)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);
    if (match == null) return null;

    var url = match.group(0)!.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  /// Chuẩn hoá URL
  static String normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  /// Fetch metadata từ URL
  static Future<UrlMetadata> fetch(String rawUrl) async {
    final url = normalizeUrl(rawUrl);

    // Check cache
    if (_cache.containsKey(url)) return _cache[url]!;

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (compatible; ChatApp/1.0; +https://cybersoft.com.vn)',
              'Accept': 'text/html,application/xhtml+xml',
              'Accept-Language': 'vi,en;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return UrlMetadata(url: url);
      }

      // Xử lý encoding
      String html;
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('charset=utf-8') ||
          contentType.contains('charset=UTF-8')) {
        html = utf8.decode(response.bodyBytes, allowMalformed: true);
      } else {
        html = response.body;
      }

      final metadata = _parseHtml(html, url);
      _cache[url] = metadata;
      return metadata;
    } catch (_) {
      // Fallback: trả về metadata cơ bản từ URL
      final uri = Uri.tryParse(url);
      final fallback = UrlMetadata(url: url, siteName: uri?.host);
      _cache[url] = fallback;
      return fallback;
    }
  }

  /// Parse HTML để lấy Open Graph / meta tags
  static UrlMetadata _parseHtml(String html, String url) {
    final uri = Uri.tryParse(url);

    // ── Open Graph tags ──
    String? ogTitle = _getMetaContent(html, 'og:title');
    String? ogDesc = _getMetaContent(html, 'og:description');
    String? ogImage = _getMetaContent(html, 'og:image');
    String? ogSiteName = _getMetaContent(html, 'og:site_name');

    // ── Twitter Card fallback ──
    ogTitle ??= _getMetaContent(html, 'twitter:title');
    ogDesc ??= _getMetaContent(html, 'twitter:description');
    ogImage ??= _getMetaContent(html, 'twitter:image');

    // ── Standard meta fallback ──
    ogTitle ??= _getMetaByName(html, 'title') ?? _getTitleTag(html);
    ogDesc ??= _getMetaByName(html, 'description');

    // ── Favicon ──
    String? favicon = _getFavicon(html, url);

    // ── Chuẩn hoá image URL ──
    if (ogImage != null && !ogImage.startsWith('http')) {
      if (ogImage.startsWith('//')) {
        ogImage = 'https:$ogImage';
      } else if (ogImage.startsWith('/') && uri != null) {
        ogImage = '${uri.scheme}://${uri.host}$ogImage';
      }
    }

    return UrlMetadata(
      url: url,
      title: ogTitle?.trim(),
      description: ogDesc?.trim(),
      imageUrl: ogImage,
      siteName: ogSiteName ?? uri?.host,
      favicon: favicon,
    );
  }

  /// Lấy content từ <meta property="..." content="...">
  static String? _getMetaContent(String html, String property) {
    // property="og:title" content="..."
    final reg1 = RegExp(
      '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final m1 = reg1.firstMatch(html);
    if (m1 != null) return _decodeHtmlEntities(m1.group(1)!);

    // content="..." property="og:title"
    final reg2 = RegExp(
      '<meta[^>]+content=["\']([^"\']*)["\'][^>]+property=["\']$property["\']',
      caseSensitive: false,
    );
    final m2 = reg2.firstMatch(html);
    if (m2 != null) return _decodeHtmlEntities(m2.group(1)!);

    return null;
  }

  /// Lấy content từ <meta name="..." content="...">
  static String? _getMetaByName(String html, String name) {
    final reg1 = RegExp(
      '<meta[^>]+name=["\']$name["\'][^>]+content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final m1 = reg1.firstMatch(html);
    if (m1 != null) return _decodeHtmlEntities(m1.group(1)!);

    final reg2 = RegExp(
      '<meta[^>]+content=["\']([^"\']*)["\'][^>]+name=["\']$name["\']',
      caseSensitive: false,
    );
    final m2 = reg2.firstMatch(html);
    if (m2 != null) return _decodeHtmlEntities(m2.group(1)!);

    return null;
  }

  /// Lấy <title>...</title>
  static String? _getTitleTag(String html) {
    final reg = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    );
    final m = reg.firstMatch(html);
    if (m != null) {
      final raw = m.group(1)!.trim();
      return raw.isEmpty ? null : _decodeHtmlEntities(raw);
    }
    return null;
  }

  /// Lấy favicon
  static String? _getFavicon(String html, String url) {
    final reg = RegExp(
      '<link[^>]+rel=["\'](?:icon|shortcut icon)["\'][^>]+href=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    final m = reg.firstMatch(html);
    if (m != null) {
      var href = m.group(1)!;
      if (href.startsWith('//')) return 'https:$href';
      if (href.startsWith('/')) {
        final uri = Uri.tryParse(url);
        if (uri != null) return '${uri.scheme}://${uri.host}$href';
      }
      if (href.startsWith('http')) return href;
    }

    // Default favicon
    final uri = Uri.tryParse(url);
    if (uri != null) return '${uri.scheme}://${uri.host}/favicon.ico';
    return null;
  }

  /// Decode HTML entities cơ bản
  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/')
        .replaceAll('&nbsp;', ' ');
  }

  /// Xoá cache
  static void clearCache() => _cache.clear();
}
