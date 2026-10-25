# Install and run ZoldDesk

This guide is written for people and AI coding agents installing **this fork** from source. It covers CachyOS and macOS on Apple Silicon. ZoldDesk is based on [InukaAsith/TwinDesk](https://github.com/InukaAsith/TwinDesk); do not silently substitute the upstream repository or binaries from another release.

## Rules for AI agents

1. Work in a normal user account and a graphical desktop session. **Do not run the app as root, use `sudo npm`, disable Gatekeeper, edit macOS TCC databases, or add `--no-sandbox`.**
2. Clone exactly `https://github.com/akundummy16081991-byte/ZoldDesk.git` and inspect the existing checkout before overwriting anything.
3. Use **Node.js 26** where possible. The locked Electron tooling requires Node.js **22.12 or newer**. Check `node -v` and `npm -v`; do not continue with an unsupported runtime.
4. Use `npm ci` in the platform directory. Do not replace it with `npm install` and do not delete the lockfile to hide dependency errors.
5. Build the native helper before starting the app. Keep compiler output and dependency errors visible; fix their cause rather than skipping the helper.
6. OS permission prompts must be approved by the user. Do not simulate consent or weaken system security settings.
7. Do not report success merely because `npm ci` or packaging exited successfully. Start ZoldDesk and verify that its main window opens. If the environment cannot display or control a desktop, report that limitation explicitly.
8. Wayland input access, firewall changes, driver installation, macOS privacy permissions, and Android debugging permissions can require user action. A fully unattended installation is not guaranteed.

## CachyOS (Arch-based, x86_64)

### 1. Install prerequisites

Update the system and install the toolchain, Electron runtime libraries, native-helper headers, desktop integration, and AppImage support:

```bash
sudo pacman -Syu
sudo pacman -S --needed \
  base-devel git nodejs npm \
  libx11 libxi libxtst libxrandr libxfixes glib2 \
  gtk3 nss alsa-lib libxss libnotify \
  polkit bluez bluez-utils networkmanager \
  pipewire pipewire-pulse wireplumber \
  python-gobject gst-plugin-pipewire fuse2
```

Check the tools before building:

```bash
node -v
npm -v
git --version
cc --version
```

Use Node.js 26 when available; Node.js older than 22.12 is unsupported by the locked build dependencies. If CachyOS provides an older version, install Node.js 26 using a user-level version manager or the official Node.js distribution, then reopen the shell and check the versions again.

BlueZ and NetworkManager are needed for Bluetooth and direct-link features. PipeWire with `pipewire-pulse` supplies audio capture through `pactl`. `python-gobject` and `gst-plugin-pipewire` are used by Extend on GNOME Wayland.

### 2. Clone and run from source

```bash
git clone https://github.com/akundummy16081991-byte/ZoldDesk.git
cd ZoldDesk/linux
npm ci
npm run build:helper
npm start
```

Run `npm start` from the logged-in desktop session, not over a headless root shell. On first launch, follow the ZoldDesk Setup page. Approve only the permissions needed for the features being used.

### 3. Build packages

From the same `ZoldDesk/linux` directory:

```bash
npm run dist
ls -lh dist/
```

The expected files are named like:

- `ZoldDesk-2.2.0-x86_64.AppImage`
- `ZoldDesk-2.2.0-amd64.deb`

Use the AppImage on CachyOS. The `.deb` is intended for Debian-based distributions.

```bash
chmod +x dist/ZoldDesk-*.AppImage
./dist/ZoldDesk-*-x86_64.AppImage
```

If the AppImage reports a FUSE error, install `fuse2` and try again. As a fallback for that error only:

```bash
./dist/ZoldDesk-*-x86_64.AppImage --appimage-extract-and-run
```

### 4. Linux permissions and desktop-specific behavior

- **Firewall:** ZoldDesk uses TCP `47800` and UDP `47801`; Android wireless-debugging discovery also uses mDNS on UDP `5353`. Prefer the Setup page's Fix action, which asks for authorization through `pkexec`.
- **Wayland mouse and keyboard:** input sharing uses `/dev/uinput` and `/dev/input`. The Setup page can configure access after an administrator prompt. Log out and back in afterward when instructed.
- **Wayland screen capture:** the desktop's own portal can ask which screen to share each time. This is expected.
- **Extend on GNOME Wayland:** requires Python GObject and GStreamer's PipeWire plugin listed above.
- **Extend on X11:** depends on the graphics driver and an available output. NVIDIA's proprietary driver has additional limitations; the app reports whether the current machine can create the virtual display.
- **Terminal and folder sharing:** optional features can require OpenSSH or Samba. Let the relevant feature request its dependency, or install `openssh` and `samba` explicitly with pacman.
- **AppImage sandbox:** do not work around startup problems with `--no-sandbox`. Fix the missing library, permissions, or desktop-session problem shown in the logs.

## macOS 13+ on Apple Silicon (M1 or newer)

### 1. Install prerequisites

Install Apple's command-line tools if they are not present:

```bash
xcode-select -p
```

If that command fails, run:

```bash
xcode-select --install
```

Complete the installer dialog, then verify:

```bash
xcode-select -p
swiftc --version
node -v
npm -v
python3 --version
```

Use Node.js 26 when possible; Node.js 22.12 or newer is required. Install it with the user's existing version manager or the official macOS arm64 package, then reopen the shell. Python 3 is needed by the DMG packaging step.

### 2. Clone and run from source

```bash
git clone https://github.com/akundummy16081991-byte/ZoldDesk.git
cd ZoldDesk/mac
npm ci
npm run build:helper
npm start
```

The helper is compiled locally with Swift. Do not copy a prebuilt helper from an untrusted source.

### 3. Build an Apple Silicon DMG

From `ZoldDesk/mac`:

```bash
npm run dist:arm64
codesign --verify --deep --strict --verbose=2 dist/ZoldDesk.app
npm run dmg
ls -lh dist/ZoldDesk.dmg
```

To install the freshly built app from the DMG:

```bash
hdiutil attach dist/ZoldDesk.dmg
cp -R "/Volumes/ZoldDesk/ZoldDesk.app" /Applications/
hdiutil detach "/Volumes/ZoldDesk"
open -a ZoldDesk
```

If `/Applications/ZoldDesk.app` already exists, stop ZoldDesk and preserve or remove the old copy deliberately before copying; do not overwrite a user's app without permission.

For an Intel cross-build from Apple Silicon, use `npm run dmg:intel`, which creates `dist/ZoldDesk_intel.dmg`. Apple Silicon users should use the arm64 build instead.

### 4. macOS signing, Gatekeeper, and permissions

- Local and CI builds use a self-signed certificate when available, otherwise ad-hoc signing. They are **not notarized by Apple**.
- Verify the source and any downloaded checksum before opening a package. If Gatekeeper warns, use Finder's right-click **Open** flow or Privacy & Security's **Open Anyway** after reviewing the warning. Do not disable Gatekeeper and do not run blanket `xattr -dr` commands.
- Grant **Screen Recording**, **Accessibility**, and **Input Monitoring** when the corresponding features need them. Local Network, Microphone, Bluetooth, and location-related prompts can also appear depending on connectivity and phone features.
- After changing a privacy permission, restart ZoldDesk when macOS requests it. Keep the same signing identity across updates where possible because macOS associates permissions with the app's signature.

## GitHub Actions packages

If this repository has no published GitHub Release, an agent must not invent a direct-release URL. A logged-in user can open the repository's **Actions** tab, run **Build Linux**, **Build macOS**, **Build Windows**, or **Build Android**, and download the resulting artifacts.

Every desktop workflow runs the composite Android source-build action first. Both APK variants are built from this repository. If `ANDROID_KEYSTORE` is configured, that key signs them; otherwise the runner uses its local debug key, so those APKs cannot update an installation signed with a different key.

## Verification checklist for agents

Before declaring completion:

```bash
git remote -v
node -v
npm -v
```

- `origin` points to `akundummy16081991-byte/ZoldDesk`.
- `npm ci` and `npm run build:helper` completed without hidden errors.
- `npm start` opens the ZoldDesk main window, or a built package opens it.
- The app is running as the normal desktop user, not root.
- Required OS prompts were left for or approved by the user.
- Any untested permission, hardware-specific feature, Wayland limitation, or Gatekeeper step is reported rather than described as verified.
