# DevSphere

> Version 10-26 · a small Flutter app with a first-run setup flow.

DevSphere remembers who you are. On first launch it shows a short setup form
asking for your name; every launch after that greets you with **`Hi {name}`**.
A **Sign out** action clears your saved config so you can start fresh.

It runs on Linux, the web, Windows, macOS, Android, and iOS from a single
codebase.

---

## Features

- **First-run setup** — a simple form captures your name.
- **Remembers you** — your name is persisted locally (via `shared_preferences`),
  so subsequent launches skip setup and go straight to the greeting.
- **Sign out** — clears the stored config and returns you to setup.
- **Jira connection check (zero token)** — rides your local **Claude CLI**:
  DevSphere shells out to `claude`, which calls the Atlassian `atlassianUserInfo`
  MCP tool and returns your connected account. No Jira token is stored or entered.
- **Google connection check (zero token)** — same pattern: `claude` uses your
  Google connector (Calendar/Gmail) to report the signed-in account.
- **Cross-platform** — the app builds for desktop, web, and mobile.

> **How the connection checks work:** DevSphere never holds Jira/Google tokens.
> It asks your authenticated `claude` CLI to make the call through its MCP
> connectors and parses the JSON result — the same approach as the earlier
> dev-dashboard app. This means the checks are **desktop-only** (they need the
> `claude` CLI installed and signed in) and do **not** run in the web build.

---

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47+ (Dart 3.13+).
- For the connection checks: [Claude Code](https://claude.com/claude-code) (the
  `claude` CLI) installed, signed in, and on your `PATH`, with the Atlassian /
  Google MCP connectors authorized. Without it the app still runs — only the
  Jira/Google checks report "not connected".

Check your setup with:

```bash
flutter doctor
```

---

## Run it (development)

```bash
flutter pub get
flutter run -d linux     # or: -d chrome, -d windows, -d macos, or a device id
```

Hot-reload keys while running: `r` reload · `R` restart · `q` quit.

Run the tests:

```bash
flutter test
```

---

## Install as a native Linux app

Install (or update) DevSphere into your apps menu — no sudo required, everything
lives under `~/.local`:

```bash
./install.sh
```

Then open your apps launcher and search **DevSphere**. To remove it:

```bash
./install.sh --uninstall
```

The script builds a release bundle, copies it to `~/.local/lib/devsphere`,
installs the icon, and writes a `.desktop` launcher entry. Re-run `./install.sh`
any time after changing the code to update the installed copy.

---

## Deploy to the cloud (web)

The web build is a plain static site, so anyone can open it in a browser — no
install needed.

### GitHub Pages (one command)

This repo ships `deploy-web.sh`, which builds the web app and publishes it to the
`gh-pages` branch that GitHub Pages serves:

```bash
./deploy-web.sh
```

Live at **https://mauricesimpro.github.io/DevSphere/** once Pages is enabled
(Settings → Pages → Source: *Deploy from a branch* → `gh-pages` / `root`).
Re-run `./deploy-web.sh` any time to publish the latest build. If you fork/rename
the repo, pass a matching base href: `./deploy-web.sh /your-repo-name/`.

### Any other static host (Netlify / Vercel / S3 / …)

```bash
flutter build web --release
```

Point the host at `build/web/` (or set build command `flutter build web
--release`, publish directory `build/web`). Drag-and-dropping `build/web/` onto
Netlify Drop works too.

### Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init hosting      # set the public directory to: build/web
flutter build web --release
firebase deploy
```

> On the web, the saved name lives in the browser's local storage, so each
> browser/profile remembers its own setup. **Sign out** clears it.

---

## Other platforms

```bash
flutter build apk          # Android
flutter build appbundle    # Android (Play Store)
flutter build windows      # Windows
flutter build macos        # macOS
flutter build ipa          # iOS (requires macOS + Xcode)
```

---

## Project structure

```
lib/
  main.dart                     App entry; routes to setup vs. welcome
  services/
    app_config.dart             Load / save / reset the saved name
    claude_cli_service.dart     Shells out to the `claude` CLI, parses JSON
    jira_service.dart           Jira check via atlassianUserInfo (no token)
    google_auth_service.dart    Google check via Calendar/Gmail (no token)
  screens/
    setup_screen.dart           First-run form
    welcome_screen.dart         "Hi {name}" dashboard + Sign out
    connection_check_screen.dart  Runs a check, shows account or error
resources/
  devsphere.svg                 App icon
install.sh                      Build + install (or --uninstall) on Linux
deploy-web.sh                   Build web + publish to GitHub Pages (gh-pages)
test/
  widget_test.dart              Widget tests for the setup/welcome flow
```

---

## Persistence & secrets

Only one, non-secret thing is persisted: your **name**, via
[`shared_preferences`](https://pub.dev/packages/shared_preferences) (a config
file on Linux desktop, `localStorage` on web). `AppConfig` is the single place
that reads/writes it — `setName()` on setup, `reset()` on sign out.

**No Jira or Google tokens are ever stored, entered, or handled by DevSphere.**
The connection checks delegate entirely to your `claude` CLI, which owns its own
MCP connector auth. That keeps credentials out of the app completely.
