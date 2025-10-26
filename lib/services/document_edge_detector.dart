import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

/// Utility service that tries to detect the bounding rectangle of a document
/// inside an image. The returned [Rect] uses normalized coordinates (0.0-1.0)
/// so it can be consumed directly by [Crop] widgets.
class DocumentEdgeDetector {
  const DocumentEdgeDetector._();

  /// Detects the document bounds inside the image described by [bytes].
  ///
  /// Returns `null` when the document could not be detected.
  static Rect? detect(Uint8List bytes) {
    try {
      final original = img.decodeImage(bytes);
      if (original == null) {
        return null;
      }

      final grayscale = img.grayscale(original);
      final edges = img.sobel(grayscale);
      if (edges == null) {
        return null;
      }

      final width = edges.width;
      final height = edges.height;
      if (width == 0 || height == 0) {
        return null;
      }

      var sum = 0.0;
      var sumSquared = 0.0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final luminance = img.getLuminance(edges.getPixel(x, y)).toDouble();
          sum += luminance;
          sumSquared += luminance * luminance;
        }
      }

      final totalPixels = width * height;
      final mean = sum / totalPixels;
      final variance = (sumSquared / totalPixels) - (mean * mean);
      final stdDeviation = math.sqrt(math.max(variance, 0));
      // Heuristic threshold: anything higher than mean + std deviation is
      // considered part of an edge. Clamp to avoid being too permissive.
      final threshold = mean + stdDeviation;
      final effectiveThreshold = threshold.clamp(32, 255).toDouble();

      var minX = width;
      var minY = height;
      var maxX = -1;
      var maxY = -1;

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final luminance = img.getLuminance(edges.getPixel(x, y));
          if (luminance >= effectiveThreshold) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }

      if (maxX == -1 || maxY == -1) {
        return null;
      }

      // Expand a little bit so that the edges sit inside the crop area.
      final marginX = (width * 0.03).round();
      final marginY = (height * 0.03).round();
      minX = math.max(0, minX - marginX);
      minY = math.max(0, minY - marginY);
      maxX = math.min(width - 1, maxX + marginX);
      maxY = math.min(height - 1, maxY + marginY);

      final rectWidth = (maxX - minX + 1).toDouble();
      final rectHeight = (maxY - minY + 1).toDouble();

      if (rectWidth <= 0 || rectHeight <= 0) {
        return null;
      }

      // Avoid returning a rectangle that basically covers the whole image or
      // is too tiny (likely noise).
      final widthRatio = rectWidth / width;
      final heightRatio = rectHeight / height;
      if (widthRatio < 0.2 || heightRatio < 0.2) {
        return null;
      }
      if (widthRatio > 0.98 && heightRatio > 0.98) {
        return null;
      }

      final left = minX / width;
      final top = minY / height;
      final right = (maxX + 1) / width;
      final bottom = (maxY + 1) / height;

      final normalized = Rect.fromLTRB(
        left.clamp(0.0, 1.0),
        top.clamp(0.0, 1.0),
        right.clamp(0.0, 1.0),
        bottom.clamp(0.0, 1.0),
      );

      if (normalized.width <= 0 || normalized.height <= 0) {
        return null;
      }

      return normalized;
    } catch (_) {
      return null;
    }
  }
}
