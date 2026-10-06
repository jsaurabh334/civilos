import 'package:url_launcher/url_launcher.dart';
import 'api_client.dart';

void downloadExport(String path, String filename) {
  final baseUrl = ApiClient.baseUrl;
  final uri = Uri.parse('$baseUrl$path');
  launchUrl(uri, mode: LaunchMode.externalApplication);
}
