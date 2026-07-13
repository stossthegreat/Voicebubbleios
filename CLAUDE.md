# VoiceBubble — project notes for Claude

## Versioning
- **ALWAYS bump the build number in `pubspec.yaml` on every change** before committing.
  The version is `MAJOR.MINOR.PATCH+BUILD` (e.g. `4.0.3+20`). Increment the `+BUILD`
  number every time; bump the patch/minor as appropriate for the size of the change.

## Sharing
- All outgoing "share text" actions go through `lib/services/share_service.dart`
  (`ShareService.shareText(context, text)`). Do not call `Share.share(...)` directly —
  the wrapper defers past menu/sheet dismissal (iOS won't present otherwise), supplies
  the iPad `sharePositionOrigin`, guards empty text, and surfaces errors.

## Rich text editor (flutter_quill)
- We're on `flutter_quill` 11.x. Its editor/toolbar read localized strings from
  `FlutterQuillLocalizations.delegate`, which is registered in `main.dart`'s
  `MaterialApp.localizationsDelegates` — do NOT remove it or the editor crashes
  on open. In 11.x `readOnly` lives on `QuillController` (not the editor config),
  `configurations:`→`config:` (`QuillEditorConfig`/`QuillSimpleToolbarConfig`),
  `EmbedBuilder.build` takes `(context, EmbedContext)`, and `DefaultTextBlockStyle`
  takes a leading `HorizontalSpacing` arg.

## Audio / transcription
- The recorder produces AAC/M4A (`recording_*.m4a`). When uploading to the Whisper
  endpoint the multipart filename MUST keep the real extension (`.m4a`) — Whisper picks
  its decoder from the extension, and a wrong extension causes a 400 that surfaces as a
  bogus "cannot connect" error.
