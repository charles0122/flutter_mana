package com.example.example

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.StringCodec

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val messenger = flutterEngine.dartExecutor.binaryMessenger

    val lifecycleChannel = BasicMessageChannel<String>(
      messenger,
      "mana/demo/lifecycle",
      StringCodec.INSTANCE
    )
    val keyboardChannel = BasicMessageChannel<Map<String, Any>>(
      messenger,
      "mana/demo/keyboard",
      JSONMessageCodec.INSTANCE
    )

    Handler(Looper.getMainLooper()).postDelayed({
      lifecycleChannel.send("resumed")
    }, 500)

    Handler(Looper.getMainLooper()).postDelayed({
      keyboardChannel.send(mapOf("type" to "keydown"))
    }, 1000)

    EventChannel(messenger, "mana/demo/stream").setStreamHandler(object : EventChannel.StreamHandler {
      private var handler: Handler? = null
      private var runnable: Runnable? = null
      private var count: Int = 0
      override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        handler = Handler(Looper.getMainLooper())
        runnable = Runnable {
          count += 1
          events.success(mapOf("type" to "tick", "count" to count, "ts" to System.currentTimeMillis()))
          handler?.postDelayed(runnable!!, 5000)
        }
        handler?.postDelayed(runnable!!, 5000)
      }
      override fun onCancel(arguments: Any?) {
        handler?.removeCallbacks(runnable!!)
        runnable = null
        handler = null
      }
    })
  }
}
