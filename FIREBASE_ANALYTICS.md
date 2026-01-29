# Firebase Analytics Integration

## Overview
Firebase Analytics is integrated to track user behavior, feature usage, and app performance.

## Setup Complete ✅

### 1. Dependencies Added
- `firebase_analytics: ^11.3.3` added to `pubspec.yaml`
- Already have `firebase_core: ^3.8.1`

### 2. Service Created
- `lib/services/analytics_service.dart` - Centralized analytics service
- Singleton pattern for easy access
- Strongly-typed event methods

### 3. Initialization
- Analytics initialized in `main.dart`
- Navigator observer added to track screen views automatically

## Key Events Tracked

### Recording Events
- `recording_started` - User starts voice recording
- `recording_completed` - Recording finished (duration, preset, language)
- `audio_file_uploaded` - Audio file uploaded (duration, type)

### AI Preset Events
- `preset_selected` - User selects a preset
- `preset_favorited` - User favorites/unfavorites a preset

### AI Output Events
- `output_generated` - AI generates output (length, time, quality score)
- `output_edited` - User manually edits output
- `output_shared` - User shares output
- `refinement_used` - User applies refinement (shorten, expand, etc.)
- `instructions_added` - User adds voice instructions
- `output_regenerated` - User regenerates output

### Outcome Events
- `outcome_assigned` - User assigns outcome type
- `outcome_completed` - User marks outcome as done
- `reminder_set` - User sets reminder

### Project Events
- `project_created` - New project created
- `project_opened` - Project opened
- `item_added_to_project` - Item added to project
- `continue_from_project` - Continue from project
- `continue_from_item` - Continue from single item

### Smart Actions Events
- `smart_actions_used` - Smart Actions preset used
- `smart_action_exported` - Action exported to external app

### Subscription Events
- `paywall_viewed` - Paywall screen shown
- `subscription_purchased` - User subscribes (product ID, price)
- `subscription_cancelled` - Subscription cancelled
- `usage_limit_hit` - User hits usage limit

### Navigation Events
- Screen views tracked automatically via observer
- `tab_selected` - User switches tabs

### Language & Settings
- `language_changed` - User changes language
- `language_favorited` - User favorites language
- `overlay_activated` - User enables/disables overlay

### Error Tracking
- `error_occurred` - Any error (type, message, context)

## Usage Example

```dart
import '../services/analytics_service.dart';

// Track recording completion
await AnalyticsService().logRecordingCompleted(
  durationSeconds: 30,
  presetId: 'magic',
  language: 'en',
);

// Track preset selection
await AnalyticsService().logPresetSelected(
  presetId: 'email_professional',
  presetName: 'Email Professional',
);

// Track share
await AnalyticsService().logOutputShared(
  presetId: 'magic',
  shareMethod: 'system_share_sheet',
);

// Track custom event
await AnalyticsService().logCustomEvent(
  eventName: 'special_feature_used',
  parameters: {'feature': 'cool_thing'},
);
```

## Next Steps (To Implement Later)

### Add Analytics Calls Throughout App:
1. **home_screen.dart**
   - Log recording started/completed
   - Log audio file uploaded
   - Log overlay activated

2. **preset_selection_screen.dart**
   - Log preset selected
   - Log preset favorited

3. **result_screen.dart**
   - Log output generated
   - Log output edited
   - Log refinement used
   - Log instructions added
   - Log output regenerated
   - Log output shared
   - Log outcome assigned

4. **main_navigation.dart**
   - Log tab selected

5. **smart_actions_result_screen.dart**
   - Log smart actions used
   - Log smart action exported

6. **project screens**
   - Log project created/opened
   - Log continue events

7. **paywall_screen.dart**
   - Log paywall viewed
   - Log subscription purchased

8. **language_selector_popup.dart**
   - Log language changed
   - Log language favorited

### Configure Firebase Console:
1. Go to Firebase Console
2. Add your Android app (package name: `com.yourdomain.voicebubble`)
3. Download `google-services.json`
4. Place in `android/app/google-services.json`
5. Update `android/build.gradle` to include Firebase plugin

## Privacy
- Analytics respects user privacy
- No personally identifiable information (PII) logged
- User IDs are anonymized
- Complies with App Store guidelines

## Testing
- Events visible in Firebase Console (DebugView)
- 24-48 hour delay for production analytics
- Use DebugView for real-time testing

## Benefits
- Understand which features users love
- Track conversion from free to paid
- Identify pain points (errors, limit hits)
- Optimize onboarding flow
- A/B test features
- Monitor app health
