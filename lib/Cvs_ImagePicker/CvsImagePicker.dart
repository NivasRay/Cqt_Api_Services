part of cqt_api_services;

class CvsImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> showImageSourcePicker(
      BuildContext context, {
        int imageQuality = 80,
      }) async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text("Camera"),
                onTap: () async {
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: imageQuality,
                  );
                  Navigator.pop(context, picked != null ? File(picked.path) : null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () async {
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: imageQuality,
                  );
                  Navigator.pop(context, picked != null ? File(picked.path) : null);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
