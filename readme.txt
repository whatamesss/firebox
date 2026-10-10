This is a comprehensive Bash script named firebox designed to launch a heavily sandboxed, privacy-hardened, and ephemeral instance of Firefox using bwrap (Bubblewrap) and xdg-dbus-proxy.

Here is a breakdown of what the script does:
1. Core Concept

The script creates a temporary "sandbox" environment. It copies your existing Firefox profile (bookmarks, extensions, and preferences) into a temporary directory (usually in RAM via /dev/shm or /tmp), sanitizes it (removes history and cookies), applies strict privacy settings, and then launches Firefox inside this isolated environment. Any changes made during the session are discarded when the browser closes.
2. Key Features & Workflow

     

    Ephemeral Profile:
         Creates a unique temporary runtime directory (TMPFS_RUNTIME) for every session.
         Copies the user's "master" profile into this directory so settings and extensions persist across sessions but are isolated from the actual disk writes of the main browser.
     

    Data Sanitization:
         Bookmarks: Syncs places.sqlite from the master profile but uses sqlite3 to delete all history (moz_historyvisits) and reset visit counts, keeping only the bookmarks.
         Extensions: Syncs extension files and their specific storage (IndexedDB for moz-extension++*) while excluding website storage (http*, https*).
         Extension UUIDs: Uses sed to copy the extension UUID mapping from the master profile so extensions recognize their ID in the new profile.
     

    Privacy Hardening (user.js & policies.json):
         Injects a massive user.js file into the profile that disables:
             Telemetry and data reporting.
             Pocket, Firefox Sync, and Metrics.
             Safe Browsing (Mozilla's phishing/malware list).
             Auto-filling passwords and addresses.
         Enforces "Letterboxing" (privacy.resistFingerprinting) to prevent screen-size tracking.
         Sets default search engines to DuckDuckGo and Startpage.
         Creates a policies.json to lock down settings like disabling updates and account services.
     

    Sandboxing (bwrap):
         Isolation: Unshares IPC, cgroup, and UTS namespaces. Sets a custom hostname (localhost).
         Filesystem: Mounts the system directories (/usr, /lib, /etc) as read-only. Creates a fake /home, /etc/passwd, and /etc/machine-id.
         Network/DNS: Creates a custom /etc/hosts file to block known Mozilla telemetry and tracking domains (e.g., telemetry.mozilla.org).
         OS Spoofing: Mounts a fake /etc/os-release identifying the system as "Ubuntu 26.04 LTS".
     

    Hardware Acceleration (GPU):
         Detects if the system uses NVIDIA, AMD, or Intel graphics.
         Dynamically binds the necessary device files (/dev/dri/, /dev/nvidia*).
         Sets environment variables for VA-API and VDPAU to ensure video decoding works inside the sandbox.
     

    Desktop Integration:
         Wayland: Binds the Wayland socket and sets MOZ_ENABLE_WAYLAND=1.
         Audio: Binds PulseAudio or PipeWire sockets.
         D-Bus: Uses xdg-dbus-proxy to filter D-Bus calls, allowing only specific portals (File Chooser, Settings, Notifications) to pass through.
         Theme/Fonts: Binds system icons, themes, and fonts so the browser looks native.

3. Security Mechanisms

     Read-Only System: The browser cannot write to system binaries or libraries.
     Filtered D-Bus: The sandboxed Firefox cannot blindly control other apps via D-Bus.
     Noexec / Tmpfs Checks: The script checks if /tmp is mounted with noexec or tmpfs for security, though it falls back if not.
     Profile Locking: It reads the master profile's "lock" symlink (Firefox records "ip:pid" there via its fcntl lock) and aborts if that process is still alive, preventing database corruption from copying a live profile.

4. Dependencies

The script requires the following tools installed on the system:

     bwrap (Bubblewrap)
     xdg-dbus-proxy
     rsync
     sqlite3
     awk
     file
     findmnt
     uuidgen (optional)
     jq (optional; scrubs tokens from synced extension storage)

5. Usage

The script is typically invoked with a URL:
bash
 
  
 
 
./firebox https://example.com
 
 

Or simply:
bash
 
  
 
 
./firebox
 
 

It supports a -v or --verbose flag for debugging output.
Summary

This script essentially transforms a standard Firefox installation into a "Tor-browser-like" experience (in terms of sandboxing and ephemerality, though not using the Tor network) by leveraging Linux namespaces and bind mounts. It is designed for users who want to browse the web without leaving traces on their disk or exposing their main system to potential browser exploits.
