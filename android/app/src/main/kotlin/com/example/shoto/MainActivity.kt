package com.example.shoto

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth's Android implementation needs a FragmentActivity host to show
// the BiometricPrompt dialog for private-folder unlock.
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HapticsChannel.register(this, flutterEngine)
        FilePickerChannel.register(this, flutterEngine)
    }

    // Only the picker's own request code is consumed; everything else still
    // reaches super, or photo_manager's permission flows would break.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (FilePickerChannel.onActivityResult(this, requestCode, resultCode, data)) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
