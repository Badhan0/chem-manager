package com.example.chem_manager

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.chem_manager/whatsapp"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareFile") {
                val phone = call.argument<String>("phone")
                val filePath = call.argument<String>("path")

                if (phone != null && filePath != null) {
                    shareToWhatsApp(phone, filePath)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "Phone or Path missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun shareToWhatsApp(phone: String, filePath: String) {
        val file = File(filePath)
        val uri = FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
        
        // WhatsApp JID format: formatted number (no +) + "@s.whatsapp.net"
        val jid = "$phone@s.whatsapp.net"

        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "application/pdf"
        intent.setPackage("com.whatsapp")
        intent.putExtra("jid", jid) 
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        
        try {
            startActivity(intent)
        } catch (e: Exception) {
            println("Error launching WhatsApp: $e")
        }
    }
}
