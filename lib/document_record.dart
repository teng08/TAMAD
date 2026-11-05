class DocumentRecord {
  const DocumentRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.pages,
    required this.pdfPath,
    this.ocrText = '',
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> pages;
  final String pdfPath;
  final String ocrText;

  int get pageCount => pages.length;
  bool get isImportedPdf => pages.isEmpty;

  DocumentRecord copyWith({
    String? name,
    List<String>? pages,
    String? pdfPath,
    String? ocrText,
  }) {
    return DocumentRecord(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      pages: pages ?? this.pages,
      pdfPath: pdfPath ?? this.pdfPath,
      ocrText: ocrText ?? this.ocrText,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'pages': pages,
    'pdfPath': pdfPath,
    'ocrText': ocrText,
  };

  factory DocumentRecord.fromJson(Map<String, dynamic> json) {
    return DocumentRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pages: List<String>.from(json['pages'] as List),
      pdfPath: json['pdfPath'] as String,
      ocrText: json['ocrText'] as String? ?? '',
    );
  }
}
