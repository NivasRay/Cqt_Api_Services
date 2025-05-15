part of cqt_api_services;

class CvsDeviceTokenHelper{

  Future<String?> saveDeviceToken() async {
    String? deviceToken = '@';
    try {
      deviceToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      //
    }
    if (deviceToken != null) {}
    return deviceToken;
  }

}