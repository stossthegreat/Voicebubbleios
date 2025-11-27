package com.voicebubble.app

// IMPORTANT POLICY COMPLIANCE:
// This service ONLY shows a floating bubble overlay using TYPE_APPLICATION_OVERLAY.
// It does NOT use Accessibility APIs.
// It does NOT read screen content from other apps.
// It does NOT automatically insert text into other apps.
// It does NOT simulate user input or clicks.
// 
// User interaction flow:
// 1. User manually taps the floating bubble
// 2. App opens to record voice
// 3. User manually copies/shares the rewritten text
//
// This implementation complies with Google Play Store policies by:
// - Using ONLY SYSTEM_ALERT_WINDOW permission for the overlay
// - Using ONLY RECORD_AUDIO permission for voice recording
// - NOT requesting or using any Accessibility permissions
// - NOT reading or modifying content from other applications
// - Requiring explicit user interaction for all actions

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity

class OverlayService : Service() {
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isOverlayVisible = false
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "VoiceBubbleOverlay"
        
        fun start(context: Context) {
            val intent = Intent(context, OverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stop(context: Context) {
            val intent = Intent(context, OverlayService::class.java)
            context.stopService(intent)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Create notification channel
        createNotificationChannel()
        
        // Start foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Initialize window manager
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        // Create and show overlay
        createOverlay()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Voice Bubble",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the floating bubble active so you can quickly record and rewrite messages"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Voice Bubble Active")
            .setContentText("Floating bubble ready for quick voice recording")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    private fun createOverlay() {
        try {
            // Create overlay view
            overlayView = createBubbleView()
            
            // Set up window parameters
            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.TOP or Gravity.END
            params.x = 16
            params.y = 200
            
            // Add view to window manager
            windowManager?.addView(overlayView, params)
            isOverlayVisible = true
            
            // Set up touch listener for dragging
            setupDragListener(params)
        } catch (e: Exception) {
            e.printStackTrace()
            // If overlay creation fails, stop the service
            stopSelf()
        }
    }
    
    private fun createBubbleView(): View {
        // Create a simple bubble view programmatically
        return ImageView(this).apply {
            try {
                setImageResource(android.R.drawable.ic_btn_speak_now)
                setPadding(32, 32, 32, 32)
                setBackgroundResource(android.R.drawable.btn_default)
                
                setOnClickListener {
                    try {
                        // Open main app when bubble is clicked
                        val intent = Intent(this@OverlayService, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            putExtra("open_recording", true)
                        }
                        startActivity(intent)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    private fun setupDragListener(params: WindowManager.LayoutParams) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isMoved = false
        
        overlayView?.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isMoved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = Math.abs(event.rawX - initialTouchX)
                    val deltaY = Math.abs(event.rawY - initialTouchY)
                    
                    if (deltaX > 10 || deltaY > 10) {
                        isMoved = true
                        params.x = initialX + (initialTouchX - event.rawX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        try {
                            windowManager?.updateViewLayout(overlayView, params)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isMoved) {
                        // It was a click, not a drag
                        view.performClick()
                    }
                    false
                }
                else -> false
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Remove overlay view
        try {
            if (overlayView != null && isOverlayVisible) {
                windowManager?.removeView(overlayView)
                overlayView = null
                isOverlayVisible = false
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}

