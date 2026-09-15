package com.chembuddy.chem_buddy

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Request highest available display refresh rate (90Hz / 120Hz / 144Hz)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val display = windowManager.defaultDisplay
                val modes = display.supportedModes
                var maxRate = 60f
                var targetModeId = 0
                for (mode in modes) {
                    if (mode.refreshRate > maxRate) {
                        maxRate = mode.refreshRate
                        targetModeId = mode.modeId
                    }
                }
                if (targetModeId != 0) {
                    val params = window.attributes
                    params.preferredDisplayModeId = targetModeId
                    window.attributes = params
                }
            } catch (_: Exception) {
                // Graceful fallback
            }
        }
    }
}
