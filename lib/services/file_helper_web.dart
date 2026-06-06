// 웹 전용 구현. 조건부 import로 웹에서만 컴파일된다.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// 웹 파일 입출력 구현.
class FileHelper {
  /// 웹에서는 file_picker가 바이트를 직접 제공하므로 경로 읽기는 쓰지 않는다.
  static Future<String> readFile(String path) async {
    throw UnsupportedError('웹에서는 파일 바이트를 직접 사용하세요.');
  }

  /// `<a download>` 앵커를 만들어 브라우저 파일 다운로드를 트리거한다.
  static bool triggerDownload(String filename, String content) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  }
}
