/// 플랫폼별 파일 입출력 헬퍼 (조건부 import).
///
/// 웹에서는 `dart:html` 기반 다운로드를, 네이티브에서는 `dart:io` 기반
/// 파일 읽기를 제공한다. 어느 플랫폼에서도 컴파일되도록 stub을 기본값으로 둔다.
library;

export 'file_helper_stub.dart'
    if (dart.library.html) 'file_helper_web.dart'
    if (dart.library.io) 'file_helper_io.dart';
