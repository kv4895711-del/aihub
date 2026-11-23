 #!/bin/bash
  # tools/patch_android.sh
  # Safe to run many times. Adds permissions + <queries> to AndroidManifest.xml
  # and writes a MainActivity.kt with the Termux RUN_COMMAND MethodChannel.
  # Run after "flutter create", before "flutter build apk".

  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  ANDROID_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/android"

  if [[ ! -d "$ANDROID_DIR" ]]; then
    echo "ERROR: android/ folder not found. Run: flutter create --platforms=android ."
    exit 1
  fi

  MANIFEST="$ANDROID_DIR/app/src/main/AndroidManifest.xml"
  KOTLIN_DIR="$ANDROID_DIR/app/src/main/kotlin/com/aihub/ai_hub"
  MAINACTIVITY="$KOTLIN_DIR/MainActivity.kt"

  if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: AndroidManifest.xml not found at $MANIFEST"
    exit 1
  fi

  # ── 1. Patch AndroidManifest.xml with python3 (idempotent) ─────────
  echo "==> Patching AndroidManifest.xml"
  python3 - "$MANIFEST" << 'PYEOF'
  import sys, re

  path = sys.argv[1]
  with open(path, "r", encoding="utf-8") as f:
      xml = f.read()

  perms = [
      'android.permission.INTERNET',
      'android.permission.RECORD_AUDIO',
      'android.permission.POST_NOTIFICATIONS',
      'com.termux.permission.RUN_COMMAND',
  ]

  needed = [p for p in perms if p not in xml]
  if needed:
      lines = "".join(
          '    <uses-permission android:name="%s" />\n' % p for p in needed
      )
      # Put permissions right after the opening <manifest ...> tag.
      xml = re.sub(r'(<manifest\b[^>]*>\s*\n)', r'\1' + lines, xml, count=1)
          '        <package android:name="com.termux" />\n'
          '    </queries>\n'
      )
      # <queries> must be a direct child of <manifest>.
      xml = re.sub(r'(<manifest\b[^>]*>\s*\n)', r'\1' + queries, xml, count=1)
      print("    added <queries> for com.termux")
  else:
      print("    <queries> already present")

  with open(path, "w", encoding="utf-8") as f:
      f.write(xml)
  PYEOF

  # ── 2. Write MainActivity.kt with Termux MethodChannel ────────────
  echo "==> Writing MainActivity.kt"
  mkdir -p "$KOTLIN_DIR"

  cat > "$MAINACTIVITY" << 'KOTEOF'
  package com.aihub.ai_hub

  import android.content.ComponentName
  import android.content.Intent
  import android.os.Build
  import io.flutter.embedding.android.FlutterActivity
  import io.flutter.embedding.engine.FlutterEngine
  import io.flutter.plugin.common.MethodChannel

  class MainActivity : FlutterActivity() {

      private val channelName = "com.aihub.ai_hub/termux"

      // Official Termux RUN_COMMAND API constants (strings, not imports).
      private val termuxPackage = "com.termux"
      private val runCommandService = "com.termux.app.RunCommandService"
      private val actionRunCommand = "com.termux.RUN_COMMAND"
      private val extraCommandPath = "com.termux.RUN_COMMAND_PATH"
      private val extraArguments = "com.termux.RUN_COMMAND_ARGUMENTS"
      private val extraWorkdir = "com.termux.RUN_COMMAND_WORKDIR"
      private val extraBackground = "com.termux.RUN_COMMAND_BACKGROUND"
      private val extraSessionAction = "com.termux.RUN_COMMAND_SESSION_ACTION"

      override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
          super.configureFlutterEngine(flutterEngine)
          MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
              .setMethodCallHandler { call, result ->
                  if (call.method == "startGateway") {
                      val path = call.argument<String>("path") ?: "~/startgateway.sh"
                      val args = call.argument<List<String>>("args") ?: emptyList()
                      val workdir = call.argument<String>("workdir") ?: "~"
                      try {
                          val intent = Intent().apply {
                              setComponent(ComponentName(termuxPackage, runCommandService))
                              action = actionRunCommand
                              putExtra(extraCommandPath, path)
                              putExtra(extraArguments, args.toTypedArray())
                              putExtra(extraWorkdir, workdir)
                              putExtra(extraBackground, true)
                              putExtra(extraSessionAction, "0")
                          }
                          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                              startForegroundService(intent)
                          } else {
                              startService(intent)
                          }
                          result.success(true)
                      } catch (e: Exception) {
                          result.error("TERMUX_ERROR", e.message, null)
                      }
                  } else {
                      result.notImplemented()
                  }
              }
      }
  }
  KOTEOF

  echo "==> Done. Android project patched."
