# My TV: Haier MatrixTV DE cleanup (2026-11-24)

## What changed
- 13 packages disabled (not uninstalled), listed in `work/my-debloat.txt`: Haier content and promo apps, the hOn IoT service, the cleaner, the e-manual, the Haier tab, the Zeasn launcher, Google feedback, Anoki ACR (screen recognition), partner rows, retail demo, Play Games, the Bluetooth-speaker mode and TalkBack.
- Private DNS is set to `dns.adguard-dns.com`, which blocks ad and tracker domains. It does not block YouTube ads.
- Kept by choice: Netflix, Prime Video, YouTube Music, Assistant, Chromecast, Miracast, Ambient, the system updater, and the Google TV home. The clean launcher was skipped because on this set it would break casting.
- Backup of the TV before any change: `backup/20261124-1405/`.

## Reconnect ADB (needed for any change)
On the TV: Developer options -> Wireless debugging -> Pair device with pairing code. Then:
    adb pair <tv ip>:<pair port> <code>
    adb connect <tv ip>:<port shown on the Wireless debugging screen>
    adb tcpip 5555

## Undo
- Everything: `TV_HOST=<tv ip> work/restore.sh`
- One app: `adb shell pm enable <package>`
- DNS only: `adb shell settings put global private_dns_mode opportunistic`, or on the TV: Settings -> Network -> Private DNS -> Automatic.

## Dock order / wallpaper
These apply only if you install the clean launcher later (`launcher/build-and-install.sh`, which disables setupwraith and costs casting). Set `dock_apps` (YouTube, Netflix, Hotstar, Prime, JioCinema, Spotify) and `columns` in `launcher/app/src/main/res/values/config.xml` or a theme's `config.json`. Put the wallpaper in the theme folder and run `tools/theme.sh <folder>`. See `docs/launcher.md`.

## Added later (same day)
- **New home screen** (`com.gathin.tvhome`): Apple TV-style, with a dock of SmartTube, Netflix, JioHotstar, Prime Video, JioCinema and Spotify. The stock Google TV home (`com.google.android.apps.tv.launcherx`) and `com.google.android.tungsten.setupwraith` are disabled, so **casting from your phone is off**. To undo: `TV_HOST=<tv ip> tools/restore.sh examples/haier-matrixtv-de/debloat.txt com.google.android.apps.tv.launcherx`, or just `adb shell pm enable` each of the two packages.
- **Dock order:** edit `dock_apps` in `launcher/app/src/main/res/values/config.xml`, then `TV_HOST=<tv ip> launcher/build-and-install.sh`.
- **SmartTube** (`org.smarttube.stable`, from the official GitHub releases, signed by its developer) is for YouTube without ads. Sign in inside the app. It updates itself from within its own settings. To remove it: `adb shell pm uninstall org.smarttube.stable`. The original YouTube app is still installed.
- **System animations at 0.5x**, so menus feel snappier. To undo: `adb shell settings put global window_animation_scale 1` (and the same for `transition_animation_scale` and `animator_duration_scale`).
- **Remotes & Accessories pill (a local change; first added as "Bluetooth") to this launcher copy):** opens Remotes & Accessories pairing. It adds the BLUETOOTH_CONNECT permission (granted with `adb shell pm grant com.gathin.tvhome android.permission.BLUETOOTH_CONNECT`). The changed files are `AndroidManifest.xml`, `activity_main.xml`, `MainActivity.java`, `res/drawable/ic_bluetooth.xml` and `res/values/bluetooth_pill.xml`. Keep them if you update the launcher with `git pull`.

## Test run (2026-11-24, evening)
- Passed: Home opens the new launcher, including after a reboot. All 15 disabled packages stay off after reboot. All 6 dock apps open. The Inputs dropdown lists HDMI 1-4 and Composite. The Wi-Fi, Bluetooth and Settings pills open the right screens. D-pad Down moves from the top bar to the dock to the grid.
- **AdGuard Private DNS is now OFF** (`private_dns_mode opportunistic`): with it on, SmartTube never started a video. Setting SmartTube's own Settings -> General -> Network settings -> Preferred DNS to Google DNS did not help, so that is back on Default. YouTube ads are blocked by SmartTube itself. To turn AdGuard back on (this breaks SmartTube): `adb shell settings put global private_dns_mode hostname`.
- To do: find which domain AdGuard blocks that SmartTube needs, and use a DNS with an allowlist (for example AdGuard DNS with a custom profile, or NextDNS) so other apps keep filtering.
- The animation scales were 0 (off) at test time. They were not changed.
- JioCinema showed a required Play Store update on launch; let it finish.

## SBlock compatibility check (2026-11-24): not integrated
- SBlock ships only as Chrome Web Store extensions: Super Ad Blocker (`cmdgdghfledlbkbciggfjblphiafkcgg`) and the separate SBlock YouTube extension (`mhlojnkkkfigapidpkknanlpfmnjclgk`, version 0.0.1, very new). I found no official Android or Android TV app.
- Google TV has no Chrome browser, and Chrome on Android does not run extensions. An extension only filters pages inside the browser it runs in. It cannot reach a native app such as SmartTube, so there is no supported way to use it there.
- Decision: nothing changed on the TV. SmartTube keeps blocking YouTube ads itself. Use SBlock in desktop Chrome on computers.

## Remotes & Accessories button: opens the saved-devices list (2026-11-24)
- The top-bar button now opens Settings' Remotes & Accessories list (`SliceActivity` with `slice_uri=content://com.android.tv.settings.accessories.sliceprovider/general`). The list shows saved devices, and "Pair accessory" starts the search.
- This needs two grants: **WRITE_SECURE_SETTINGS** (you approved it on 2026-11-24) and BLUETOOTH_CONNECT. `launcher/build-and-install.sh` revokes WRITE_SECURE_SETTINGS on every install, so after any reinstall run:
      adb shell pm grant com.gathin.tvhome android.permission.WRITE_SECURE_SETTINGS
      adb shell pm grant com.gathin.tvhome android.permission.BLUETOOTH_CONNECT
  Without WRITE_SECURE_SETTINGS the button falls back to the pairing search screen.
- To take the permission away: `adb shell pm revoke com.gathin.tvhome android.permission.WRITE_SECURE_SETTINGS`
