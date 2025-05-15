part of cqt_api_services;


class ApiClient {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  final Future<void> Function()? onTokenExpired;
  final String? masterUrl;
  final String? loginUrl;
  final String? smartFloBaseUrl;

  static const String noInternetMessage = 'Connection to API server failed';
  final int timeoutInSeconds = 30;

  String? token;
  late Map<String, String> _mainHeaders;
  late Map<String, String> _getmainHeaders;

  ApiClient({
    required this.appBaseUrl,
    required this.sharedPreferences,
    this.onTokenExpired,
    this.masterUrl,
    this.loginUrl,
    this.smartFloBaseUrl,
  }) {
    token = sharedPreferences.getString('token');
    postUpdateHeader(token);
    getUpdateHeader(token);
  }

  void postUpdateHeader(String? token) {
    _mainHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
      'Accept-Language': sharedPreferences.getString('language_code') ?? 'en'
    };
  }

  void getUpdateHeader(String? token) {
    _getmainHeaders = {
      'Authorization': 'Bearer $token',
      'Accept-Language': sharedPreferences.getString('language_code') ?? 'en'
    };
  }

  Future<http.Response> _handleHttp(http.Response response) async {
    if (response.statusCode == 401 && onTokenExpired != null) {
      await onTokenExpired!();
    }
    return response;
  }

  Future<Response> getData(String uri,
      {Map<String, String>? headers}) async {
    try {
      final response = await http
          .get(Uri.parse(appBaseUrl + uri), headers: headers ?? _getmainHeaders)
          .timeout(Duration(seconds: timeoutInSeconds));
      await _handleHttp(response);
      return _handleResponse(response);
    } catch (_) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postData(String uri, dynamic body,
      {Map<String, String>? headers}) async {
    try {
      final response = await http
          .post(Uri.parse(appBaseUrl + uri),
          body: jsonEncode(body), headers: headers ?? _mainHeaders)
          .timeout(Duration(seconds: timeoutInSeconds));
      await _handleHttp(response);
      return _handleResponse(response);
    } catch (_) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putData(String uri, dynamic body,
      {Map<String, String>? headers}) async {
    try {
      final response = await http
          .put(Uri.parse(appBaseUrl + uri),
          body: jsonEncode(body), headers: headers ?? _mainHeaders)
          .timeout(Duration(seconds: timeoutInSeconds));
      await _handleHttp(response);
      return _handleResponse(response);
    } catch (_) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> deleteData(String uri,
      {Map<String, String>? headers}) async {
    try {
      final response = await http
          .delete(Uri.parse(appBaseUrl + uri), headers: headers ?? _mainHeaders)
          .timeout(Duration(seconds: timeoutInSeconds));
      return _handleResponse(response);
    } catch (_) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postMultipartData(String uri, Map<String, String> body,
      List<MultipartBody>? multipartBody, File? otherFile,
      {Map<String, String>? headers}) async {
    try {
      var request =
      http.MultipartRequest('POST', Uri.parse(appBaseUrl + uri));
      request.headers.addAll(headers ?? _mainHeaders);
      request.fields.addAll(body);

      if (otherFile != null) {
        final bytes = await otherFile.readAsBytes();
        request.files.add(http.MultipartFile(
          'submitted_file',
          Stream.value(bytes),
          bytes.length,
          filename: basename(otherFile.path),
        ));
      }

      if (multipartBody != null) {
        for (var part in multipartBody) {
          final file = File(part.file.path);
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile(
            part.key!,
            Stream.value(bytes),
            bytes.length,
            filename: basename(file.path),
          ));
        }
      }

      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(response);
    } catch (_) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<bool> isTokenExpired(String token) async {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return DateTime.now().isAfter(exp);
    } catch (_) {
      if (onTokenExpired != null) await onTokenExpired!();
      return true;
    }
  }

  Response _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    return Response(
      body: body,
      bodyString: response.body,
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: response.reasonPhrase,
    );
  }
}

class Response {
  final dynamic body;
  final String? bodyString;
  final Map<String, String>? headers;
  final int? statusCode;
  final String? statusText;

  Response({
    this.body,
    this.bodyString,
    this.headers,
    this.statusCode,
    this.statusText,
  });
}

class MultipartBody {
  final String? key;
  final XFile file;

  MultipartBody(this.key, this.file);
}

