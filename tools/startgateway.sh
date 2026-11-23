  #!/bin/bash
  # tools/startgateway.sh
  # Termux script: starts FreeLLMAPI gateway if not already running.
  # Run this from com.termux.app.RunCommandService.
  # Logs go to ~/gateway.log

  LOG=~/gateway.log
  GATEWAY_DIR=~/freellmapi

  echo "[$(date)] startgateway.sh invoked" >> "$LOG"

  # Acquire wake lock so the phone doesn't sleep while starting.
  if command -v termux-wake-lock >/dev/null 2>&1; then
      termux-wake-lock >> "$LOG" 2>&1 || true
  fi

  # Check if gateway is already responding on port 3001.
  if curl -s http://localhost:3001/ >/dev/null 2>&1; then
      echo "[$(date)] Gateway already running." >> "$LOG"
      exit 0
  fi

  # If not running, start it from ~/freellmapi with nohup "npm run dev".
  if [[ -d "$GATEWAY_DIR" ]]; then
      echo "[$(date)] Starting gateway from $GATEWAY_DIR ..." >> "$LOG"
      cd "$GATEWAY_DIR"
      nohup npm run dev >> "$LOG" 2>&1 &
      echo $! > ~/gateway.pid
      echo "[$(date)] Gateway started with PID $(cat ~/gateway.pid)." >> "$LOG"
  else
      echo "[$(date)] Gateway directory $GATEWAY_DIR not found. Skipping." >> "$LOG"
  fi
