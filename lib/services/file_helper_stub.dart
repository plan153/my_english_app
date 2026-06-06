/// 어떤 플랫폼 라이브러리도 사용할 수 없을 때의 기본 구현.
class FileHelper {
  /// 경로의 파일을 문자열로 읽는다 (네이티브 전용).
  static Future<String> readFile(String path) async {
    throw UnsupportedError('파일 읽기는 이 플랫폼에서 지원되지 않습니다.');
  }

  /// 브라우저 다운로드를 트리거한다. 지원되면 true.
  static bool triggerDownload(String filename, String content) => false;
}
