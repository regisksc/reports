part of 'portal_submission_client.dart';

Future<List<_Json>> _validatedPhotos(Report report) async {
  final location = report.debrisLocation;
  final quantity = report.quantity;
  if (report.itemFamily == null && (location == null || quantity == null)) {
    throw const _Failure(
      SubmissionFailureKind.rejected,
      'Missing debris details',
    );
  }
  if (report.description.length > _maxDescriptionLength) {
    throw _Failure(
      SubmissionFailureKind.rejected,
      'Description must be $_maxDescriptionLength characters or fewer.',
    );
  }
  return _photoLinks(report.photoPaths);
}

Future<List<_Json>> _photoLinks(List<String> paths) async {
  if (paths.length > 3) {
    throw const _Failure(
      SubmissionFailureKind.rejected,
      'A report can include up to 3 photos. Remove extra photos before sending.',
    );
  }
  final links = <_Json>[];
  for (final path in paths) {
    Uint8List bytes;
    try {
      bytes = await File(path).readAsBytes();
    } on FileSystemException {
      throw const _Failure(
        SubmissionFailureKind.rejected,
        'The photo could not be read. Choose it again.',
      );
    }
    if (bytes.length > 10000000) {
      throw const _Failure(
        SubmissionFailureKind.rejected,
        'Each photo must be 10 MB or smaller. Choose a smaller photo.',
      );
    }
    if (bytes.length > 500000) {
      final normalized = await compute(_normalizePhoto, bytes);
      if (normalized == null) {
        throw const _Failure(
          SubmissionFailureKind.rejected,
          'The photo could not be prepared. Choose it again.',
        );
      }
      bytes = normalized;
    }
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    links.add({
      'fileData': base64Encode(bytes),
      'fileName': name,
      'showImage': true,
      'showPdf': false,
      'fileType': dot < 0 ? '' : name.substring(dot + 1),
      'position': null,
    });
  }
  return links;
}

Uint8List? _normalizePhoto(Uint8List bytes) {
  try {
    final decoded = image.decodeImage(bytes);
    if (decoded == null) return null;
    var normalized = image.bakeOrientation(decoded);
    if (max(normalized.width, normalized.height) > 600) {
      normalized = image.copyResize(
        normalized,
        width: normalized.width >= normalized.height ? 600 : null,
        height: normalized.height > normalized.width ? 600 : null,
        interpolation: image.Interpolation.linear,
      );
    }
    normalized.exif = image.ExifData();
    return image.encodeJpg(normalized, quality: 50);
  } on image.ImageException {
    return null;
  }
}
