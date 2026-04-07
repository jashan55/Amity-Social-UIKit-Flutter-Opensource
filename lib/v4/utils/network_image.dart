import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AmityNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final String placeHolderPath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AmityNetworkImage(
      {super.key,
      required this.imageUrl,
      required this.placeHolderPath,
      this.fit = BoxFit.cover,
      this.width,
      this.height});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty && isValidImageUrl(imageUrl!)) {
      return _renderImage();
    } else {
      return SvgPicture.asset(
        placeHolderPath,
        package: 'amity_uikit_beta_service',
      );
    }
  }

  Image _renderImage() {
    if (_isHttpUrl(imageUrl!)) {
      return Image.network(
        imageUrl!,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child;
          } else {
            return SvgPicture.asset(
              placeHolderPath,
              package: 'amity_uikit_beta_service',
            );
          }
        },
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return SvgPicture.asset(
            placeHolderPath,
            package: 'amity_uikit_beta_service',
          );
        },
      );
    } else {
      return Image.file(
        File(imageUrl!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return SvgPicture.asset(
            placeHolderPath,
            package: 'amity_uikit_beta_service',
          );
        },
      );
    }
  }
}

// Helper function to get image dimensions
Future<AmityImageWithSize> getImageWithSize(
    String? imageUrl, Uint8List? memoryImage) async {
  final Completer<AmityImageWithSize> completer = Completer();
  Image? image;
  try {
    if (imageUrl != null) {
      if (_isHttpUrl(imageUrl)) {
        image = Image.network(
          imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        image = Image.file(
          File(imageUrl),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      }
    } else if (memoryImage != null) {
      image = Image.memory(
        memoryImage,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }
  } catch (e) {
    completer.completeError(e);
  }

  if (image != null) {
    image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            completer.complete(
              AmityImageWithSize(
                image!,
                Size(
                  info.image.width.toDouble(),
                  info.image.height.toDouble(),
                ),
              ),
            );
          }, onError: (dynamic exception, StackTrace? stackTrace) {
            completer.completeError(exception);
          }),
        );
  }

  return completer.future;
}

bool _isHttpUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.scheme.startsWith('http') && uri.host.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Returns true if the URL is usable for display — either a valid HTTP URL
/// or a valid local file path. Rejects empty/broken URIs like "file:///".
bool isValidImageUrl(String url) {
  if (url.isEmpty) return false;
  try {
    final uri = Uri.parse(url);
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return uri.host.isNotEmpty;
    }
    if (uri.scheme == 'file') {
      // "file:///" with no actual path is invalid
      return uri.path.length > 1;
    }
    // Local file path (no scheme)
    return url.startsWith('/') && url.length > 1;
  } catch (_) {
    return false;
  }
}

class AmityImageWithSize {
  Image image;
  Size size;

  AmityImageWithSize(this.image, this.size);
}
