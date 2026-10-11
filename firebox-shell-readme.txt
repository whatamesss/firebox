firebox-shell — interactive shell inside the firebox sandbox
============================================================

This is a Bash script named firebox-shell that opens an interactive bash shell
inside the same hardened sandbox used by firebox. It builds the identical
bubblewrap environment (namespaces, read-only system mounts, filtered D-Bus
proxy, GPU injection, Wayland/audio/print binds, synthesized identity files),
but instead of launching Firefox it drops you into a shell.

1. Core Concept

Use firebox-shell to explore and test the sandbox from the inside: inspect what
is mounted, run utilities, or launch other programs under the same isolation
before trusting them. The environment is ephemeral, so anything you create is
discarded when the shell exits.

2. What it sets up

     Ephemeral environment:
          Creates a unique runtime directory (TMPFS_RUNTIME) in /dev/shm or
          /tmp, plus an ephemeral Firefox profile inside it. HOME inside the
          sandbox is /tmp/sandboxes/firefox, and the profile is bound at
          $EPHEMERAL_PROFILE.

     Profile seed:
          Detects your default Firefox profile, syncs extensions and their
          storage, injects a privacy-hardened user.js and a locked-down
          policies.json, and imports bookmarks with history and cookies
          stripped.

     Filtered D-Bus:
          Starts xdg-dbus-proxy, exposing only org.mozilla.firefox.* and the
          narrowly scoped org.freedesktop.portal interfaces.

     Desktop integration:
          Binds the Wayland socket, PulseAudio / PipeWire sockets, camera
          devices (/dev/video*), and CUPS. Binds system themes, icons, fonts,
          GLib schemas, MIME data and X11 keyboard layouts.

     Hardware acceleration:
          Detects NVIDIA, AMD, or Intel GPUs, binds the corresponding devices,
          and sets VA-API / Vulkan / EGL environment variables.

     Custom identity and hosts:
          Synthesizes /etc/passwd, /etc/group and /etc/machine-id, a spoofed
          /etc/os-release (reported as Ubuntu 26.04 LTS), and a /etc/hosts that
          blocks a list of Mozilla telemetry and tracking domains.

3. Isolation

     Namespaces:
          Unshares IPC, PID, cgroup, and UTS namespaces; sets the hostname to
          "localhost"; uses --die-with-parent and --new-session.

     Filesystem:
          System directories are mounted read-only. Only the sandbox runtime
          directory, the ephemeral profile, and the sandbox Downloads /
          Documents / Pictures / Desktop directories are writable.

     Network:
          The network namespace is not unshared and no proxy is applied, so the
          shell has the host's network access (subject to the custom /etc/hosts).

4. Dependencies

     bwrap (Bubblewrap)
     xdg-dbus-proxy
     rsync, awk, file, sqlite3, findmnt
     uuidgen (optional; random per-session machine-id)
     jq (optional)
     A Firefox binary (firefox, firefox-esr, or firefox-bin), used to locate
     the install directory for the distribution/policies overrides.

5. Usage

     ./firebox-shell          # open an interactive shell in the sandbox
     ./firebox-shell -v       # verbose launcher tracing (set -x)

6. Notes / Limitations

     A Wayland session is required (WAYLAND_DISPLAY must be set), and a Firefox
     binary must be found, since the script builds the full Firefox sandbox
     environment before handing you the shell.
     All changes made inside the shell are lost on exit, except anything
     written to host paths that are bound read-write.
