import 'dart:io';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';

class SaveMemeInteractor {
  static const memesPathName = "memes";
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() =>
      _instance ??= SaveMemeInteractor._internal();

  SaveMemeInteractor._internal();

  Future<bool> saveMeme({
    required final String id,
    required final List<TextWithPosition> textWithPositions,
    final String? imagePath,
  }) async {
    if (imagePath == null) {
      final meme = Meme(id: id, texts: textWithPositions);
      return MemesRepository.getInstance().addToMemes(meme);
    }

    await createNewFile(imagePath);
    final meme = Meme(
      id: id,
      texts: textWithPositions,
      memePath: imagePath,
    );
    return MemesRepository.getInstance().addToMemes(meme);
  }

  Future<void> createNewFile(final String imagePath) async {
    final docsPath = await getApplicationDocumentsDirectory();
    final memePath =
        "${docsPath.absolute.path}${Platform.pathSeparator}$memesPathName";
    final memeDirectory = Directory(memePath);
    await Directory(memePath).create(recursive: true);
    final currentFiles = memeDirectory.listSync();

    final imageName = _getFileNameByPath(imagePath);
    final oldFileWithTheSameName = currentFiles.firstWhereOrNull(
      (element) {
        return _getFileNameByPath(element.path) == imageName && element is File;
      },
    );
    final newImagePath = "$memePath${Platform.pathSeparator}$imageName";
    final tempFile = File(imagePath);

    if (oldFileWithTheSameName == null) {
      await tempFile.copy(newImagePath);
      return;
    }
    final oldFileLength = await (oldFileWithTheSameName as File).length();
    final newFileLength = await tempFile.length();
    if (oldFileLength == newFileLength) {
      return;
    }
    return _createFileForSameNameButDifferentLength(
      imageName: imagePath,
      newImagePath: newImagePath,
      memePath: memePath,
      tempFile: tempFile,
    );
  }

  Future<void> _createFileForSameNameButDifferentLength({
    required final String imageName,
    required final String newImagePath,
    required final String memePath,
    required final File tempFile,
  }) async {
    final indexOfLastDot = imageName.lastIndexOf(".");
    if (indexOfLastDot == -1) {
      return;
    }
    final extension = imageName.substring(indexOfLastDot);
    final imageNameWithoutExtension = imageName.substring(0, indexOfLastDot);
    final indexOfLastUnderscore = imageNameWithoutExtension.lastIndexOf("_");
    if (indexOfLastUnderscore == -1) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExtension}_1$extension";
      await tempFile.copy(correctedNewImagePath);
    }
    final suffixNumberString =
        imageNameWithoutExtension.substring(indexOfLastUnderscore + 1);
    final suffixNumber = int.tryParse(suffixNumberString);
    if (suffixNumber == null) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExtension}_1$extension";
      await tempFile.copy(correctedNewImagePath);
    } else {
      final imageNameWithoutSuffix =
          imageNameWithoutExtension.substring(0, indexOfLastUnderscore);
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutSuffix}_${suffixNumber + 1}$extension";
      await tempFile.copy(correctedNewImagePath);
    }
  }

  String _getFileNameByPath(String imagePath) =>
      imagePath.split(Platform.pathSeparator).last;
}
