import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String? vendorName;
  final int? totalCost;

  OcrResult({this.vendorName, this.totalCost});
}

class OcrService {
  static Future<OcrResult?> recognizeReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _parseReceiptText(recognizedText);
    } finally {
      textRecognizer.close();
    }
  }

  static OcrResult? _parseReceiptText(RecognizedText recognizedText) {
    final allLines = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        allLines.add(line.text.trim());
      }
    }

    if (allLines.isEmpty) return null;

    String? vendorName;
    int? totalCost;
    final amounts = <int>[];
    final totalKeywords = ['합계', '총액', '총 금', 'Total', 'TOTAL', 'total'];

    for (final line in allLines) {
      final matches = RegExp(r'(\d{1,3}(?:,\d{3})*)').allMatches(line);
      for (final match in matches) {
        final amount = int.tryParse(match.group(1)!.replaceAll(',', ''));
        if (amount != null && amount > 500) {
          amounts.add(amount);
        }
      }

      final wonMatch = RegExp(r'₩\s*(\d{1,3}(?:,\d{3})*)').firstMatch(line);
      if (wonMatch != null) {
        final amount = int.tryParse(wonMatch.group(1)!.replaceAll(',', ''));
        if (amount != null) amounts.add(amount);
      }
    }

    for (final line in allLines) {
      if (totalKeywords.any((k) => line.contains(k))) {
        final matches = RegExp(r'(\d{1,3}(?:,\d{3})*)').allMatches(line);
        for (final match in matches) {
          final amount = int.tryParse(match.group(1)!.replaceAll(',', ''));
          if (amount != null && amount > 0) {
            totalCost = amount;
            break;
          }
        }
        if (totalCost != null) break;
      }
    }

    if (totalCost == null && amounts.isNotEmpty) {
      amounts.sort();
      totalCost = amounts.last;
    }

    final ignorePatterns = [
      RegExp(r'^\d'),
      '서울', '경기', '인천', '부산', '대구', '대전', '광주', '울산', '세종',
      '주소', '전화', '사업자', '대표', '주민', '홈페이지', '이메일',
    ];

    for (final line in allLines) {
      final trimmed = line.trim();
      if (trimmed.length < 2) continue;
      if (ignorePatterns.any((p) => p is RegExp ? p.hasMatch(trimmed) : trimmed.contains(p as String))) continue;
      if (RegExp(r'\d{4}[-/\s]\d{1,2}[-/\s]\d{1,2}').hasMatch(trimmed)) continue;
      if (trimmed.startsWith('(') || trimmed.startsWith('[')) continue;

      vendorName = trimmed;
      break;
    }

    return OcrResult(vendorName: vendorName, totalCost: totalCost);
  }
}
