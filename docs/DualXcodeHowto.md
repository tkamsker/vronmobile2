You can run **Xcode 16.4 (16F6)** side-by-side with the newest Xcode just fine — the trick is:

1. install each as a separate `.app` in `/Applications` (different names), and
2. switch the active toolchain per project/terminal with `xcode-select` or `DEVELOPER_DIR`.

Also: **Xcode 16.4 includes iOS 18.x SDK support** (iOS 18.5 SDK per Apple’s release notes / version tables), so keeping it around is a good way to keep iOS 18.x workflows stable while you evaluate newer Xcode. ([Apple Developer][1])

---

## Install Xcode 16.4 in parallel (recommended workflow)

### 1) Download Xcode 16.4 from Apple (not the App Store build)

* Apple’s “Downloads” / “More downloads” is the canonical place for older Xcodes. ([Apple Developer][2])

You’ll end up with `Xcode.app` (from the `.xip`).

### 2) Rename it **before** moving to /Applications

Example:

```bash
mv ~/Downloads/Xcode.app /Applications/Xcode-16.4.app
```

Keep the newest one as:

* `/Applications/Xcode.app` (App Store or latest .xip)
* `/Applications/Xcode-16.4.app` (your “pinned” iOS 18.x toolchain)

This is the standard “multiple Xcodes” pattern. ([Stack Overflow][3])

### 3) Accept license + install components once

```bash
sudo /Applications/Xcode-16.4.app/Contents/Developer/usr/bin/xcodebuild -license accept
sudo /Applications/Xcode-16.4.app/Contents/Developer/usr/bin/xcodebuild -runFirstLaunch
```

(Repeat for the newest Xcode once.)

---

## Switch between versions (system-wide vs per-terminal)

### Option A: Switch system-wide (affects `xcodebuild`, `xcrun`, Flutter iOS builds, etc.)

```bash
sudo xcode-select -s /Applications/Xcode-16.4.app/Contents/Developer
xcodebuild -version
xcode-select -p
```

Switch back to newest:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Option B: Switch per project / per terminal (best for parallel work)

In the shell where you build:

```bash
export DEVELOPER_DIR=/Applications/Xcode-16.4.app/Contents/Developer
xcodebuild -version
```

This avoids breaking other terminals/CI.

---

## Simulators and iOS 18.x

* Xcode 16 (and 16.4 specifically) ships with iOS 18 SDK/sim runtime aligned to that release train; 16.4 corresponds to iOS 18.5 SDK in common version tables, and Apple’s Xcode 16 release notes confirm iOS 18 SDK coverage for the Xcode 16 family. ([Apple Developer][4])
* If you want to “freeze” iOS 18.x simulators, keep using Xcode 16.4’s Simulator runtime from that app. Newer Xcode can install newer iOS 18 point runtimes too, but keeping 16.4 around is a solid stability anchor.

---

## Practical setup for Flutter (so it always picks the right Xcode)

### For “stable iOS 18.x builds” in one terminal:

```bash
export DEVELOPER_DIR=/Applications/Xcode-16.4.app/Contents/Developer
flutter doctor -v
flutter build ios
```

### For “try newest Xcode” in another terminal:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
flutter doctor -v
```

---

## Strongly recommended: use Xcodes.app (or `xcodes` CLI)

If you’re doing this often, **Xcodes.app** can download/install multiple Xcodes and switch the active one without you manually juggling paths. ([DEV Community][5])

---

## One important gotcha on Tahoe

Make sure your **macOS version supports Xcode 16.4**. Some older Xcodes won’t run on newer macOS releases, and Tahoe has tightened restrictions in places. If 16.4 launches fine on your machine today, you’re good; if it refuses to launch, we’ll need to pin the matching macOS or use a separate machine/VM. ([Medium][6])

---

If you tell me which “newest Xcode” you mean (version/build) and your macOS build (e.g. Tahoe 15.x / 26.x style numbers), I’ll give you the exact pairing rules + the cleanest `DEVELOPER_DIR`/CI setup so iOS 18.x never breaks again.

[1]: https://developer.apple.com/documentation/xcode-release-notes/xcode-16_4-release-notes?utm_source=chatgpt.com "Xcode 16.4 Release Notes"
[2]: https://developer.apple.com/support/xcode/?utm_source=chatgpt.com "Xcode - Support"
[3]: https://stackoverflow.com/questions/669367/can-i-have-multiple-xcode-versions-installed?utm_source=chatgpt.com "Can I have multiple Xcode versions installed?"
[4]: https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes?utm_source=chatgpt.com "Xcode 16 Release Notes | Apple Developer Documentation"
[5]: https://dev.to/markkazakov/managing-multiple-xcode-versions-with-xcodesapp-3ini?utm_source=chatgpt.com "Managing Multiple Xcode Versions with Xcodes.app"
[6]: https://michaellong.medium.com/another-year-another-xcode-macos-warning-a2d3d003ef8c?utm_source=chatgpt.com "Another Year, Another Xcode/macOS Warning | by Michael Long"
