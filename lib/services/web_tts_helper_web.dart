import 'dart:js' as js;

class WebTtsHelper {
  static Future<void> playAzureTts(String text, String key, String region, String voice, double rateMultiplier) async {
    try {
      js.context.callMethod('playAzureTtsWeb', [text, key, region, voice, rateMultiplier]);
    } catch (e) {
      print('WebTtsHelper playAzureTts error: $e');
    }
  }

  static Future<void> stopAzureTts() async {
    try {
      js.context.callMethod('stopAzureTtsWeb');
    } catch (e) {
      print('WebTtsHelper stopAzureTts error: $e');
    }
  }
}
