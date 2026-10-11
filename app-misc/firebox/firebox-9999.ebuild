# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 optfeature

DESCRIPTION="Bash launchers that run apps inside hardened, ephemeral Bubblewrap sandboxes"
HOMEPAGE="https://github.com/whatamesss/firebox"
EGIT_REPO_URI="https://github.com/whatamesss/firebox.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"

RDEPEND="
	sys-apps/bubblewrap
	sys-apps/file
	sys-apps/util-linux
	sys-apps/xdg-dbus-proxy
	dev-db/sqlite
	net-misc/rsync
	virtual/awk
"

src_install() {
	local script
	for script in firebox firebox-opencode firebox-signal; do
		dobin "${script}" || die
	done

	# Convenience alias: `opencode` launches the sandboxed CLI. Note this
	# only wins if /usr/bin precedes the upstream installer's
	# ~/.opencode/bin in PATH.
	dosym firebox-opencode /usr/bin/opencode

	dodoc README.md firebox-readme.txt firebox-opencode-readme.txt firebox-signal-readme.txt
}

pkg_postinst() {
	optfeature "routing sandboxed egress through a proxy" net-misc/proxychains
	optfeature "scrubbing tokens from synced extension storage (firebox)" app-misc/jq

	elog "Firebox only provides the sandboxes; the applications it launches"
	elog "are installed separately, for example:"
	elog
	elog "  firebox          -> www-client/firefox (or www-client/firefox-bin)"
	elog "  firebox-signal   -> Signal Desktop (net-im/signal-desktop-bin)"
	elog "  firebox-opencode -> the opencode CLI (https://opencode.ai)"
}
