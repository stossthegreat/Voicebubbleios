# Document Continuation Bug Fix

## Issue
When pressing the mic button on a document in the Library tab, the continue functionality 
doesn't append to the same document. It used to work but broke.

## Root Cause
In `lib/screens/main/result_screen.dart`, the `_updateOriginalCard()` method uses 
`appState.recordingItems` to find the original document. However, `recordingItems` 
**filters out** items with `hiddenInLibrary: true` (outcome items).

When the user continues from an outcome document, the code can't find it because 
it's filtered out!

## Fix Location
File: `lib/screens/main/result_screen.dart`
Method: `_updateOriginalCard()`

## Change Required

### BEFORE (broken):
```dart
Future<void> _updateOriginalCard(String originalItemId) async {
  try {
    final appState = context.read<AppStateProvider>();
    
    // Find the original item - THIS FILTERS OUT OUTCOME ITEMS!
    final originalItem = appState.recordingItems.firstWhere(
      (item) => item.id == originalItemId,
      orElse: () => throw Exception('Original item not found'),
    );
```

### AFTER (fixed):
```dart
Future<void> _updateOriginalCard(String originalItemId) async {
  try {
    final appState = context.read<AppStateProvider>();
    
    // Find the original item - USE allRecordingItems to include outcome items!
    final originalItem = appState.allRecordingItems.firstWhere(
      (item) => item.id == originalItemId,
      orElse: () => throw Exception('Original item not found'),
    );
```

## Also check _saveRecording()

There's similar code in `_saveRecording()` that also needs to use `allRecordingItems`:

### BEFORE:
```dart
final originalItem = appState.recordingItems.firstWhere(
  (item) => item.id == originalItemId,
  orElse: () => appState.recordingItems.first,
);
```

### AFTER:
```dart
final originalItem = appState.allRecordingItems.firstWhere(
  (item) => item.id == originalItemId,
  orElse: () => appState.allRecordingItems.first,
);
```

## Summary
Search for all instances of `appState.recordingItems` in result_screen.dart and 
change them to `appState.allRecordingItems` when looking for items by ID.
