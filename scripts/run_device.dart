import 'dart:io';

Future<void> main(List<String> args) async {
  String? ip;
  
  try {
    // Find local IP address
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          // Prefer Wi-Fi or Ethernet
          if (ip == null || interface.name.toLowerCase().contains('wi')) {
            ip = addr.address;
          }
        }
      }
    }
  } catch (e) {
    print('Warning: Failed to parse network interfaces.');
  }

  if (ip == null) {
    print('Could not find local IP address. Running standard flutter run.');
    final process = await Process.start('flutter', ['run', ...args], mode: ProcessStartMode.inheritStdio);
    exit(await process.exitCode);
  }

  print('');
  print('===================================================');
  print(' 🌐 Auto-Detected Host IP : $ip');
  print(' 🚀 Injecting BACKEND_IP  : $ip -> flutter run');
  print('===================================================');
  print('');

  final process = await Process.start(
    'flutter', 
    ['run', '--dart-define=BACKEND_IP=$ip', ...args],
    mode: ProcessStartMode.inheritStdio,
  );
  
  exit(await process.exitCode);
}
