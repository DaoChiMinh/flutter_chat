import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════
// URL Type Detection
// ═══════════════════════════════════════════════════════════

enum UrlContentType { image, video, web }

class UrlTypeResult {
  final String url;
  final UrlContentType type;
  final String? extension; // jpg, mp4, ...

  const UrlTypeResult({required this.url, required this.type, this.extension});
}

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

/// Fetch Open Graph metadata + nhận dạng kiểu URL
class UrlMetadataFetcher {
  static final _metaCache = <String, UrlMetadata>{};
  static final _typeCache = <String, UrlTypeResult>{};

  // ── Extension lists ──
  static const _imageExts = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
    'ico',
    'tiff',
    'tif',
  ];
  static const _videoExts = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    '3gp',
    'flv',
    'wmv',
    'm4v',
  ];
  
  // ═══════════════════════════════════════════════════════
  // ★ Nhận dạng URL → image / video / web
  // ═══════════════════════════════════════════════════════

  /// Nhận dạng nhanh bằng extension (không cần request)
  static UrlTypeResult detectByExtension(String rawUrl) {
    final url = normalizeUrl(rawUrl);
    final ext = _extractExtension(url);

    if (ext != null) {
      if (_imageExts.contains(ext)) {
        return UrlTypeResult(
          url: url,
          type: UrlContentType.image,
          extension: ext,
        );
      }
      if (_videoExts.contains(ext)) {
        return UrlTypeResult(
          url: url,
          type: UrlContentType.video,
          extension: ext,
        );
      }
    }

    return UrlTypeResult(url: url, type: UrlContentType.web);
  }

  /// Nhận dạng đầy đủ: extension + HEAD request (Content-Type)
  static Future<UrlTypeResult> detectType(String rawUrl) async {
    final url = normalizeUrl(rawUrl);

    // Cache
    if (_typeCache.containsKey(url)) return _typeCache[url]!;

    // ── Bước 1: Kiểm tra extension ──
    final byExt = detectByExtension(url);
    if (byExt.type != UrlContentType.web) {
      _typeCache[url] = byExt;
      return byExt;
    }

    // ── Bước 2: HEAD request để kiểm tra Content-Type ──
    try {
      final response = await http
          .head(
            Uri.parse(url),
            headers: {'User-Agent': 'Mozilla/5.0 (compatible; ChatApp/1.0)'},
          )
          .timeout(const Duration(seconds: 5));

      final contentType = (response.headers['content-type'] ?? '')
          .toLowerCase();

      if (contentType.startsWith('image/')) {
        final ext = _contentTypeToExt(contentType, _imageExts) ?? 'jpg';
        final result = UrlTypeResult(
          url: url,
          type: UrlContentType.image,
          extension: ext,
        );
        _typeCache[url] = result;
        return result;
      }

      if (contentType.startsWith('video/')) {
        final ext = _contentTypeToExt(contentType, _videoExts) ?? 'mp4';
        final result = UrlTypeResult(
          url: url,
          type: UrlContentType.video,
          extension: ext,
        );
        _typeCache[url] = result;
        return result;
      }
    } catch (_) {
      // HEAD thất bại → mặc định web
    }

    final result = UrlTypeResult(url: url, type: UrlContentType.web);
    _typeCache[url] = result;
    return result;
  }

  /// Lấy extension từ URL path (bỏ query string)
  static String? _extractExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.isEmpty || !path.contains('.')) return null;
      final ext = path.split('.').last.toLowerCase();
      // Chỉ chấp nhận extension ngắn hợp lệ
      if (ext.length > 5 || ext.contains('/')) return null;
      return ext;
    } catch (_) {
      return null;
    }
  }

  /// Chuyển content-type → extension
  static String? _contentTypeToExt(String contentType, List<String> validExts) {
    // "image/jpeg" → "jpeg", "video/mp4" → "mp4"
    final parts = contentType.split(';').first.trim().split('/');
    if (parts.length < 2) return null;
    final sub = parts[1].trim();
    if (sub == 'jpeg') return 'jpg';
    if (validExts.contains(sub)) return sub;
    return null;
  }

  // ═══════════════════════════════════════════════════════
  // URL Detection trong text
  // ═══════════════════════════════════════════════════════

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

  /// Tìm tất cả URL trong text
  static List<String> extractAllUrls(String text) {
    final regex = RegExp(
      r'(https?://[^\s]+)|(www\.[^\s]+)|((?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:[/?#][^\s]*)?)',
      caseSensitive: false,
    );

    return regex
        .allMatches(text)
        .map((m) {
          var url = m.group(0)!.trim();
          // Xoá dấu câu cuối (, . ; : ! ?)
          while (url.isNotEmpty && '.;:!?,)'.contains(url[url.length - 1])) {
            url = url.substring(0, url.length - 1);
          }
          return normalizeUrl(url);
        })
        .toSet() // loại trùng
        .toList();
  }

  /// Tìm URL đầu tiên trong text
  static String? extractFirstUrl(String text) {
    final urls = extractAllUrls(text);
    return urls.isEmpty ? null : urls.first;
  }

  /// Chuẩn hoá URL
  static String normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  // ═══════════════════════════════════════════════════════
  // Fetch Metadata (cho URL web)
  // ═══════════════════════════════════════════════════════

  static Future<UrlMetadata> fetch(String rawUrl) async {
    final url = normalizeUrl(rawUrl);

    if (_metaCache.containsKey(url)) return _metaCache[url]!;

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

      String html;
      final ct = response.headers['content-type'] ?? '';
      if (ct.contains('charset=utf-8') || ct.contains('charset=UTF-8')) {
        html = utf8.decode(response.bodyBytes, allowMalformed: true);
      } else {
        html = response.body;
      }

      final metadata = _parseHtml(html, url);
      _metaCache[url] = metadata;
      return metadata;
    } catch (_) {
      final uri = Uri.tryParse(url);
      final fallback = UrlMetadata(url: url, siteName: uri?.host);
      _metaCache[url] = fallback;
      return fallback;
    }
  }

  static UrlMetadata _parseHtml(String html, String url) {
    final uri = Uri.tryParse(url);

    String? ogTitle = _getMetaContent(html, 'og:title');
    String? ogDesc = _getMetaContent(html, 'og:description');
    String? ogImage = _getMetaContent(html, 'og:image');
    String? ogSiteName = _getMetaContent(html, 'og:site_name');

    ogTitle ??= _getMetaContent(html, 'twitter:title');
    ogDesc ??= _getMetaContent(html, 'twitter:description');
    ogImage ??= _getMetaContent(html, 'twitter:image');

    ogTitle ??= _getMetaByName(html, 'title') ?? _getTitleTag(html);
    ogDesc ??= _getMetaByName(html, 'description');

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
    );
  }

  static String? _getMetaContent(String html, String property) {
    final reg1 = RegExp(
      '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final m1 = reg1.firstMatch(html);
    if (m1 != null) return _decodeHtmlEntities(m1.group(1)!);

    final reg2 = RegExp(
      '<meta[^>]+content=["\']([^"\']*)["\'][^>]+property=["\']$property["\']',
      caseSensitive: false,
    );
    final m2 = reg2.firstMatch(html);
    if (m2 != null) return _decodeHtmlEntities(m2.group(1)!);
    return null;
  }

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

  static void clearCache() {
    _metaCache.clear();
    _typeCache.clear();
  }
}
