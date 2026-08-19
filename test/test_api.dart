import 'dart:convert';
import 'dart:io';

void main() async {
  print('==================================================');
  print('Testing JioSaavn API Connection...');
  print('==================================================\n');

  // Direct JioSaavn Launch Data API Endpoint
  final Uri url = Uri.parse(
    'https://www.jiosaavn.com/api.php?__call=webapi.getLaunchData&api_version=4&_format=json&_marker=0',
  );

  final HttpClient httpClient = HttpClient();

  try {
    final HttpClientRequest request = await httpClient.getUrl(url);

    // Modern browsers/clients headers to bypass Cloudflare/IP blocking
    request.headers.set(
      'User-Agent',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    );
    request.headers.set('Accept', 'application/json, text/plain, */*');
    request.headers.set('Referer', 'https://www.jiosaavn.com/');

    print('Sending request to: $url\n');
    final HttpClientResponse response = await request.close();

    print('HTTP Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final String responseBody = await response.transform(utf8.decoder).join();

      print('\n--- Raw Response Preview (First 500 chars) ---');
      print(
        responseBody.length > 500
            ? responseBody.substring(0, 500) + '...'
            : responseBody,
      );
      print('--------------------------------------------\n');

      try {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        print('✅ SUCCESS: JSON decoded successfully!');
        print('Top-level keys found in response: ${data.keys.toList()}');

        if (data.containsKey('modules')) {
          print('\nFound "modules" key (Home screen categories):');
          print((data['modules'] as Map).keys.toList());
        } else {
          print('\n⚠️ WARNING: "modules" key is missing from response.');
        }
      } catch (e) {
        print('❌ JSON PARSE ERROR: Response was not valid JSON.');
        print('Detailed error: $e');
      }
    } else {
      print('❌ REQUEST FAILED with Status Code: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ NETWORK ERROR: Failed to reach the server.');
    print('Error details: $e');
  } finally {
    httpClient.close();
  }
}