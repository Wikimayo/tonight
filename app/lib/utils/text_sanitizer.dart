class TextSanitizer {
  const TextSanitizer._();

  static String clean(String value) {
    var text = value.trim();

    const replacements = <String, String>{
      'ÃƒÂ¡': 'á',
      'ÃƒÂ©': 'é',
      'ÃƒÂ­': 'í',
      'ÃƒÂ³': 'ó',
      'ÃƒÂº': 'ú',
      'ÃƒÂ±': 'ñ',
      'ÃƒÂ¼': 'ü',
      'ÃƒÂ§': 'ç',
      'Ã¡': 'á',
      'Ã ': 'à',
      'Ã¢': 'â',
      'Ã¤': 'ä',
      'Ã£': 'ã',
      'Ã©': 'é',
      'Ã¨': 'è',
      'Ãª': 'ê',
      'Ã«': 'ë',
      'Ã­': 'í',
      'Ã¬': 'ì',
      'Ã®': 'î',
      'Ã¯': 'ï',
      'Ã³': 'ó',
      'Ã²': 'ò',
      'Ã´': 'ô',
      'Ã¶': 'ö',
      'Ãµ': 'õ',
      'Ãº': 'ú',
      'Ã¹': 'ù',
      'Ã»': 'û',
      'Ã¼': 'ü',
      'Ã±': 'ñ',
      'Ã§': 'ç',
      'Ã': 'Á',
      'Ã‰': 'É',
      'Ã': 'Í',
      'Ã“': 'Ó',
      'Ãš': 'Ú',
      'Ã‘': 'Ñ',
      'Â¿': '¿',
      'Â¡': '¡',
      'Â·': '·',
      'Â«': '«',
      'Â»': '»',
      'Âº': 'º',
      'Âª': 'ª',
      'ââ€šÂ¬': '€',
      'â‚¬': '€',
      'Ã¢â€šÂ¬': '€',
      'â€¦': '...',
      'â€“': '-',
      'â€”': '-',
      'â€œ': '"',
      'â€': '"',
      'â€˜': "'",
      'â€™': "'",
      '�': '',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    return text
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String? cleanOptional(String? value) {
    final cleaned = clean(value ?? '');
    return cleaned.isEmpty ? null : cleaned;
  }
}
