package ng.edu.unn.lionfm

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is required (not FlutterActivity) so that
// audio_service v0.18+ can correctly bind its MediaBrowserService
// lifecycle to a Fragment host during background radio streaming.
class MainActivity : FlutterFragmentActivity()
