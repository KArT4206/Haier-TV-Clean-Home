# Context prompt for ChatGPT: Haier Google TV debloat + custom launcher (SRS)

Paste everything below this line into ChatGPT.

---

You are helping me with an ongoing project. Below is a Software Requirements Specification (SRS) that describes what has already been done and how the system is set up. Read it fully, then help me with follow-up questions, changes or troubleshooting. Stay within the constraints in section 6.

## 1. Introduction

### 1.1 Purpose
I am debloating a Google TV and replacing its home screen with a clean, Apple TV-style launcher. The work is done from a Mac over ADB (Android Debug Bridge) on the local Wi-Fi network. Every change has to be reversible.

### 1.2 Scope
- **In scope:** turning off manufacturer bloat and telemetry, a custom home-screen launcher, an ad-blocking DNS, an ad-free YouTube client, small speed tweaks, a Bluetooth shortcut button on the home screen, and backup, restore and documentation.
- **Out of scope:** rooting, flashing firmware, uninstalling system apps, and anything that cannot be undone.

### 1.3 Definitions
- **ADB:** Android Debug Bridge, a command-line tool to control an Android device from a computer.
- **Wireless debugging:** Android's ADB over Wi-Fi with TLS and a pairing code. On this TV it gets a new random port each time it starts.
- **Port 5555:** classic plaintext network ADB, opened with `adb tcpip 5555`. It closes on reboot.
- **Disable (pm disable-user):** turns an app off for user 0 without removing it. `pm enable` undoes it.
- **Launcher / Home:** the app that the Home button opens.
- **setupwraith:** `com.google.android.tungsten.setupwraith`, Google TV's setup wizard. It also claims the Home button.
- **launcherx:** `com.google.android.apps.tv.launcherx`, the stock Google TV home screen.

### 1.4 Base project
I use the open-source repo **github.com/Gathin23/cleanyourtv** (cloned locally). It provides:
- `PROMPT.md`: the step-by-step procedure and safety rules.
- `tools/`: `tv.py` (ADB client and screenshots), `disable.sh` and `restore.sh` (batch disable and re-enable with safety checks), `adb-closed.py` (checks whether ADB ports are really closed), `b64push.py` (reliable file push).
- `launcher/`: a small native Android TV launcher (`com.gathin.tvhome`: Java, AndroidX RecyclerView, minSdk 26, no internet permission), configured through `launcher/app/src/main/res/values/config.xml`.
- `examples/haier-matrixtv-de/`: a tested debloat list for my exact TV model.

## 2. Overall description

### 2.1 Device
- **TV:** Haier MatrixTV DE (product HR9676EUF, device "omonia")
- **OS:** Google TV 14 (Android 14, API 34), firmware UKN2.241219.053
- **Hardware:** MediaTek mt5896, 32-bit userspace (armeabi-v7a), about 1.8 GB RAM, 4K panel with the UI at 1080p
- **Network:** Wi-Fi only. Nothing is plugged into the USB ports.
- **Board family:** CVTE/MediaTek. Factory packages exist and must never be opened.

### 2.2 Users
- A household that watches YouTube, Netflix, JioHotstar, Prime Video, JioCinema, Spotify, SonyLIV, Zee5 and YouTube Music.
- They want to keep the Google Assistant, Miracast, the Ambient screensaver and firmware updates.

### 2.3 Operating environment
- **Mac (macOS)** with Android SDK platform-tools (`adb`), build-tools 34, SDK platform 34 and JDK 21 (JetBrains Runtime).
- **Python venv** at `tools/venv` for the repo's tools.
- **Connection:** pair through Wireless debugging (pairing code), then `adb tcpip 5555`, then use `192.168.1.x:5555`. "Revoke USB debugging authorisations" also removes the wireless pairing, so a new code is needed after it.

## 3. Functional requirements (all done unless marked)

### FR-1 Backup before any change ✅
Saved before the first change: the package list, disabled-package list, `getprop`, all `settings` (global, secure, system), the `wm size` and `wm density` values, and the Home resolver. Folder: `backup/<timestamp>/`.

### FR-2 Debloat (disable, never uninstall) ✅
Done in two small batches, with a screenshot after each. 13 packages disabled:
- **Haier content:** `it.hon.service` (hOn IoT), `com.haier.apps`, `com.haier.tvhousekeeper` (cleaner), `com.haier.emanual9603`, `com.haier.oemtabprovider` (Haier tab), `com.haier.launcher.haiermatrix` (Zeasn content launcher).
- **Telemetry, ads and preloads:** `com.google.android.feedback`, `tv.anoki.acr.controller` (ACR, which recognises what is on screen), `com.mediatek.tv.launcher.partner` (partner rows), `com.mediatek.tv.retaildemo`, `com.google.android.play.games`, `com.haier.overseastv.bluetoothspeaker`, `com.google.android.marvin.talkback`.
- Later, for the launcher: `com.google.android.tungsten.setupwraith` and `com.google.android.apps.tv.launcherx`.
- **Kept on purpose:** all streaming apps, Assistant (katniss), Miracast, Ambient (dreamx), the system updater, the Play Store and Play Services, the TV input and tuner services, and remote pairing.
- I checked after a reboot that the disabled state persisted.

### FR-3 Ad-blocking DNS ✅
Private DNS is set to `dns.adguard-dns.com` (`private_dns_mode hostname`). It blocks ad and tracker domains for all apps, but not YouTube ads. Undo: `settings put global private_dns_mode opportunistic`.

### FR-4 Custom home screen (Apple TV style) ✅
- Built from the repo's launcher and installed as the default Home.
- **Design:** dark background, a dock band with 6 slots, the other apps in a 6-column grid below, a greeting, a large clock and the date at top left, and frosted pill buttons at top right.
- **Dock order:** SmartTube, Netflix, JioHotstar, Prime Video, JioCinema, Spotify.
- **Config changes in `config.xml`:** `dock_apps`, `columns`=6, `live_tv_package`=`com.mediatek.tv.oneworld.tvcenter`, `animations`=false (this TV lags with launcher animations).
- **Taking over Home:** disabling launcherx alone was not enough, because setupwraith took Home. setupwraith also had to be disabled. Before that, the Wi-Fi network was forgotten and re-joined so that Android, not setupwraith, owns it. Otherwise Android deletes the network when setupwraith is disabled.
- **Known trade-off:** disabling setupwraith breaks Chromecast casting from phones. The user accepted this.
- **Verified:** `dumpsys activity activities` shows `com.gathin.tvhome/.MainActivity` as the resumed activity after pressing Home.

### FR-5 Ad-free YouTube ✅
- YouTube ads come from YouTube's own servers, so DNS cannot block them.
- Installed **SmartTube** (`org.smarttube.stable` 32.80, armeabi-v7a) from the official GitHub releases (yuliskov/SmartTube). The signing certificate was verified with `apksigner` before install.
- Installed via base64 push and `pm install -r`, because `adb install` can hang on Android 14.
- It replaced YouTube in the dock. The original YouTube app is still installed.

### FR-6 Performance tweaks ✅
- System animation scales (window, transition and animator) went from 1.0 to 0.5.
- Launcher animations are off.
- The slowness was mostly in the first minutes after boot (app compilation). Once settled the CPU was mostly idle, with about 700 MB RAM available.

### FR-7 Bluetooth shortcut on the home screen ✅ (local code change)
- **Requirement:** a "Bluetooth" pill in the top bar, styled like Inputs, Wi-Fi and Settings, that opens Remotes & Accessories pairing directly.
- **Constraint found:** every Bluetooth and accessories screen in TV Settings (`com.android.tv.settings`, for example `.accessories.AddAccessoryActivity`) requires the `android.permission.BLUETOOTH_CONNECT` permission. The stock launcher has none, so it got "Not available on this TV".
- **Solution (my own modified copy, not sent to the original project):**
  - `AndroidManifest.xml`: added `<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />`.
  - `res/layout/activity_main.xml`: a new `TextView` `@+id/btnBluetooth` with `style="@style/TopButton"`, placed after `btnWifi`.
  - `res/drawable/ic_bluetooth.xml`: a Material Bluetooth vector icon.
  - `res/values/bluetooth_pill.xml`: string `bluetooth_pill` = "Bluetooth".
  - `MainActivity.java`: the click opens `new Intent("com.google.android.intent.action.CONNECT_INPUT").setPackage("com.android.tv.settings")`, and the pill reuses the top bar's D-pad key handler.
  - Granted at runtime with `pm grant com.gathin.tvhome android.permission.BLUETOOTH_CONNECT`.
- **Verified:** pressing the pill makes `AddAccessoryActivity` the resumed activity.

### FR-8 Close ADB afterwards ✅
- Wireless debugging is switched off (`settings put global adb_wifi_enabled 0`), then the TV reboots.
- `tools/adb-closed.py <tv ip>` must report port 5555 "closed: the TV refused the connection".
- USB debugging is switched off by hand in Developer options.

### FR-9 Documentation and restore ✅
- `work/my-debloat.txt`: what was disabled.
- `work/restore.sh`: re-enables everything and resets DNS.
- `work/README.md`: how to reconnect ADB, undo each change, change the dock and wallpaper, and which files the Bluetooth pill changed.
- `shots/`: screenshots taken from the TV for verification.

## 4. Non-functional requirements
- **NFR-1 Reversibility:** every change can be undone with `pm enable`, `restore.sh` or a settings reset. Nothing is uninstalled except the optional SmartTube, which was added.
- **NFR-2 Safety:** never disable Android core packages (permission controller, package installer, providers, systemui, shell, settings, `com.android.tv.settings`), TV middleware (`com.cltv.mal`, `com.mediatek.tis`, `com.mediatek.tv.service`, `com.mediatek.tv.agent`), input and tuner services, remote pairing, or the keyboard. Never open factory packages (`com.haier.hkcfac`, `com.cvte.tv.at`, `mediatek.factorymenu.ui`, `com.at.factory.*`), not even to look.
- **NFR-3 Lightweight launcher:** for about 1–2 GB RAM. No blur, no video, no network polling, and no internet permission.
- **NFR-4 Verification:** every change is checked with screenshots pulled from the TV, or with `dumpsys`, not assumed.
- **NFR-5 Security:** ADB is closed when work ends, because port 5555 is plaintext and anyone on the LAN could get a shell through it.
- **NFR-6 Privacy:** no IPs, Wi-Fi names, serials or account details go into anything shared publicly.

## 5. Known issues and quirks of this TV
- Port 5555 is closed on every boot. Each session needs Wireless debugging, and a new pairing code if authorisations were revoked.
- `com.netflix.ninja` is re-enabled by the firmware at every boot, so it is kept.
- The remote's gear button sends keycode 83 (`KEYCODE_NOTIFICATION`). It does nothing once launcherx is disabled. Settings opens from the launcher's top bar instead.
- Voice search for songs or videos may say "Google Assistant is having trouble" with launcherx disabled.
- The remote's power button is only a light sleep. `input keyevent 26` over ADB can drop the TV off the network.
- Load average reads about 20+ even when idle. That is normal on this MediaTek kernel; check `top` for the real CPU use.

## 6. Constraints for any help you give
- Use `pm disable-user --user 0` only, one package per command. Never `pm uninstall` a system package, never root, never flash.
- Before disabling anything unclear, inspect it with `dumpsys package <name>`. Never launch it.
- Before disabling setupwraith, check that it doesn't own the saved Wi-Fi network.
- Keep the launcher with no internet permission and lightweight.
- Any change to the launcher's code is my own local fork. Keep it minimal and list every file changed.

## 7. What I may ask you next
- Changing the dock order, the number of columns, the wallpaper or a theme (`config.xml` / theme `config.json`).
- Mapping remote buttons (for example the gear button) through the launcher's key helper settings.
- Diagnosing slowness or apps that come back after a reboot.
- Restoring casting (re-enable setupwraith; Home would then need re-checking).
- Explaining any of the above step by step.
