import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/core/utils/slug_generator.dart';

void main() {
  group('SlugGenerator.slugify', () {
    test('converts basic text to lowercase slug', () {
      expect(SlugGenerator.slugify('Hello World'), 'hello-world');
      expect(SlugGenerator.slugify('Product Name 123'), 'product-name-123');
    });

    test('removes special characters', () {
      expect(SlugGenerator.slugify('Hello, World!'), 'hello-world');
      expect(SlugGenerator.slugify('Price: \$99.99'), 'price-99-99');
      expect(SlugGenerator.slugify('C++ & Java'), 'c-java');
      expect(SlugGenerator.slugify('Product #123!!'), 'product-123');
    });

    test('handles accented characters', () {
      expect(SlugGenerator.slugify('Café'), 'cafe');
      expect(SlugGenerator.slugify('naïve'), 'naive');
      expect(SlugGenerator.slugify('Zürich'), 'zurich');
      expect(SlugGenerator.slugify('Björk'), 'bjork');
      expect(SlugGenerator.slugify('Crème Brûlée'), 'creme-brulee');
    });

    test('collapses multiple spaces and hyphens', () {
      expect(SlugGenerator.slugify('Hello   World'), 'hello-world');
      expect(SlugGenerator.slugify('Hello - World'), 'hello-world');
      expect(SlugGenerator.slugify('Multiple---Hyphens'), 'multiple-hyphens');
    });

    test('trims leading and trailing hyphens', () {
      expect(SlugGenerator.slugify('---Hello---'), 'hello');
      expect(SlugGenerator.slugify('-Product-'), 'product');
      expect(SlugGenerator.slugify('   Spaces   '), 'spaces');
    });

    test('removes emojis and special unicode', () {
      expect(SlugGenerator.slugify('Hello 👋 World'), 'hello-world');
      expect(SlugGenerator.slugify('🎉 Party Time 🎊'), 'party-time');
    });

    test('handles truncation at word boundaries', () {
      final longText = 'this is a very long slug that needs truncation at boundary';
      final result = SlugGenerator.slugify(longText, maxLength: 30);

      expect(result.length, lessThanOrEqualTo(30));
      expect(result, isNot(endsWith('-'))); // No trailing hyphen
      expect(result, contains('this')); // Starts with beginning of string
    });

    test('handles truncation for very short maxLength', () {
      final result = SlugGenerator.slugify('Hello World Test', maxLength: 5);

      expect(result.length, lessThanOrEqualTo(5));
      expect(result, isNot(contains('--'))); // No consecutive hyphens
      expect(result, isNot(startsWith('-'))); // No leading hyphen
      expect(result, isNot(endsWith('-'))); // No trailing hyphen
    });

    test('handles custom delimiter', () {
      expect(
        SlugGenerator.slugify('Hello World', delimiter: '_'),
        'hello_world',
      );
      expect(
        SlugGenerator.slugify('Product Name', delimiter: '_'),
        'product_name',
      );
    });

    test('handles edge cases', () {
      expect(SlugGenerator.slugify(''), '');
      expect(SlugGenerator.slugify('!!!'), '');
      expect(SlugGenerator.slugify('   '), '');
      expect(SlugGenerator.slugify('123'), '123');
      expect(SlugGenerator.slugify('a'), 'a');
    });

    test('handles mixed case with numbers', () {
      expect(SlugGenerator.slugify('iPhone 14 Pro'), 'iphone-14-pro');
      expect(SlugGenerator.slugify('Version 2.0 Beta'), 'version-2-0-beta');
    });

    test('preserves numbers in slugs', () {
      expect(SlugGenerator.slugify('Room 101'), 'room-101');
      expect(SlugGenerator.slugify('2023 Project'), '2023-project');
    });
  });

  group('SlugGenerator.isValidSlug', () {
    test('accepts valid slugs', () {
      expect(SlugGenerator.isValidSlug('hello-world'), true);
      expect(SlugGenerator.isValidSlug('project-123'), true);
      expect(SlugGenerator.isValidSlug('test'), true);
      expect(SlugGenerator.isValidSlug('a-b-c-d'), true);
      expect(SlugGenerator.isValidSlug('my-room-scan'), true);
      expect(SlugGenerator.isValidSlug('product-2024'), true);
    });

    test('rejects invalid slugs with uppercase', () {
      expect(SlugGenerator.isValidSlug('Hello-World'), false);
      expect(SlugGenerator.isValidSlug('Project-123'), false);
      expect(SlugGenerator.isValidSlug('UPPERCASE'), false);
    });

    test('rejects slugs with leading hyphens', () {
      expect(SlugGenerator.isValidSlug('-hello'), false);
      expect(SlugGenerator.isValidSlug('--project'), false);
    });

    test('rejects slugs with trailing hyphens', () {
      expect(SlugGenerator.isValidSlug('hello-'), false);
      expect(SlugGenerator.isValidSlug('project--'), false);
    });

    test('rejects slugs with consecutive hyphens', () {
      expect(SlugGenerator.isValidSlug('hello--world'), false);
      expect(SlugGenerator.isValidSlug('project---123'), false);
    });

    test('rejects slugs with underscores', () {
      expect(SlugGenerator.isValidSlug('hello_world'), false);
      expect(SlugGenerator.isValidSlug('my_project'), false);
    });

    test('rejects slugs with spaces', () {
      expect(SlugGenerator.isValidSlug('hello world'), false);
      expect(SlugGenerator.isValidSlug('my project'), false);
    });

    test('rejects slugs with special characters', () {
      expect(SlugGenerator.isValidSlug('hello@world'), false);
      expect(SlugGenerator.isValidSlug('project!123'), false);
      expect(SlugGenerator.isValidSlug('test.slug'), false);
    });

    test('rejects empty string', () {
      expect(SlugGenerator.isValidSlug(''), false);
    });

    test('accepts single character slugs', () {
      expect(SlugGenerator.isValidSlug('a'), true);
      expect(SlugGenerator.isValidSlug('1'), true);
    });
  });
}
