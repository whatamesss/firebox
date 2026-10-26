firebox-opencode — sandboxed opencode CLI
==========================================

This is a Bash script named firebox-opencode that launches the opencode CLI inside a
hardened, minimal Bubblewrap (bwrap) sandbox. The sandbox starts from an empty
root filesystem and exposes only what a coding session needs: a read-only
system tree, private scratch space, and a small set of persistent
read-write directories.

1. Core Concept

The script builds an empty root and mounts in exactly the pieces opencode
requires. opencode runs with HOME set to the real home directory (so its
self-managed install tree at ~/.opencode is respected) and starts in the
directory the launcher was invoked from (provided that directory is inside
~/projects).
Everything outside the persistent directories is either read-only or a
throwaway tmpfs.

2. Key Features & Workflow

     Working directory:
          If launched from inside ~/projects, opencode starts in the matching
          /projects/... subfolder; otherwise it starts in /projects. HOME is
          set to the real home directory, so ~/.opencode/bin/opencode is the
          binary opencode upgrades in place.

     Persistent, read-write state:
          ~/projects                -> /projects
          ~/.opencode               -> ~/.opencode
          ~/.config/opencode        -> ~/.config/opencode
          ~/.cache/opencode         -> ~/.cache/opencode
          ~/.local/share/opencode   -> ~/.local/share/opencode
          ~/.local/state/opencode   -> ~/.local/state/opencode
          ~/.mozilla                -> ~/.mozilla
          /tmp/opencode             -> /tmp   (scratch, created at launch)
          ~/.gitconfig is bound read-only, if present (git identity).

     Read-only system:
          /usr, /bin, /sbin, /usr/libexec/git-core (git's real binaries), libs
          and multiarch directories, /usr/local, /opt, /usr/share data (zoneinfo,
          locale, terminfo, git-core templates, CA certificates), and selected
          /etc files (ld.so cache/conf, SSL certificates, resolv.conf,
          nsswitch.conf, hosts, passwd/group, machine-id, localtime,
          proxychains.conf, gitconfig, profile files).

     Scratch (/tmp and $TMPDIR):
          /tmp is a bind of the host's /tmp/opencode, created at launch with
          mode 700. The host's /tmp is a tmpfs, so nothing reaches the disk,
          but unlike a sandbox-internal tmpfs the contents survive between
          sessions and can be inspected from the host. Only non-executable
          scratch belongs there. TMPDIR and BUN_TMPDIR point at the private,
          ephemeral /dev/shm instead: Bun extracts its OpenTUI renderer into
          $TMPDIR and dlopen()s it, and a shared, persistent $TMPDIR can hand
          a later session a stale or partially written object, which the
          loader rejects with "failed to map segment from shared object".
          /dev/shm is wiped when the sandbox exits, so that cannot recur.
          XDG_RUNTIME_DIR is a private mode-0700 /run/user/<uid> directory in
          the sandbox root, also discarded with the sandbox. /sys is reduced
          to CPU topology only, with no hardware enumeration.

3. Isolation

     Namespaces:
          Unshares IPC, PID, cgroup, and UTS namespaces; sets the hostname to
          "localhost"; uses --die-with-parent and --new-session.

     Environment:
          DISPLAY, WAYLAND_DISPLAY, XAUTHORITY, DBUS_SESSION_BUS_ADDRESS,
          SSH_AUTH_SOCK, GNUPGHOME, GPG_AGENT_INFO and the KDE_* variables are
          unset. LANG and LC_ALL are forced to C.UTF-8.
          HOME is the real home directory and XDG_CONFIG_HOME, XDG_DATA_HOME,
          XDG_CACHE_HOME and XDG_STATE_HOME point at the real host
          directories so opencode locates its own configuration and data.
          Because the sandbox root is otherwise empty, the rest of the home
          directory is still inaccessible even though HOME names it.

     Network:
          The network namespace is not unshared. If proxychains is present,
          egress is routed through it; otherwise opencode connects directly.

4. Dependencies

     bwrap (Bubblewrap)
     proxychains (optional; proxychains4 on Debian/Ubuntu)
     opencode (expected at ~/.opencode/bin/opencode)

5. Usage

     ./firebox-opencode              # start in /projects (or the current subfolder)
     ./firebox-opencode [args...]    # additional arguments are forwarded to opencode
     ./firebox-opencode -v           # verbose launcher tracing (set -x)
     ./firebox-opencode --no-proxy   # ignore proxychains and connect directly

6. Notes / Limitations

     Ctrl-C is disabled inside the sandbox (via a TUI keybind overlay set with
     OPENCODE_TUI_CONFIG), so it cannot quit the session or clear the prompt.
     The overlay is written to a local file at launch and bind-mounted
     read-only over /etc/opencode-tui.json; it carries no remote "$schema"
     URL and is never fetched from the network.
     Exit with /quit (or ctrl+x q, or ctrl+d).
     --new-session detaches the controlling terminal, so terminal resizes may
     not reflow until the session restarts. Remove that flag if this is a
     problem.
     /etc/passwd and /etc/group are synthesised per session, so only the
     launching user is visible and no real host account list is exposed.
     Because XDG_* point at the real host directories, only the opencode
     subdirectories exist inside the sandbox; other applications' config
     directories are not writable.
