part of cqt_api_services;

class LocationHelper {
  /// Fetches the current location of the device.
  static Future<geo.Position?> getCurrentLocation({
    required BuildContext context,
    required void Function(double lat, double long) onLocationFetched,
    required void Function(bool isReady) onLocationReady,
  }) async {
    location.Location locationService = location.Location();
    bool serviceEnabled;
    location.PermissionStatus permissionGranted;

    try {
      serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
          return null;
        }
      }

      permissionGranted = await locationService.hasPermission();
      if (permissionGranted == location.PermissionStatus.denied) {
        permissionGranted = await locationService.requestPermission();
        if (permissionGranted != location.PermissionStatus.granted) {
          final userDecision = await _showPermissionDialog(context);
          if (!userDecision) {
            Navigator.pop(context);
            return null;
          } else {
            permissionGranted = await locationService.requestPermission();
            if (permissionGranted != location.PermissionStatus.granted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Location permissions are still denied.')),
              );
              return null;
            }
          }
        }
      }

      locationService.changeSettings(
        accuracy: location.LocationAccuracy.high,
        distanceFilter: 10,
      );

      geo.Position position;
      try {
        position = await Future.any([
          geo.Geolocator.getCurrentPosition(
              desiredAccuracy: geo.LocationAccuracy.high),
          Future.delayed(
              const Duration(seconds: 10),
                  () => throw TimeoutException('Location fetch timeout')),
        ]);
      } catch (e) {
        onLocationReady(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e is TimeoutException
                  ? 'Unable to load the location. Try again later.'
                  : 'Error fetching location: ${e.toString()}')),
        );
        return null;
      }

      onLocationFetched(position.latitude, position.longitude);
      onLocationReady(true);
      return position;
    } catch (e) {
      onLocationReady(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: ${e.toString()}')),
      );
      return null;
    }
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission'),
          content: const Text('Please allow location permission to proceed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    ) ??
        false;
  }
}
