import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

class ScanPage {
  ScanPage({required this.id, required this.bytes, required this.createdAt});

  final String id;
  final Uint8List bytes;
  final DateTime createdAt;

  ScanPage copyWith({Uint8List? bytes}) {
    return ScanPage(
      id: id,
      bytes: bytes ?? this.bytes,
      createdAt: createdAt,
    );
  }
}

class ScanSessionState {
  const ScanSessionState({this.pages = const []});

  final List<ScanPage> pages;

  int get totalPages => pages.length;

  ScanSessionState copyWith({List<ScanPage>? pages}) {
    return ScanSessionState(pages: pages ?? this.pages);
  }
}

class ScanSessionController extends StateNotifier<ScanSessionState> {
  ScanSessionController() : super(const ScanSessionState());

  List<ScanPage> get pages => state.pages;

  Future<void> addPage(Uint8List bytes) async {
    final corrected = await _fixOrientation(bytes);
    final page = ScanPage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      bytes: corrected,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(pages: [...state.pages, page]);
  }

  void removePage(String id) {
    state =
        state.copyWith(pages: state.pages.where((page) => page.id != id).toList());
  }

  Future<void> rotatePage(String id) async {
    final updatedPages = <ScanPage>[];
    for (final page in state.pages) {
      if (page.id == id) {
        final rotated = await _rotate90(page.bytes);
        updatedPages.add(page.copyWith(bytes: rotated));
      } else {
        updatedPages.add(page);
      }
    }
    state = state.copyWith(pages: updatedPages);
  }

  void reorder(int oldIndex, int newIndex) {
    final pages = [...state.pages];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final page = pages.removeAt(oldIndex);
    pages.insert(newIndex, page);
    state = state.copyWith(pages: pages);
  }

  void clear() {
    state = const ScanSessionState();
  }

  List<Uint8List> get pagesBytes => state.pages.map((p) => p.bytes).toList();

  Future<Uint8List> _fixOrientation(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return bytes;
    }
    final baked = img.bakeOrientation(image);
    return Uint8List.fromList(img.encodeJpg(baked, quality: 90));
  }

  Future<Uint8List> _rotate90(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return bytes;
    }
    final rotated = img.copyRotate(image, angle: 90);
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
  }
}

final scanSessionProvider =
    StateNotifierProvider<ScanSessionController, ScanSessionState>((ref) {
  return ScanSessionController();
});
