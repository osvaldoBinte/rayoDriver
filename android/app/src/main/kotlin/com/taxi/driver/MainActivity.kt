package com.taxi.driver

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class MainActivity: FlutterActivity() {
    private val CHANNEL_WHATSAPP = "com.tuapp/whatsapp"
    private val CHANNEL_PHONE = "com.tuapp/phone"
    private val PERMISSION_REQUEST_CODE = 123
    private var pendingEmergencyCallUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // WhatsApp Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_WHATSAPP).setMethodCallHandler { call: MethodCall, result: Result ->
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PHONE).setMethodCallHandler { call: MethodCall, result: Result ->
            when (call.method) {
                "makePhoneCall" -> {
                    try {
                        val url = call.argument<String>("url") ?: ""
                        val intent = Intent(Intent.ACTION_DIAL)
                        intent.data = Uri.parse(url)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "No se pudo iniciar la llamada", null)
                    }
                }
                "makeEmergencyCall" -> {
                    try {
                        val url = call.argument<String>("url") ?: ""
                        if (checkAndRequestCallPermission()) {
                            makeEmergencyCall(url, result)
                        } else {
                            pendingEmergencyCallUrl = url
                            result.error("PERMISSION_DENIED", "Se requieren permisos para realizar la llamada", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "No se pudo iniciar la llamada de emergencia", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndRequestCallPermission(): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED) {
            println("Solicitando permiso CALL_PHONE")
            
            if (ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.CALL_PHONE)) {
                println("Debería mostrar razón del permiso")
            }
            
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                PERMISSION_REQUEST_CODE
            )
            return false
        }
        println("Permiso CALL_PHONE ya concedido")
        return true
    }

    private fun makeEmergencyCall(url: String, result: Result) {
        try {
            println("Intentando realizar llamada de emergencia a: $url")
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
                == PackageManager.PERMISSION_GRANTED) {
                val intent = Intent(Intent.ACTION_CALL)
                intent.data = Uri.parse(url)
                startActivity(intent)
                result.success(true)
            } else {
                println("Permiso no concedido al intentar hacer la llamada")
                result.error("PERMISSION_DENIED", "No se tienen los permisos necesarios", null)
            }
        } catch (e: Exception) {
            println("Error al realizar llamada: ${e.message}")
            result.error("ERROR", "No se pudo iniciar la llamada de emergencia: ${e.message}", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        println("onRequestPermissionsResult: requestCode=$requestCode")
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty()) {
                println("Resultado del permiso: ${if (grantResults[0] == PackageManager.PERMISSION_GRANTED) "CONCEDIDO" else "DENEGADO"}")
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    pendingEmergencyCallUrl?.let { url ->
                        makeEmergencyCall(url, object : Result {
                            override fun success(result: Any?) {
                                println("Llamada realizada con éxito después de conceder permiso")
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                println("Error al realizar llamada después de conceder permiso: $errorMessage")
                            }
                            override fun notImplemented() {}
                        })
                        pendingEmergencyCallUrl = null
                    }
                }
            }
        }
    }
} // Esta es la llave que faltaba
