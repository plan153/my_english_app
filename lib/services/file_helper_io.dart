import 'dart:io';

/// 네이티브(모바일·데스크톱) 파일 입출력 구현.
class FileHelper {
  /// 경로의 파일을 문자열로 읽는다.
  static Future<String> readFile(String path) => File(path).readAsString();

  /// 네이티브에는 브라우저 다운로드가 없으므로 false를 반환한다.
  /// (호출 측에서 다이얼로그/클립보드 대체 UI를 띄운다.)
  static bool triggerDownload(String filename, String content) => false;
}
