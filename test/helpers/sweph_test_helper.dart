import 'dart:io';
import 'dart:typed_data';

import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:sweph/sweph.dart';

class _FileAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) => File(assetPath).readAsBytes();
}

/// Path of the host Swiss Ephemeris library built by tool/build_sweph_test_lib.sh.
String? swephTestLibraryPath() {
  final env = Platform.environment['SWEPH_DYLIB_PATH'];
  if (env != null && File(env).existsSync()) return env;
  for (final name in ['libsweph.so', 'libsweph.dylib', 'sweph.dll']) {
    final f = File('build/test_native/$name');
    if (f.existsSync()) return f.absolute.path;
  }
  return null;
}

/// Reason to skip Swiss Ephemeris tests, or null when they can run.
String? swephSkipReason() => swephTestLibraryPath() == null
    ? 'Swiss Ephemeris host library missing: run tool/build_sweph_test_lib.sh'
    : null;

Future<void> initEphemerisForTests() async {
  final lib = swephTestLibraryPath();
  if (lib == null) return;
  final src = Directory('build/test_native/ephe_src');
  final dest = Directory('${Directory.systemTemp.path}/jyotish_ephe_test')..createSync(recursive: true);
  await Ephemeris.init(
    modulePath: lib,
    assetLoader: _FileAssetLoader(),
    epheFilesPath: dest.path,
    epheAssets: src.listSync().whereType<File>().map((f) => f.path).toList(),
  );
}
