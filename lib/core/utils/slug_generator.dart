/// Slug generation utility for creating URL-friendly strings
///
/// Features:
/// - Converts to lowercase
/// - Replaces spaces/special chars with hyphens
/// - Handles accented characters (basic Latin-1 supplement)
/// - Removes consecutive hyphens
/// - Trims leading/trailing hyphens
/// - Optional length truncation
class SlugGenerator {
  // Pre-compiled regex patterns for performance
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _validSlugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  // Common diacritic mappings (Latin-1 Supplement + Extended-A)
  static const Map<String, String> _diacriticMap = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'æ': 'ae',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'œ': 'oe',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ß': 'ss',
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Ä': 'A',
    'Å': 'A',
    'Æ': 'AE',
    'Ç': 'C',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Ì': 'I',
    'Í': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ñ': 'N',
    'Ò': 'O',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ø': 'O',
    'Œ': 'OE',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ý': 'Y',
    'Ÿ': 'Y',
  };

  /// Generate a URL-friendly slug from input text
  ///
  /// [text] - The input string to convert
  /// [maxLength] - Optional maximum length (default: no limit)
  /// [delimiter] - Character to use as separator (default: '-')
  ///
  /// Returns a lowercase, hyphenated slug suitable for URLs
  ///
  /// Example:
  /// ```dart
  /// slugify('Hello World!'); // 'hello-world'
  /// slugify('Café & Restaurant', maxLength: 10); // 'cafe'
  /// slugify('Product #123', delimiter: '_'); // 'product_123'
  /// ```
  static String slugify(String text, {int? maxLength, String delimiter = '-'}) {
    if (text.isEmpty) return '';

    // Step 1: Remove diacritics/accents
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(_diacriticMap[char] ?? char);
    }

    var slug = buffer.toString();

    // Step 2: Convert to lowercase
    slug = slug.toLowerCase();

    // Step 3: Replace whitespace with delimiter
    slug = slug.replaceAll(_whitespace, delimiter);

    // Step 4: Replace non-alphanumeric characters with delimiter (except existing delimiters)
    // Allow delimiter in regex pattern
    final safeDelimiter = RegExp.escape(delimiter);
    final nonAlphanumericPattern = RegExp('[^a-z0-9$safeDelimiter]+');
    slug = slug.replaceAll(nonAlphanumericPattern, delimiter);

    // Step 5: Collapse multiple consecutive delimiters
    final multipleDelimitersPattern = RegExp('$safeDelimiter{2,}');
    slug = slug.replaceAll(multipleDelimitersPattern, delimiter);

    // Step 6: Trim leading/trailing delimiters
    final leadingTrailingPattern = RegExp('^$safeDelimiter+|$safeDelimiter+\$');
    slug = slug.replaceAll(leadingTrailingPattern, '');

    // Step 7: Truncate if needed
    if (maxLength != null && maxLength > 0 && slug.length > maxLength) {
      slug = _truncateAtWordBoundary(slug, maxLength, delimiter);
    }

    return slug;
  }

  /// Truncate slug at word boundary (delimiter) if possible
  static String _truncateAtWordBoundary(
    String slug,
    int maxLength,
    String delimiter,
  ) {
    if (slug.length <= maxLength) return slug;

    var truncated = slug.substring(0, maxLength);
    final lastDelimiterIndex = truncated.lastIndexOf(delimiter);

    // If we can keep at least 70% of content, truncate at last delimiter
    if (lastDelimiterIndex > maxLength * 0.7) {
      return truncated.substring(0, lastDelimiterIndex);
    }

    // Otherwise hard truncate and clean up
    final safeDelimiter = RegExp.escape(delimiter);
    final trailingPattern = RegExp('$safeDelimiter+\$');
    return truncated.replaceAll(trailingPattern, '');
  }

  /// Validates if a string is a valid slug
  ///
  /// Returns true if the slug matches the required format:
  /// - Lowercase alphanumeric characters and hyphens only
  /// - No leading or trailing hyphens
  /// - No consecutive hyphens
  ///
  /// Example:
  /// ```dart
  /// isValidSlug('my-project'); // true
  /// isValidSlug('My-Project'); // false (uppercase)
  /// isValidSlug('my--project'); // false (consecutive hyphens)
  /// ```
  static bool isValidSlug(String slug) {
    if (slug.isEmpty) return false;
    return _validSlugPattern.hasMatch(slug);
  }
}
