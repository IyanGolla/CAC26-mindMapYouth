import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256. The PIN itself is never stored, only salt + hash.
class PinHasher {
  static const iterations = 100000;

  static String newSalt() {
    final r = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String hash(String pin, String salt, {int iterations = iterations}) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    // Single block (32 bytes) is all we need.
    final block = Uint8List.fromList([...base64Decode(salt), 0, 0, 0, 1]);
    var u = hmac.convert(block).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return base64Encode(out);
  }

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
