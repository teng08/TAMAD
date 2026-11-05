import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'document_record.dart';
import 'document_services.dart';
import 'document_state.dart';

enum _PageAction { rotate, original, enhance, grayscale, blackWhite }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TamadApp()));
}

class TamadApp extends StatelessWidget {
  const TamadApp({super.key});

  static const seed = Color(0xFF006D77);
  static const coral = Color(0xFFFF7A59);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAMAD',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const HomeShell(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF5F7F6)
          : const Color(0xFF101414),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF182020),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  bool _scanning = false;

  Future<void> _scan({int pageLimit = 30, String? name}) async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      final document = await ref
          .read(documentsProvider.notifier)
          .scan(pageLimit: pageLimit, name: name);
      if (!mounted) return;
      if (document == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan cancelled. No pages were saved.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${document.pageCount}-page PDF saved locally.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not finish the scan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _importGallery() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      final document = await ref
          .read(documentsProvider.notifier)
          .importFromGallery();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document == null
                ? 'No photos were selected.'
                : '${document.pageCount}-page PDF saved locally.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import photos: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addFile() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      final document = await ref.read(documentsProvider.notifier).addFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document == null
                ? 'No file was selected.'
                : '${document.isImportedPdf ? 'PDF' : 'Image'} added to your library.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not add file: $error')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onScan: _scan,
        onImportGallery: _importGallery,
        onAddFile: _addFile,
      ),
      LibraryScreen(onAddFile: _addFile),
      ToolsScreen(onIdScan: () => _scan(pageLimit: 2, name: 'ID card')),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: pages),
          if (_scanning)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 18),
                          Text('Preparing your document…'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_rounded),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onScan,
    required this.onImportGallery,
    required this.onAddFile,
    super.key,
  });

  final Future<void> Function({int pageLimit, String? name}) onScan;
  final VoidCallback onImportGallery;
  final VoidCallback onAddFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(documentsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/branding/tamad-icon.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAMAD',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('Quietly turn paper into something useful.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _ScanCard(
              onTap: () => onScan(pageLimit: 30),
              onImportGallery: onImportGallery,
              onAddFile: onAddFile,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent documents',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Text('Stored locally'),
              ],
            ),
            const SizedBox(height: 8),
            documents.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _MessageCard(
                icon: Icons.error_outline,
                title: 'Library unavailable',
                message: '$error',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _MessageCard(
                    icon: Icons.inbox_rounded,
                    title: 'Your shelf is clear',
                    message: 'Scan a receipt, handout, or form. TAMAD will keep the pages and a PDF on this device.',
                  );
                }
                return Column(
                  children: items
                      .take(3)
                      .map(
                        (document) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DocumentTile(document: document),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.onTap,
    required this.onImportGallery,
    required this.onAddFile,
  });
  final VoidCallback onTap;
  final VoidCallback onImportGallery;
  final VoidCallback onAddFile;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: TamadApp.coral,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TamadApp.coral.withValues(alpha: .3),
                      blurRadius: 26,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Scan a document',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Automatic edges and perspective crop, with multi-page PDF export.',
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Auto crop')),
                  Chip(label: Text('Batch')),
                  Chip(label: Text('Filters')),
                  Chip(label: Text('PDF')),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onImportGallery,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Import photos'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onAddFile,
                icon: const Icon(Icons.note_add_rounded),
                label: const Text('Add file'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({required this.onAddFile, super.key});

  final VoidCallback onAddFile;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Library',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onAddFile,
                  icon: const Icon(Icons.note_add_rounded),
                  label: const Text('Add file'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search names and recognized text',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: documents.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
                data: (items) {
                  final visible = items.where((item) {
                    if (_query.isEmpty) return true;
                    return item.name.toLowerCase().contains(_query) ||
                        item.ocrText.toLowerCase().contains(_query);
                  }).toList();
                  if (visible.isEmpty) {
                    return const Center(
                      child: Text('No documents match this search.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 28),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        DocumentTile(document: visible[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentTile extends StatelessWidget {
  const DocumentTile({required this.document, super.key});
  final DocumentRecord document;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: document.isImportedPdf
              ? const SizedBox(
                  width: 58,
                  height: 72,
                  child: Icon(Icons.picture_as_pdf_rounded, size: 34),
                )
              : Image.file(
                  File(document.pages.first),
                  width: 58,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 58,
                    height: 72,
                    child: Icon(Icons.description_rounded),
                  ),
                ),
        ),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${document.isImportedPdf ? 'PDF file' : '${document.pageCount} page${document.pageCount == 1 ? '' : 's'}'} · ${DateFormat.yMMMd().add_jm().format(document.createdAt)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentDetailScreen(documentId: document.id),
          ),
        ),
      ),
    );
  }
}

class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({required this.documentId, super.key});
  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _working = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _rename(DocumentRecord document) async {
    final controller = TextEditingController(text: document.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(documentsProvider.notifier).rename(document.id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(documentsProvider).value ?? const <DocumentRecord>[];
    final matches = items.where((item) => item.id == widget.documentId);
    if (matches.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('This document is no longer available.')),
      );
    }
    final document = matches.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(document.name),
        actions: [
          IconButton(
            onPressed: _working ? null : () => _rename(document),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _working
                        ? null
                        : () => OpenFilex.open(document.pdfPath),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Open PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _working
                        ? null
                        : () => SharePlus.instance.share(
                            ShareParams(
                              text: 'Scanned with TAMAD',
                              files: [XFile(document.pdfPath)],
                            ),
                          ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                  if (!document.isImportedPdf)
                    OutlinedButton.icon(
                      onPressed: _working
                          ? null
                          : () => _run(
                              () => ref
                                  .read(documentsProvider.notifier)
                                  .recognizeText(document.id),
                            ),
                      icon: const Icon(Icons.text_snippet_rounded),
                      label: Text(
                        document.ocrText.isEmpty
                            ? 'Recognize text'
                            : 'Refresh OCR',
                      ),
                    ),
                ],
              ),
              if (document.ocrText.isNotEmpty) ...[
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recognized text',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(document.ocrText, maxLines: 8),
                      ],
                    ),
                  ),
                ),
              ],
              if (document.isImportedPdf)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'Imported PDFs open and share as their original file. Page editing and OCR are available for scanned images.',
                  ),
                ),
              if (!document.isImportedPdf) ...[
                const SizedBox(height: 20),
                Text(
                  'Pages',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: document.pages.length,
                  onReorderItem: _working
                      ? (_, _) {}
                      : (oldIndex, newIndex) => _run(
                          () => ref
                              .read(documentsProvider.notifier)
                              .reorder(document.id, oldIndex, newIndex),
                        ),
                  itemBuilder: (context, index) => Card(
                    key: ValueKey(document.pages[index]),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(document.pages[index]),
                              width: 82,
                              height: 104,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Page ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          PopupMenuButton<_PageAction>(
                            tooltip: 'Edit page',
                            enabled: !_working,
                            icon: const Icon(Icons.tune_rounded),
                            onSelected: (action) => _run(() async {
                              final controller = ref.read(
                                documentsProvider.notifier,
                              );
                              await switch (action) {
                                _PageAction.rotate => controller.rotate(
                                  document.id,
                                  index,
                                ),
                                _PageAction.original => controller.applyFilter(
                                  document.id,
                                  index,
                                  PageFilter.original,
                                ),
                                _PageAction.enhance => controller.applyFilter(
                                  document.id,
                                  index,
                                  PageFilter.enhance,
                                ),
                                _PageAction.grayscale => controller.applyFilter(
                                  document.id,
                                  index,
                                  PageFilter.grayscale,
                                ),
                                _PageAction.blackWhite =>
                                  controller.applyFilter(
                                    document.id,
                                    index,
                                    PageFilter.blackWhite,
                                  ),
                              };
                              await FileImage(File(document.pages[index]))
                                  .evict();
                            }),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: _PageAction.rotate,
                                child: Text('Rotate clockwise'),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: _PageAction.original,
                                child: Text('Original color'),
                              ),
                              PopupMenuItem(
                                value: _PageAction.enhance,
                                child: Text('Enhance contrast'),
                              ),
                              PopupMenuItem(
                                value: _PageAction.grayscale,
                                child: Text('Grayscale'),
                              ),
                              PopupMenuItem(
                                value: _PageAction.blackWhite,
                                child: Text('Black and white'),
                              ),
                            ],
                          ),
                          const Icon(Icons.drag_handle_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_working)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({required this.onIdScan, super.key});
  final VoidCallback onIdScan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Text(
            'Tools',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'The working tools are available now; planned tools are clearly marked.',
          ),
          const SizedBox(height: 20),
          _ToolCard(
            icon: Icons.badge_rounded,
            title: 'ID card scan',
            subtitle: 'Capture front and back as a two-page PDF.',
            actionLabel: 'Scan',
            onTap: onIdScan,
          ),
          const _ToolCard(
            icon: Icons.text_snippet_rounded,
            title: 'Offline OCR',
            subtitle: 'Open a document and recognize English or Filipino text on-device.',
            actionLabel: 'Available in documents',
          ),
          const _ToolCard(
            icon: Icons.call_merge_rounded,
            title: 'Merge and split',
            subtitle: 'Planned for a later release.',
            actionLabel: 'Coming next',
          ),
          const _ToolCard(
            icon: Icons.draw_rounded,
            title: 'Sign and annotate',
            subtitle: 'Planned for a later release.',
            actionLabel: 'Coming next',
          ),
          const _ToolCard(
            icon: Icons.lock_rounded,
            title: 'Password-protected PDF',
            subtitle: 'Planned for a later release.',
            actionLabel: 'Coming next',
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onTap, child: Text(actionLabel)),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          const _InfoRow(
            icon: Icons.palette_rounded,
            title: 'Appearance',
            subtitle: 'Follows your phone’s light or dark theme.',
          ),
          const _InfoRow(
            icon: Icons.storage_rounded,
            title: 'Storage',
            subtitle: 'Scans, PDFs, metadata, and OCR text stay in the app’s private local storage.',
          ),
          const _InfoRow(
            icon: Icons.cloud_off_rounded,
            title: 'No account or ads',
            subtitle: 'TAMAD has no sign-in, ads, subscription, analytics, or watermark.',
          ),
          const _InfoRow(
            icon: Icons.info_outline_rounded,
            title: 'Scanner model',
            subtitle: 'Android scanning uses Google Play services; iPhone scanning uses Apple VisionKit. OCR runs on-device.',
          ),
          const SizedBox(height: 18),
          const Center(child: Text('TAMAD 1.2.3 (6)')),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(subtitle),
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
