// import android.app.NotificationChannel
// import android.app.NotificationManager
// import android.media.AudioAttributes
// import android.net.Uri
// import android.os.Build
// import android.util.Log
// import com.google.firebase.messaging.FirebaseMessagingService
// import com.google.firebase.messaging.RemoteMessage

// class MyFirebaseMessagingService : FirebaseMessagingService() {

//     override fun onMessageReceived(remoteMessage: RemoteMessage) {
//         super.onMessageReceived(remoteMessage)

//         // Handle your notification logic here
//         Log.d(TAG, "From: ${remoteMessage.from}")

//         // Check if message contains a data payload
//         remoteMessage.data.isNotEmpty().let {
//             Log.d(TAG, "Message data payload: ${remoteMessage.data}")

//             // Extract sound file name from message data
//             val soundFileName = remoteMessage.data["status"]

//             // Update the notification channel with the dynamic sound file name
//             createNotificationChannel(soundFileName)
//         }

//         // Check if message contains a notification payload
//         remoteMessage.notification?.let {
//             Log.d(TAG, "Message Notification Body: ${it.body}")
//         }
//     }

//     private fun createNotificationChannel(soundFileName: String?) {
//         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//             val channelId = "laporcepat"
//             val channelName = "laporcepat"
//             val importance = NotificationManager.IMPORTANCE_HIGH

//             val channel = NotificationChannel(channelId, channelName, importance)
//             val notificationManager =
//                 getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

//             // Configure the notification channel with sound
//             channel.setSound(getNotificationSoundUri(soundFileName), AudioAttributes.Builder()
//                     .setUsage(AudioAttributes.USAGE_NOTIFICATION)
//                     .build())

//             notificationManager.createNotificationChannel(channel)
//         }
//     }

//     private fun getNotificationSoundUri(soundFileName: String?): Uri? {
//         // Replace with your logic to get the URI based on soundFileName
//         // Example: Uri.parse("android.resource://" + packageName + "/raw/" + soundFileName)
//         return Uri.parse(
//             "android.resource://" +
//                     applicationContext.packageName +
//                     "/" +
//                     soundFileName
//         )
//     }

//     companion object {
//         private const val TAG = "MyFirebaseMsgService"
//     }
// }