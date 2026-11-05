import 'package:flutter_test/flutter_test.dart';
import 'package:tamad/document_record.dart';
import 'package:tamad/document_services.dart';

void main() {
  test('document metadata survives a JSON round trip', () {
    final source = DocumentRecord(
      id: 'doc-1',
      name: 'Receipt',
      createdAt: DateTime.utc(2026, 11, 5, 5, 30),
      pages: const ['/tmp/page-1.jpg', '/tmp/page-2.jpg'],
      pdfPath: '/tmp/receipt.pdf',
      ocrText: 'TOTAL 125.00',
    );

    final restored = DocumentRecord.fromJson(source.toJson());

    expect(restored.id, source.id);
    expect(restored.name, source.name);
    expect(restored.createdAt, source.createdAt);
    expect(restored.pages, source.pages);
    expect(restored.pdfPath, source.pdfPath);
    expect(restored.ocrText, source.ocrText);
  });

  test('unsafe filename characters are replaced', () {
    expect(
      DocumentRepository.sanitizeFileName('  Invoice: 11/05?  '),
      'Invoice_ 11_05_',
    );
    expect(DocumentRepository.sanitizeFileName('***'), '___');
  });

  test('an imported PDF keeps its file-only form in saved metadata', () {
    final source = DocumentRecord(
      id: 'pdf-1',
      name: 'Contract',
      createdAt: DateTime.utc(2026, 11, 5),
      pages: const [],
      pdfPath: '/tmp/contract.pdf',
    );

    final restored = DocumentRecord.fromJson(source.toJson());

    expect(restored.isImportedPdf, isTrue);
    expect(restored.pages, isEmpty);
    expect(restored.pdfPath, source.pdfPath);
  });
}
