# Firebox

A small collection of Bash launchers that run everyday applications inside
hardened, ephemeral [Bubblewrap](https://github.com/containers/bubblewrap)
(`bwrap`) sandboxes. Each launcher is self-contained, and each is documented in
detail by its own `*-readme.txt`.

| Script | Launches | Details |
| --- | --- | --- |
| `firebox` | Privacy-hardened, ephemeral Firefox | [`firebox-readme.txt`](firebox-readme.txt) |
| `firebox-signal` | Signal Desktop | [`firebox-signal-readme.txt`](firebox-signal-readme.txt) |
| `firebox-opencode` | The opencode CLI | [`firebox-opencode-readme.txt`](firebox-opencode-readme.txt) |

## The scripts

### firebox — sandboxed, ephemeral, privacy-hardened Firefox
Copies your real profile into a fresh session directory in RAM, strips history
and cookies from it, injects a strict privacy `user.js` and a locked-down
`policies.json`, then launches Firefox under `bwrap`: read-only system mounts,
a filtered D-Bus proxy, a custom `/etc/hosts` that blocks telemetry endpoints,
and auto-detected NVIDIA/AMD/Intel acceleration. Everything is discarded on
exit.

Run it with `--shell` to build the exact same hardened environment but hand you
an interactive `bash` instead of a browser. Use that to inspect what is mounted,
run utilities, or vet other programs under the same isolation before trusting
them.

→ [`firebox-readme.txt`](firebox-readme.txt)

### firebox-signal — sandboxed Signal Desktop
Runs Signal against an ephemeral `HOME` under `/tmp/sandboxes/signal`, keeping
only `~/.config/Signal` between sessions. A filtered D-Bus proxy is scoped to
`org.signal.*` and the StatusNotifier/portal interfaces; Wayland, audio, camera
and CUPS are bound; egress is routed through `proxychains` when available.

→ [`firebox-signal-readme.txt`](firebox-signal-readme.txt)

### firebox-opencode — sandboxed opencode CLI
Starts from an empty root and mounts only what a coding session needs: a
read-only system tree, private `/tmp` and `/dev/shm`, and a handful of
persistent read-write opencode directories. `HOME` is `/projects`, and the
session begins in the directory the launcher was invoked from.

→ [`firebox-opencode-readme.txt`](firebox-opencode-readme.txt)

## Shared design

- **Ephemeral by default** — session data lives in RAM (`/dev/shm` or `/tmp`) and is destroyed on exit.
- **Read-only system** — binaries, libraries and `/etc` are bound read-only; only explicitly listed paths are writable.
- **Least-privilege D-Bus** — a proxy exposes only the bus names and interfaces each app actually needs.
- **Wayland-only** — no X11 fallback.
- **Namespaced** — IPC, PID, cgroup and UTS namespaces are unshared; the hostname is `localhost`.

## Requirements

Linux with a Wayland session, plus `bwrap` (Bubblewrap). Individual scripts add
their own tools — commonly `xdg-dbus-proxy`, `rsync`, `awk`, `file`, `sqlite3`
and `findmnt`, with `jq` and `uuidgen` optional. `firebox-signal` and
`firebox-opencode` also use `proxychains` when it is installed.

## Installation

The repository ships a single `app-misc/firebox` package. It installs the three
launchers into `/usr/bin` and adds an `opencode` convenience symlink. Copy the
ebuild into your local Gentoo tree and generate its Manifest:

    cp -r app-misc/firebox /var/db/repos/gentoo/app-misc/
    cd /var/db/repos/gentoo/app-misc/firebox
    ebuild firebox-9999.ebuild manifest

The `ebuild ... manifest` step digests the live ebuild (and any AUX/MISC files)
and writes the results into the local `Manifest`, which Portage requires before
it will accept the package. Then install it:

    echo "app-misc/firebox **" >> /etc/portage/package.accept_keywords/firebox
    emerge -av app-misc/firebox

`app-misc/firebox` is a live ebuild (`-9999`) that tracks `master`: re-run the
copy, `ebuild ... manifest` and `emerge` steps whenever you update your
checkout. There are no tagged releases, hence no versioned ebuild.

## Usage

    ./firebox            # ephemeral, hardened Firefox
    ./firebox --shell    # interactive shell inside the sandbox
    ./firebox-signal     # sandboxed Signal Desktop
    ./firebox-opencode   # sandboxed opencode CLI

Each script accepts `-v` for verbose launcher tracing.

> The `*-readme.txt` files are the authoritative reference for each sandbox —
> read the matching one for exact behaviour, dependencies and caveats.

The scripts were written by robots but carefully and painstakingly refined by
hand. Input and refinements are very welcome.
