  # AI Hub

  > Chat with many free AI models from one place — through a local FreeLLMAPI gateway running in
  Termux on the same phone.

  ## What is AI Hub?

  AI Hub is a standalone Android app (Flutter, Dart) that talks to a **FreeLLMAPI** gateway. The
  gateway runs inside **Termux** on your phone and exposes an OpenAI-compatible API at
  `http://localhost:3001/v1`. You open only this app, see only the chat screen, and the app starts
  the gateway in the background by itself.

  ## Features

  - Claude-style chat UI with glass (iOS-style) design
  - Streaming replies (SSE), stop, regenerate, copy
  - Markdown rendering with code blocks (monospace, scroll, copy)
  - Animated typing indicator, shimmer loaders, haptics
  - Model selector with search (bottom sheet)
  - Local chat history (sqflite): search, rename, delete, pin
  - Voice input (speech_to_text) and read-aloud (flutter_tts)
  - 8+ color theme presets + custom color picker
  - Gateway status pill + auto-start in Termux
  - One-time setup help screen

  ## How to build

  The APK is built by GitHub Actions. You do **not** need Flutter installed.

  1. Push your code to GitHub (branch `main` or `master`).
  2. Go to the **Actions** tab of your repository.
  3. Find the workflow named "Build AI Hub APK" and run it.
  4. After it succeeds, download the APK from the **Artifacts** section.

  ## One-time Termux setup (do this once on your phone)

  1. Install **Termux** from F-Droid: https://f-droid.org/packages/com.termux
  2. Open Termux and run:
     ```bash
     pkg install nodejs npm
  3. Clone/download your FreeLLMAPI gateway into ~/freellmapi and run npm install there.
  4. Copy tools/startgateway.sh from this repo to ~/ in Termux and make it executable:
  chmod +x ~/startgateway.sh
  5. Set allow-external-apps = true in ~/.termux/termux.properties (create the file if it does not
     exist).
  6. In Android settings, grant AI Hub the permission "Run commands in Termux environment".
  7. Open AI Hub, go to Settings, enter your API key (starts with freellmapi-), and tap Test
     connection.

  App constants

  The app name is defined in lib/core/constants/app_constants.dart as kAppName = 'AI Hub'. Change
  that one constant to rename the app everywhere.

  License

  © 2026 AI Hub
