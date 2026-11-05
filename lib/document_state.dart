import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_record.dart';
import 'document_services.dart';

final repositoryProvider = Provider<DocumentRepository>(
  (_) => DocumentRepository(),
);
final scannerProvider = Provider<ScannerService>((_) => ScannerService());
final ocrProvider = Provider<OcrService>((_) => OcrService());

final documentsProvider =
    AsyncNotifierProvider<DocumentsController, List<DocumentRecord>>(
      DocumentsController.new,
    );

class DocumentsController extends AsyncNotifier<List<DocumentRecord>> {
  DocumentRepository get _repository => ref.read(repositoryProvider);

  @override
  Future<List<DocumentRecord>> build() => _repository.load();

  Future<DocumentRecord?> scan({int pageLimit = 30, String? name}) async {
    final images = await ref.read(scannerProvider).scan(pageLimit: pageLimit);
    if (images.isEmpty) return null;
    final document = await _repository.importScan(images, name: name);
    await _commit([document, ...?state.value]);
    return document;
  }

  Future<DocumentRecord?> importFromGallery({int pageLimit = 30}) async {
    final images = await ref
        .read(scannerProvider)
        .importFromGallery(pageLimit: pageLimit);
    if (images.isEmpty) return null;
    final document = await _repository.importScan(images);
    await _commit([document, ...?state.value]);
    return document;
  }

  Future<DocumentRecord?> addFile() async {
    final picked = await ref.read(scannerProvider).pickDocumentFile();
    if (picked == null) return null;
    final document = await _repository.importPickedFile(picked);
    await _commit([document, ...?state.value]);
    return document;
  }

  Future<void> rename(String id, String name) async {
    await _replace(
      id,
      (item) => item.copyWith(name: DocumentRepository.sanitizeFileName(name)),
    );
  }

  Future<void> recognizeText(String id) async {
    final document = _find(id);
    final text = await ref.read(ocrProvider).recognize(document.pages);
    await _replace(id, (item) => item.copyWith(ocrText: text));
  }

  Future<void> reorder(String id, int oldIndex, int newIndex) async {
    final document = _find(id);
    final pages = [...document.pages];
    final page = pages.removeAt(oldIndex);
    pages.insert(newIndex, page);
    final rebuilt = await _repository.rebuild(document, pages: pages);
    await _replace(id, (_) => rebuilt);
  }

  Future<void> rotate(String id, int pageIndex) async {
    final document = _find(id);
    final rebuilt = await _repository.rotate(document, pageIndex);
    await _replace(id, (_) => rebuilt);
  }

  Future<void> applyFilter(String id, int pageIndex, PageFilter filter) async {
    final document = _find(id);
    final rebuilt = await _repository.applyFilter(document, pageIndex, filter);
    await _replace(id, (_) => rebuilt);
  }

  Future<void> delete(String id) async {
    final document = _find(id);
    await _repository.deleteFiles(document);
    await _commit(
      (state.value ?? const <DocumentRecord>[])
          .where((item) => item.id != id)
          .toList(),
    );
  }

  DocumentRecord _find(String id) {
    return (state.value ?? const <DocumentRecord>[]).firstWhere(
      (item) => item.id == id,
    );
  }

  Future<void> _replace(
    String id,
    DocumentRecord Function(DocumentRecord) update,
  ) async {
    final items = (state.value ?? const <DocumentRecord>[])
        .map((item) => item.id == id ? update(item) : item)
        .toList();
    await _commit(items);
  }

  Future<void> _commit(List<DocumentRecord> items) async {
    await _repository.save(items);
    state = AsyncData(items);
  }
}
