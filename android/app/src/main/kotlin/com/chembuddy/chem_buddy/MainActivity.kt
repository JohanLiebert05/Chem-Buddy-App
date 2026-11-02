package com.chembuddy.chem_buddy

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep the current resolution; a resolution switch can blank the display.
        // Android retains final control over refresh rate and battery policy.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val display = windowManager.defaultDisplay
                val current = display.mode
                val modes = display.supportedModes
                var maxRate = 60f
                var targetModeId = 0
                for (mode in modes) {
                    if (mode.physicalWidth == current.physicalWidth &&
                        mode.physicalHeight == current.physicalHeight &&
                        mode.refreshRate > maxRate) {
                        maxRate = mode.refreshRate
                        targetModeId = mode.modeId
                    }
                }
                if (targetModeId != 0) {
                    val params = window.attributes
                    if (Build.VERSION.SDK_INT >= 34) {
                        // A rate preference lets modern Android choose the mode.
                        params.preferredRefreshRate = maxRate
                    } else {
                        params.preferredDisplayModeId = targetModeId
                    }
                    window.attributes = params
                }
            } catch (_: Exception) {
                // Graceful fallback
            }
        }
    }
}
