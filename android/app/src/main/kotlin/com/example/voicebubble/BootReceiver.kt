package com.example.voicebubble

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

/**
 * Receives BOOT_COMPLETED broadcast and restarts the overlay service
 * if it was enabled before the reboot
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
        private const val PREFS_NAME = "VoiceBubblePrefs"
        private const val KEY_OVERLAY_ENABLED = "overlay_enabled"
        
        /**
         * Save overlay enabled state
         */
        fun setOverlayEnabled(context: Context, enabled: Boolean) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_OVERLAY_ENABLED, enabled).apply()
            Log.d(TAG, "Overlay enabled state saved: $enabled")
        }
        
        /**
         * Get overlay enabled state
         */
        fun isOverlayEnabled(context: Context): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getBoolean(KEY_OVERLAY_ENABLED, false)
        }
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "📱 BOOT_COMPLETED received")
            
            context?.let {
                // Check if overlay was enabled before reboot
                if (isOverlayEnabled(it)) {
                    Log.d(TAG, "🚀 Overlay was enabled, restarting service...")
                    
                    // Small delay to ensure system is ready
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        try {
                            OverlayService.start(it)
                            Log.d(TAG, "✅ OverlayService restarted after boot")
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Error restarting overlay service after boot", e)
                        }
                    }, 3000) // 3 second delay
                } else {
                    Log.d(TAG, "Overlay was not enabled, skipping auto-start")
                }
            }
        }
    }
}

