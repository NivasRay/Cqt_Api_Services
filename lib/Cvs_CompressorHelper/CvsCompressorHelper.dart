part of cqt_api_services;

class CvsCompressorhelper{

  Future<XFile?> CvsImageCompresser(PlatformFile file) async {
    if (file.path == null || !file.extension!.contains('jpg') && !file.extension!.contains('png')) {
      return null; // Not an image
    }

    final dir = await getTemporaryDirectory();
    final targetPath = path.join(dir.absolute.path, 'compressed_${file.name}');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path!,
      targetPath,
      quality: 60, // adjust between 0–100
    );

    return result;
  }

}