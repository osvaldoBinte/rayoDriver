package com.taxi.driver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val CHANNEL_WHATSAPP = "com.tuapp/whatsapp"
    private val CHANNEL_PHONE = "com.tuapp/phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // WhatsApp Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_WHATSAPP).setMethodCallHandler { call, result ->
            if (call.method == "openWhatsApp") {
                try {
                    val url = call.argument<String>("url") ?: ""
                    val intent = Intent(Intent.ACTION_VIEW)
                    intent.data = Uri.parse(url)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "No se pudo abrir WhatsApp", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Phone Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PHONE).setMethodCallHandler { call, result ->
            if (call.method == "makePhoneCall") {
                try {
                    val url = call.argument<String>("url") ?: ""
                    val intent = Intent(Intent.ACTION_DIAL)
                    intent.data = Uri.parse(url)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "No se pudo iniciar la llamada", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}