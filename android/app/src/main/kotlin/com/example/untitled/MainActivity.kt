package com.example.untitled

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/background")
            .setMethodCallHandler { call, result ->
                if (call.method == "moveToBackground") {
                    moveTaskToBack(true)
                    result.success(null)
                }
            }
    }
}