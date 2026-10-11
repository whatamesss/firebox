firebox-opencode — sandboxed opencode CLI
==========================================

This is a Bash script named firebox-opencode that launches the opencode CLI inside a
hardened, minimal Bubblewrap (bwrap) sandbox. The sandbox starts from an empty
root filesystem and exposes only what a coding session needs: a read-only
system tree, private scratch space, and a small set of persistent
read-write directories.

1. Core Concept

The script builds an empty root and mounts in exactly the pieces opencode
requires. opencode runs with HOME=/projects and starts in the directory the
launcher was invoked from (provided that directory is inside ~/projects).
Everything outside the persistent directories is either read-only or a
throwaway tmpfs.

2. Key Features & Workflow

     Working directory:
          If launched from inside ~/projects, opencode starts in the matching
          /projects/... subfolder; otherwise it starts in /projects. HOME is
          set to /projects.

     Persistent, read-write state:
          ~/projects                -> /projects
          ~/.opencode               -> ~/.opencode
          ~/.config/opencode        -> ~/.config/opencode
          ~/.cache/opencode         -> ~/.cache/opencode
          ~/.local/share/opencode   -> ~/.local/share/opencode
          ~/.gitconfig is bound read-only, if present (git identity).

     Read-only system:
          /usr, /bin, /sbin, libs and multiarch directories, /usr/local, /opt,
          /usr/share data (zoneinfo, locale, terminfo, CA certificates), and
          selected /etc files (ld.so cache/conf, SSL certificates,
          resolv.conf, nsswitch.conf, hosts, passwd/group, machine-id,
          localtime, proxychains.conf, profile files).

     Ephemeral scratch:
          A private tmpfs /tmp and /dev/shm, with TMPDIR pointed at /tmp. Tool
          output therefore never touches the host disk and is discarded on
          exit. /sys is reduced to CPU topology only, with no hardware
          enumeration.

3. Isolation

     Namespaces:
          Unshares IPC, PID, cgroup, and UTS namespaces; sets the hostname to
          "localhost"; uses --die-with-parent and --new-session.

     Environment:
          DISPLAY, WAYLAND_DISPLAY, XAUTHORITY, DBUS_SESSION_BUS_ADDRESS,
          SSH_AUTH_SOCK, GNUPGHOME, GPG_AGENT_INFO and the KDE_* variables are
          unset. LANG and LC_ALL are forced to C.UTF-8.
          XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_CACHE_HOME and XDG_STATE_HOME
          point at the real host directories so opencode locates its own
          configuration and data.

     Network:
          The network namespace is not unshared; egress is routed through
          proxychains.

4. Dependencies

     bwrap (Bubblewrap)
     proxychains
     opencode (expected at ~/.opencode/bin/opencode)

5. Usage

     ./firebox-opencode              # start in /projects (or the current subfolder)
     ./firebox-opencode [args...]    # additional arguments are forwarded to opencode
     ./firebox-opencode -v           # verbose launcher tracing (set -x)

6. Notes / Limitations

     --new-session detaches the controlling terminal, so terminal resizes may
     not reflow until the session restarts. Remove that flag if this is a
     problem.
     The host /etc/passwd and /etc/group are bound read-only, so real usernames
     are visible (but no secrets are exposed).
     Because XDG_* point at the real host directories, only the opencode
     subdirectories exist inside the sandbox; other applications' config
     directories are not writable.
