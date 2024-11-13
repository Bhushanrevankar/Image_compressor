import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessor {
  Future<Map<String, dynamic>> extractPixelData(String imagePath) async {
    print('Searching for image at: $imagePath');

    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw FileSystemException('Image file not found', imagePath);
    }

    Uint8List bytes = await imageFile.readAsBytes();
    print('File size: ${bytes.length} bytes');
    
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      print('Failed to decode image. File might be corrupted or in an unsupported format.');
      throw Exception('Failed to decode image');
    }

    print('Image decoded successfully. Width: ${image.width}, Height: ${image.height}');

    final int width = image.width;
    final int height = image.height;
    final List<int> pixelData = List<int>.filled(width * height * 4, 0);

    int index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        pixelData[index++] = pixel.r.toInt();
        pixelData[index++] = pixel.g.toInt();
        pixelData[index++] = pixel.b.toInt();
        pixelData[index++] = pixel.a.toInt();
      }
    }

    return {
      'pixelData': pixelData,
      'width': width,
      'height': height,
    };
  }

  List<int> extractProminentColors(List<int> pixelData, int width, int height, int blockSize) {
    final int blocksPerRow = width ~/ blockSize;
    final int blocksPerColumn = height ~/ blockSize;
    final List<int> prominentColors = List<int>.filled(blocksPerRow * blocksPerColumn * 4, 0);

    for (int blockY = 0; blockY < blocksPerColumn; blockY++) {
      for (int blockX = 0; blockX < blocksPerRow; blockX++) {
        int rSum = 0, gSum = 0, bSum = 0, aSum = 0;

        for (int y = 0; y < blockSize; y++) {
          for (int x = 0; x < blockSize; x++) {
            final int pixelIndex = ((blockY * blockSize + y) * width + (blockX * blockSize + x)) * 4;
            rSum += pixelData[pixelIndex];
            gSum += pixelData[pixelIndex + 1];
            bSum += pixelData[pixelIndex + 2];
            aSum += pixelData[pixelIndex + 3];
          }
        }

        final int pixelsPerBlock = blockSize * blockSize;
        final int prominentColorIndex = (blockY * blocksPerRow + blockX) * 4;
        prominentColors[prominentColorIndex] = rSum ~/ pixelsPerBlock;
        prominentColors[prominentColorIndex + 1] = gSum ~/ pixelsPerBlock;
        prominentColors[prominentColorIndex + 2] = bSum ~/ pixelsPerBlock;
        prominentColors[prominentColorIndex + 3] = aSum ~/ pixelsPerBlock;
      }
    }

    return prominentColors;
  }

  img.Image generateImageFromProminentColors(List<int> prominentColors, int blocksPerRow, int blocksPerColumn, int blockSize) {
    final int width = blocksPerRow * blockSize;
    final int height = blocksPerColumn * blockSize;
    img.Image generatedImage = img.Image(width: width, height: height);

    for (int blockY = 0; blockY < blocksPerColumn; blockY++) {
      for (int blockX = 0; blockX < blocksPerRow; blockX++) {
        final int colorIndex = (blockY * blocksPerRow + blockX) * 4;
        int r = prominentColors[colorIndex];
        int g = prominentColors[colorIndex + 1];
        int b = prominentColors[colorIndex + 2];
        int a = prominentColors[colorIndex + 3];

        // Create color using the image package's ColorRgba8 class
        final colorPixel = img.ColorRgba8(r, g, b, a);

        // Fill the macro block with the prominent color
        for (int y = 0; y < blockSize; y++) {
          for (int x = 0; x < blockSize; x++) {
            generatedImage.setPixel(
              blockX * blockSize + x,
              blockY * blockSize + y,
              colorPixel
            );
          }
        }
      }
    }

    return generatedImage;
  }
}