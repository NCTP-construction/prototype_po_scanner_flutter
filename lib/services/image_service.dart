import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  Future<String> saveImagePermanently(String temporaryPath) async {
    // 1. Get the directory where the app can store files safely
    final directory = await getApplicationDocumentsDirectory();

    // 2. Create a unique filename (e.g., "20240520_143000.jpg")
    final fileName = path.basename(temporaryPath);
    final permanentPath = '${directory.path}/$fileName';

    // 3. Copy the file from Cache to Documents
    final File tempFile = File(temporaryPath);
    await tempFile.copy(permanentPath);

    // 4. Return the new safe path to store in your database
    return permanentPath;
  }
}
