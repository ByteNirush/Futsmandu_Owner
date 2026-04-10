export 'api_client.dart';

import 'api_client.dart';

class OwnerApiClient extends ApiClient {
  OwnerApiClient._internal();

  static final OwnerApiClient _instance = OwnerApiClient._internal();
  factory OwnerApiClient() => _instance;
}
