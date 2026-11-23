  #!/bin/bash
  # tools/patch_android.sh
  # Idempotent patcher: adds INTERNET, RECORD_AUDIO, RUN_COMMAND permission,
  # queries for com.termux, and MainActivity.kt MethodChannel code.
  # Run this after flutter create, before flutter build.

  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  ANDROID_DIR="${SCRIPT_DIR}/../android"

  if [[ ! -d "$ANDROID_DIR" ]]; then
    echo "ERROR: android/ directory not found. Run: flutter create --platforms=android ."
    exit 1
  fi

  MANIFEST="$ANDROID_DIR/app/src/main/AndroidManifest.xml"
  MAINACTIVITY="$ANDROID_DIR/app/src/main/kotlin/com/aihub/ai_hub/MainActivity.kt"

  # ── 1. AndroidManifest.xml patches ──────────────────────────────
  if [[ -f "$MANIFEST" ]]; then
    echo "Patching AndroidManifest.xml..."

    # Add INTERNET permission if missing
    if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
      sed -i 's/<manifest/<manifest\n    <uses-permission android:name="android.permission.INTERNET"
    fi

    # Add RECORD_AUDIO permission if missing
    if ! grep -q "android.permission.RECORD_AUDIO" "$MANIFEST"; then
      sed -i 's/<manifest/<manifest\n    <uses-permission
  android:name="android.permission.RECORD_AUDIO" \/>/' "$MANIFEST"
    fi

    # Add com.termux.permission.RUN_COMMAND permission if missing
    if ! grep -q "com.termux.permission.RUN_COMMAND" "$MANIFEST"; then
      sed -i 's/<manifest/<manifest\n    <uses-permission
  android:name="com.termux.permission.RUN_COMMAND" \/>/' "$MANIFEST"
    fi

    # Add <queries> for com.termux if missing
    if ! grep -q "com.termux" "$MANIFEST"; then
      # Insert <queries> block right after <manifest ...> line
      QUERIES='<queries>
    <package android:name="com.termux" />
  </queries>'
      sed -i "0,/<manifest/ s//<manifest>\n    $QUERIES/" "$MANIFEST"
    fi
  fi

  # ── 2. MainActivity.kt patch ────────────────────────────────────
  if [[ -f "$MAINACTIVITY" ]]; then
    echo "Patching MainActivity.kt..."

    if ! grep -q "MethodChannel" "$MAINACTIVITY"; then
      # Replace entire file with method channel implementation
      cat > "$MAINACTIVITY" << 'EOF'
  package com.aihub.ai_hub

  import io.flutter.embedding.android.FlutterActivity
  import io.flutter.embedding.engine.FlutterEngine
  import io.flutter.plugin.common.MethodChannel
  import android.content.Intent
  import android.os.Build
  import com.termux.app.RunCommandService
  import com.termux.app.RunCommandService.ACTION_RUN_COMMAND

  class MainActivity: FlutterActivity() {
      private val CHANNEL = "com.aihub.ai_hub/termux"
      private lateinit var channel: MethodChannel

      override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
          super.configureFlutterEngine(flutterEngine)
          channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
          channel.setMethodCallHandler { call, result ->
              when (call.method) {
                  "startGateway" -> {
                      try {
                          val script = call.argument<String>("script") ?: "startgateway.sh"
                          val intent = Intent(RunCommandService.ACTION_RUN_COMMAND).apply {
                              component = android.content.ComponentName(
                                  "com.termux",
                                  "com.termux.app.RunCommandService"
                              )
                              putExtra(RunCommandService.EXTRA_COMMAND_PATH, script)
                              putExtra(RunCommandService.EXTRA_BACKGROUND, true)
                          }
                          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                              applicationContext.startForegroundService(intent)
                          } else {
                              applicationContext.startService(intent)
                          }
                          result.success(true)
                      } catch (e: Exception) {
                          result.error("TERMUX_ERROR", e.message, null)
                      }
                  }
                  else -> result.notImplemented()
              }
          }
      }
  }
  EOF
    fi
  fi

  echo "Done patching android/ project."
