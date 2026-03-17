import 'dart:io';

Map<String, String> loadEnvFromFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('env 文件不存在: $filePath');
  }

  final result = <String, String>{};
  final lines = file.readAsLinesSync();

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final index = line.indexOf('=');
    if (index <= 0) {
      continue;
    }

    final key = line.substring(0, index).trim();
    final value = line.substring(index + 1).trim();
    result[key] = value;
  }

  return result;
}