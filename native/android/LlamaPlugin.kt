// Copy into android/app/src/main/kotlin/<your package>/ and call LlamaPlugin.register(flutterEngine, modelPath)
// from MainActivity.configureFlutterEngine(). Status: channel contract only. Bind LlamaJni to llama.cpp
// (see examples/llama.android in the llama.cpp repo) and set ready=true after a successful load.
package org.gramvidya.gramvidya

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

object LlamaJni {
    @Volatile var ready = false
    fun load(path: String): Boolean = false          // TODO: System.loadLibrary("llama_jni") + native load
    fun generate(system: String, prompt: String, onToken: (String) -> Unit) {} // TODO: native streaming decode
}

object LlamaPlugin {
    fun register(engine: FlutterEngine, modelPath: String) {
        val ui = Handler(Looper.getMainLooper())
        MethodChannel(engine.dartExecutor.binaryMessenger, "gramvidya/llama").setMethodCallHandler { call, result ->
            when (call.method) {
                "isModelLoaded" -> {
                    if (!LlamaJni.ready && File(modelPath).exists()) LlamaJni.load(modelPath)
                    result.success(LlamaJni.ready)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(engine.dartExecutor.binaryMessenger, "gramvidya/llama/tokens").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                val a = args as Map<*, *>
                Thread {
                    LlamaJni.generate(a["system"] as String, a["prompt"] as String) { t -> ui.post { sink.success(t) } }
                    ui.post { sink.endOfStream() }
                }.start()
            }
            override fun onCancel(args: Any?) {}
        })
    }
}
