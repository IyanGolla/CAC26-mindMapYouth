import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Hand-offs to the phone's own apps. Nothing is logged.

Uri telUri(String number) => Uri(scheme: 'tel', path: number);

Uri smsUri(String number, {String? body, TargetPlatform? platform}) {
  if (body == null) return Uri.parse('sms:$number');
  // iOS and Android disagree on the separator before "body".
  final sep = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS ? '&' : '?';
  return Uri.parse('sms:$number${sep}body=${Uri.encodeComponent(body)}');
}

Uri directionsUri(double lat, double lng, String label, {TargetPlatform? platform}) =>
    (platform ?? defaultTargetPlatform) == TargetPlatform.iOS
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng')
        : Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})');

/// Opens [uri] in another app. Shows [fallback] if the phone can't.
Future<void> open(BuildContext context, Uri uri, {required String fallback}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(fallback)));
}
