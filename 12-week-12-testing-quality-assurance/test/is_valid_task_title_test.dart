import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/is_valid_task_title.dart';

void main() {
  group('isValidTaskTitle - Unit Test & Edge Cases', () {
    // 1. Uji perilaku standar
    test('menerima judul yang berisi teks standar', () {
      // Arrange
      const title = 'Belajar Flutter';

      // Act
      final result = isValidTaskTitle(title);

      // Assert
      expect(result, isTrue);
    });

    test('menolak teks kosong atau hanya spasi', () {
      // Arrange & Act & Assert
      expect(isValidTaskTitle(''), isFalse);
      expect(isValidTaskTitle('   '), isFalse);
    });

    // 2. Kasus tepi: Variasi Whitespace (Tab, Newline, Kombinasi)
    test('menolak string yang hanya berisi newline, tab, atau carriage return', () {
      // Arrange
      const tabOnly = '\t\t\t';
      const newlineOnly = '\n\n\r';
      const mixedWhitespace = ' \t \n \r ';

      // Act & Assert
      expect(isValidTaskTitle(tabOnly), isFalse);
      expect(isValidTaskTitle(newlineOnly), isFalse);
      expect(isValidTaskTitle(mixedWhitespace), isFalse);
    });

    // 3. Kasus tepi: Judul valid dengan spasi di awal dan/atau di akhir
    test('menerima judul yang diawali atau diakhiri spasi berlebih', () {
      // Arrange
      const leadingSpace = '   Tugas Mobile';
      const trailingSpace = 'Tugas Mobile   ';
      const surroundingSpace = '   Tugas Mobile Week 12   ';

      // Act
      final resultLeading = isValidTaskTitle(leadingSpace);
      final resultTrailing = isValidTaskTitle(trailingSpace);
      final resultSurrounding = isValidTaskTitle(surroundingSpace);

      // Assert
      expect(resultLeading, isTrue);
      expect(resultTrailing, isTrue);
      expect(resultSurrounding, isTrue);
    });

    // 4. Kasus tepi: Batas nilai terpendek (Boundary: Single Character)
    test('menerima judul dengan panjang minimal 1 karakter non-spasi', () {
      // Arrange
      const singleChar = 'A';
      const singleDigit = '1';
      const singleSymbol = '?';

      // Act & Assert
      expect(isValidTaskTitle(singleChar), isTrue);
      expect(isValidTaskTitle(singleDigit), isTrue);
      expect(isValidTaskTitle(singleSymbol), isTrue);
    });

    // 5. Kasus tepi: Karakter Unicode / Emoji
    test('menerima judul yang mengandung emoji atau karakter unicode', () {
      // Arrange
      const emojiTitle = '🎯 Testing QA';
      const onlyEmoji = '🔥';

      // Act & Assert
      expect(isValidTaskTitle(emojiTitle), isTrue);
      expect(isValidTaskTitle(onlyEmoji), isTrue);
    });

    // 6. Kasus batas atas: Teks sangat panjang (Boundary test)
    test('menerima judul yang sangat panjang', () {
      // Arrange
      final veryLongTitle = 'A' * 1000;

      // Act
      final result = isValidTaskTitle(veryLongTitle);

      // Assert
      expect(result, isTrue);
    });
  });
}
