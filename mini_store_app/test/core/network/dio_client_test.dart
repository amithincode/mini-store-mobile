import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/config/app_config.dart';
import 'package:mini_store_app/core/network/dio_client.dart';

void main() {
  test('configures the Dio client without making a request', () {
    const config = AppConfig(apiBaseUrl: 'https://dummyjson.com');
    final dio = createDioClient(config);

    expect(dio.options.baseUrl, 'https://dummyjson.com');
    expect(dio.options.connectTimeout, const Duration(seconds: 15));
    expect(dio.options.receiveTimeout, const Duration(seconds: 20));
    expect(dio.options.sendTimeout, const Duration(seconds: 20));
    expect(dio.options.headers['Accept'], 'application/json');
    // Dio installs a single content-type interceptor by default. The app adds
    // no authentication or custom interceptors.
    expect(dio.interceptors, hasLength(1));
  });
}
