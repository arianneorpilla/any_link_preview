import 'package:http/http.dart' as http;

Future<http.Response> fetchWithRedirects(
  String url, {
  int maxRedirects = 7,
  Map<String, String> headers = const {},
  String? userAgent,
}) async {
  const userAgentFallback = 'WhatsApp/2.21.12.21 A';
  Map<String, String>? allHeaders = {
    ...headers,
    'User-Agent': userAgent ?? userAgentFallback,
  };
  
  // First, check content type with HEAD request
  var headResponse = await http.head(Uri.parse(url), headers: allHeaders);
  var redirectCount = 0;

  // Follow redirects with HEAD
  while (_isRedirect(headResponse) && redirectCount < maxRedirects) {
    final location = headResponse.headers['location'];
    if (location == null) {
      throw Exception('HTTP redirect without Location header');
    }

    headResponse = await http.head(Uri.parse(location), headers: allHeaders);
    redirectCount++;
  }

  if (redirectCount >= maxRedirects) {
    throw Exception('Maximum redirect limit reached');
  }

  // Check if content type is appropriate (not a file download)
  final contentType = headResponse.headers['content-type'];
  if (contentType != null && _isFileContentType(contentType)) {
    throw Exception('URL points to a file, not a web page');
  }

  // Now perform GET request
  var response = await http.get(Uri.parse(url), headers: allHeaders);
  redirectCount = 0;

  while (_isRedirect(response) && redirectCount < maxRedirects) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('HTTP redirect without Location header');
    }

    response = await http.get(Uri.parse(location), headers: allHeaders);
    redirectCount++;
  }

  if (redirectCount >= maxRedirects) {
    throw Exception('Maximum redirect limit reached');
  }

  return response;
}

bool _isRedirect(http.Response response) {
  return [301, 302, 303, 307, 308].contains(response.statusCode);
}

bool _isFileContentType(String contentType) {
  // Parse the content type to remove charset and other parameters
  final mainType = contentType.split(';').first.trim().toLowerCase();
  
  // List of content types that are acceptable (web pages, APIs, etc.)
  const acceptableTypes = [
    'text/html',
    'text/plain',
    'application/json',
    'application/ld+json',
    'application/xml',
    'text/xml',
    'application/xhtml+xml',
  ];
  
  // If it's an acceptable type, it's not a file
  if (acceptableTypes.contains(mainType)) {
    return false;
  }
  
  // If it starts with text/, it's probably acceptable
  if (mainType.startsWith('text/')) {
    return false;
  }
  
  // Everything else is considered a file (images, videos, PDFs, etc.)
  return true;
}

Future<http.Response> getYoutubeData(
  String videoId, {
  Map<String, String>? headers,
  String? userAgent,
}) async {
  const userAgentFallback = 'WhatsApp/2.21.12.21 A';
  Map<String, String>? allHeaders = {
    ...?headers,
    'User-Agent': userAgent ?? userAgentFallback,
  };
  var response = await http.get(
    Uri.parse(
      'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json',
    ),
    headers: allHeaders,
  );
  return response;
}

String? getYouTubeVideoId(String url) {
  // Regular expression pattern to detect YouTube URLs
  // with or without a proxy prefix
  final regExp = RegExp(
    r'(?:https?:\/\/)?(?:[^\/]+\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|v\/|.+\?v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
  );

  // Apply the regex to the URL
  final match = regExp.firstMatch(url);

  // If a match is found, return the first capture group, which is the video ID
  return match?.group(1);
}
