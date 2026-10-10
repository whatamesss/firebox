# Firebox is a bash script written by robots but carefully and painstakingly refined by me. i would love your input or refinements!

A security-hardened Bash wrapper for Firefox that launches an ephemeral, sandboxed session using Bubblewrap (`bwrap`). It creates a temporary profile in RAM, injects strict privacy settings, and auto-configures hardware acceleration for NVIDIA, AMD, and Intel GPUs on Wayland.

## Features
*   **Total Isolation:** Sandboxes filesystem, PID, and IPC namespaces.
*   **Ephemeral Profile:** Creates a fresh profile in RAM (`/dev/shm`) on every launch. All data is deleted on exit.
*   **Sanitized Bookmarks:** Imports bookmarks from your master profile while strictly purging all history, cookies, and input history using SQLite.
*   **Hardened Privacy:** Disables telemetry, ads, tracking, and Pocket via injected `user.js` and `policies.json`.
*   **Profile Sync:** Automatically imports your installed add-ons, extension storage, toolbar/tab layout, and the extension quarantine list from your main Firefox profile.
*   **GPU Acceleration:** Auto-detects NVIDIA, AMD, and Intel drivers; handles VA-API and Vulkan dynamically.
*   **Wayland Native:** Requires a Wayland compositor; no X11 fallback.

## Prerequisites
*   **OS:** Linux (Wayland session).
*   **Tools:** `bubblewrap`, `xdg-dbus-proxy`, `rsync`, `awk`, `file`, `sqlite3`, `findmnt`.
*   **Optional tools:** `jq` (scrubs tokens from synced extension storage), `uuidgen` (random per-session machine-id).
*   **Browser:** `firefox`, `firefox-esr`, or `firefox-bin`.

## Installation

    # 1. Save script as 'firebox' and make executable
    chmod +x firebox

    # 2. Move to bin (optional)
    sudo mv firebox /usr/local/bin/firebox

## Usage

    # Open with blank page
    firebox

    # Open specific URL
    firebox example.com

    # Debug mode
    firebox -v

## Testing the Sandbox (firebox-shell)

`firebox-shell` opens an interactive `bash` shell *inside* the same hardened
sandbox as `firebox`. Use it to test the environment, run utilities, or try
other applications under the same isolation (filesystem/PID/IPC namespaces,
GPU injection, filtered D-Bus portals, blocked hosts) before trusting them:

    firebox-shell

## Configuration & Persistence

**Important:** Because the sandbox runs in RAM, **all changes made inside a `firebox` session are lost when you close it.** To make persistent changes, use your standard, unsandboxed Firefox instance:

1.  **Add-ons:** Install, update, and configure extensions in your main browser. `firebox` will automatically sync these extensions on the next launch.
2.  **Layout & Add-on Settings:** Toolbar/tab layout, the horizontal-tab backup, and your extension quarantine list are imported from your main browser at launch.
3.  **Bookmarks:** Manage your bookmarks in your main browser. `firebox` automatically imports them and strips all associated history/cookies at launch, ensuring a fresh browsing session.

*Note: Network settings are not imported. `firebox` applies its own hardened network configuration (direct connection, DNS-over-HTTPS disabled) and ignores the master profile's proxy/DoH settings.*

*Note: Downloads are not saved to disk. To keep a file, manually copy it to your real `Downloads` folder. you can modify the $SANDBOXES variable near the start of the script but read the warning*

## Troubleshooting
*   **"WAYLAND_DISPLAY is not set":** Ensure you are running a Wayland session (GNOME, Sway, etc.).
*   **"Firefox binary not found":** Ensure `firefox`, `firefox-esr`, or `firefox-bin` is in your `$PATH`.
*   **GPU Issues:** Run with `-v`. The script auto-injects driver paths, but ensure your proprietary/NVIDIA/Mesa drivers are correctly installed system-wide.
