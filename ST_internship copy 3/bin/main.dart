import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../lib/image_processor.dart';
import 'package:image/image.dart' as img;

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Please provide an image path.');
    return;
  }

  final imagePath = arguments[0];
  final processor = ImageProcessor();
  
  try {
    // Extract pixel data
    final result = await processor.extractPixelData(imagePath);
    final pixelData = result['pixelData'] as List<int>;
    final width = result['width'] as int;
    final height = result['height'] as int;
    
    print('Pixel data extracted. Dimensions: ${width}x${height}');
    print('Number of pixels: ${pixelData.length ~/ 4}');
    print('First pixel RGBA: ${pixelData.sublist(0, 4)}');
    
    // Prepare data for sharing with layer-1 (above) for "Original Image" display
    final originalImageData = {
      'type': 'original_image',
      'width': width,
      'height': height,
    };
    
    print('Sending pixel data back to layer-1 for "Original Image" display...');
    shareDataWithLayer1(originalImageData);
    
    // Extract prominent colors from 32x32 macro blocks
    final int blockSize = 32;
    final prominentColors = processor.extractProminentColors(pixelData, width, height, blockSize);
    
    final int blocksPerRow = width ~/ blockSize;
    final int blocksPerColumn = height ~/ blockSize;
    final int macroBlocksCount = prominentColors.length ~/ 4;
    print('Extracted prominent colors from $macroBlocksCount macro blocks');
    print('First macro block color RGBA: ${prominentColors.sublist(0, 4)}');
    
    // Generate image from prominent colors
    final generatedImage = processor.generateImageFromProminentColors(prominentColors, blocksPerRow, blocksPerColumn, blockSize);
    final pngBytes = img.encodePng(generatedImage);
    
    // Determine the directory and file name for the generated image
    final inputDirectory = p.dirname(imagePath);
    final inputFileName = p.basenameWithoutExtension(imagePath);
    final generatedImagePath = p.join(inputDirectory, '${inputFileName}_processed.png');
    
    // Save the generated image to the filesystem
    final generatedFile = File(generatedImagePath);
    await generatedFile.writeAsBytes(pngBytes);
    print('Generated image saved at: $generatedImagePath');
    
    // Prepare data for sharing with layer-1 (above) for "Extracted Pixel Image" display
    final extractedPixelImageData = {
      'type': 'extracted_pixel_image',
      'imagePath': generatedImagePath,
      'width': blocksPerRow * blockSize,
      'height': blocksPerColumn * blockSize,
      'blockSize': blockSize
    };
    
    // Share data with layer-1 (above)
    print('Sending extracted pixel image data to layer-1 for "Extracted Pixel Image" display...');
    shareDataWithLayer1(extractedPixelImageData);
    
    // Prepare data for sharing with layer-3 (below) for compression
    final compressionData = {
      'type': 'compression_data',
      'imagePath': generatedImagePath,
      'width': blocksPerRow * blockSize,
      'height': blocksPerColumn * blockSize,
      'blockSize': blockSize
    };
    
    // Share data with layer-3 (below)
    print('Sending macro block colors to layer-3 for compression...');
    shareDataWithLayer3(compressionData);
    
  } catch (e) {
    print('Error processing image: $e');
  }
}

void shareDataWithLayer1(Map<String, dynamic> data) {
  // This is a placeholder function. In a real application, you would implement
  // the actual mechanism to share data with layer-1.
  // For now, we'll just print the data to stdout.
  print('Data for layer-1:');
  print(jsonEncode(data));
}

void shareDataWithLayer3(Map<String, dynamic> data) {
  // This is a placeholder function. In a real application, you would implement
  // the actual mechanism to share data with layer-3.
  // For now, we'll just print the data to stdout.
  print('Data for layer-3:');
  print(jsonEncode(data));
}