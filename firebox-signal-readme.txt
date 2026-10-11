firebox-signal — sandboxed Signal Desktop
=========================================

This is a Bash script named firebox-signal that launches Signal Desktop inside
a hardened Bubblewrap (bwrap) sandbox with a filtered D-Bus proxy.

1. Core Concept

Signal runs against an ephemeral HOME under /tmp/sandboxes/signal. Only its
configuration (~/.config/Signal) is persisted from the host; everything else
created during the session is discarded when Signal exits.

2. Key Features & Workflow

     Single instance:
          Exits immediately if a signal-desktop process is already running, to
          avoid starting a second instance.

     Ephemeral runtime:
          Creates a unique runtime directory (TMPFS_RUNTIME), preferring
          /dev/shm and falling back to /tmp. It holds a synthesized
          /etc/passwd, /etc/group and /etc/machine-id plus a custom /etc/hosts.
          A cleanup trap removes it on exit.

     Hardware acceleration:
          Detects NVIDIA, AMD, or Intel GPUs; binds the relevant /dev/dri and
          /dev/nvidia* device nodes and sets VA-API, Vulkan and EGL environment
          variables so video decoding and rendering work inside the sandbox.

     Desktop integration:
          Binds the Wayland socket, PulseAudio / PipeWire sockets, camera
          devices (/dev/video*), and CUPS for printing. Binds system themes,
          icons, fonts, GLib schemas, MIME data and X11 keyboard layouts.

     Filtered D-Bus:
          Starts xdg-dbus-proxy and allows only org.signal.* and the
          StatusNotifier names to be owned, visibility of
          org.freedesktop.portal.Desktop, narrowly-scoped portal interfaces
          (FileChooser, OpenURI, Settings, Notification, Clipboard, Inhibit,
          Request), and talk access to Notifications, secrets and the
          StatusNotifierWatcher.

     Persistent state:
          ~/.config/Signal is bound read-write; /opt/Signal is bound read-only.

3. Isolation

     Namespaces:
          Unshares IPC, PID, cgroup, and UTS namespaces; sets the hostname to
          "localhost"; uses --die-with-parent and --new-session.

     Filesystem:
          System directories are mounted read-only. A custom /etc/hosts is
          synthesized (localhost entries plus any host 0.0.0.0 entries), and
          the identity files are regenerated per session.

     Network:
          The network namespace is not unshared; egress is routed through
          proxychains.

4. Dependencies

     bwrap (Bubblewrap)
     xdg-dbus-proxy
     findmnt
     proxychains
     uuidgen (optional; random per-session machine-id)
     jq (optional; degraded features if absent)

5. Usage

     ./firebox-signal        # launch Signal Desktop in the sandbox
     ./firebox-signal -v     # verbose launcher tracing (set -x)

6. Notes / Limitations

     All changes made inside a session, other than ~/.config/Signal, are lost
     when Signal closes.
     A Wayland session is required; the sandbox has no X11 fallback.
     Signal is launched as:
          proxychains -q signal-desktop --use-webgpu-adapter=opengles
