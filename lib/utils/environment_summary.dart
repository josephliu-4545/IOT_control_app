String cleanEnvironmentSummary(String value) {
  return value
      .replaceAll(RegExp(r'\s*\(\s*\d+(?:\.\d+)?\s*\)'), '')
      .replaceAll(RegExp(r'\s+,\s*'), ', ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}
