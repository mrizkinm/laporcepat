package com.example.laporcepat

// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugins.GeneratedPluginRegistrant
// import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService
// import android.content.Intent
// import android.os.Build
// import android.os.Bundle
// import android.util.Log
// import androidx.annotation.RequiresApi
// import com.google.firebase.messaging.FirebaseMessaging

// class MainActivity : FlutterActivity() {

//     @RequiresApi(Build.VERSION_CODES.O)
//     override fun onCreate(savedInstanceState: Bundle?) {
//         super.onCreate(savedInstanceState)
//         GeneratedPluginRegistrant.registerWith(FlutterEngine(this))

//         // Initialize Firebase messaging
//         FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
//             if (task.isSuccessful) {
//                 val token = task.result
//                 Log.d(TAG, "FCM Token: $token")
//             } else {
//                 Log.w(TAG, "Fetching FCM registration token failed", task.exception)
//             }
//         }
//     }

//     companion object {
//         private const val TAG = "MainActivity"
//     }
// }

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.RawRes
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONException
import org.json.JSONObject

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Extract sound name from the payload
            val payload = intent.extras?.getString("notification")
            Log.d("MainActivity", "FCM Payload: $payload")
            val soundName = extractSoundNameFromPayload(payload)

            // Map sound name to resource id
            val soundResourceId = when (soundName) {
                "darurat" -> R.raw.darurat
                "ringan" -> R.raw.ringan
                "sedang" -> R.raw.sedang
                else -> R.raw.darurat // default sound if not found
            }

            val soundUri: Uri = getSoundUri(soundResourceId)

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()

            val channel = NotificationChannel(
                "laporcepat",
                "laporcepat",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.setSound(soundUri, audioAttributes)

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun getSoundUri(soundResourceId: Int): Uri {
        return Uri.parse(
            "android.resource://" +
                    applicationContext.packageName +
                    "/" +
                    soundResourceId
        )
    }

    private fun extractSoundNameFromPayload(payload: String?): String {
        return try {
            if (payload != null) {
                val json = JSONObject(payload)
                json.getJSONObject("notification").getString("sound")
            } else {
                "darurat"
            }
        } catch (e: JSONException) {
            "darurat"
        }
    }
}

// package com.example.laporcepat

// import io.flutter.embedding.android.FlutterActivity

// class MainActivity: FlutterActivity() {
// }
