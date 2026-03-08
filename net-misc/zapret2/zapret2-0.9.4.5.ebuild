# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd toolchain-funcs

DESCRIPTION="Anti-DPI tool to bypass HTTP(S)/VPN blocking and throttling"
HOMEPAGE="https://github.com/bol-van/zapret2"
SRC_URI="https://github.com/bol-van/zapret2/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="luajit systemd"

BDEPEND="
	virtual/pkgconfig
"
DEPEND="
	net-libs/libnetfilter_queue
	net-libs/libnfnetlink
	net-libs/libmnl
	sys-libs/zlib
	luajit? ( dev-lang/luajit:2 )
	!luajit? ( dev-lang/lua:5.5 )
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}"

ZAPRET_DIR=/opt/zapret2

src_compile() {
	local target="all"
	use systemd && target="systemd"

	local lua_cflags lua_lib
	if use luajit; then
		lua_cflags="$($(tc-getPKG_CONFIG) --cflags luajit)"
		lua_lib="$($(tc-getPKG_CONFIG) --libs luajit)"
	else
		lua_cflags="$($(tc-getPKG_CONFIG) --cflags lua5.5)"
		lua_lib="$($(tc-getPKG_CONFIG) --libs lua5.5)"
	fi

	emake -C nfq2 "${target}" \
		LUA_CFLAGS="${lua_cflags}" \
		LUA_LIB="${lua_lib}" \
		LUA_JIT=$(usex luajit 1 0)

	emake -C ip2net
	emake -C mdig
}

src_install() {
	local zd="${ED}${ZAPRET_DIR}"

	# Install binaries into binaries/my/ matching upstream layout.
	# init scripts reference $ZAPRET_BASE/nfq2/nfqws2 which resolves
	# via the symlinks upstream creates in install_bin.sh.
	exeinto "${ZAPRET_DIR}/binaries/my"
	doexe nfq2/nfqws2 ip2net/ip2net mdig/mdig

	# Symlinks: nfq2/nfqws2 -> ../binaries/my/nfqws2 etc.
	# (mirrors what install_bin.sh does with ln -fs)
	dosym ../binaries/my/nfqws2 "${ZAPRET_DIR}/nfq2/nfqws2"
	dosym ../binaries/my/ip2net "${ZAPRET_DIR}/ip2net/ip2net"
	dosym ../binaries/my/mdig   "${ZAPRET_DIR}/mdig/mdig"

	# Lua scripts
	insinto "${ZAPRET_DIR}/lua"
	doins lua/*.lua

	# Fake packet data files
	insinto "${ZAPRET_DIR}/files"
	doins -r files/fake

	# Shell library
	insinto "${ZAPRET_DIR}/common"
	doins common/*.sh

	# ipset scripts (executable)
	exeinto "${ZAPRET_DIR}/ipset"
	doexe ipset/*.sh

	# blockcheck2
	exeinto "${ZAPRET_DIR}"
	doexe blockcheck2.sh
	insinto "${ZAPRET_DIR}"
	doins -r blockcheck2.d

	# SysV init script and functions (executable)
	exeinto "${ZAPRET_DIR}/init.d/sysv"
	doexe init.d/sysv/zapret2 init.d/sysv/functions
	# custom.d placeholder so users can drop scripts there
	keepdir "${ZAPRET_DIR}/init.d/sysv/custom.d"

	# Helper install scripts
	exeinto "${ZAPRET_DIR}"
	doexe install_bin.sh install_easy.sh uninstall_easy.sh install_prereq.sh

	# Default config — user copies this to /opt/zapret2/config
	insinto "${ZAPRET_DIR}"
	doins config.default

	# Documentation
	dodoc docs/*.md

	# systemd units
	if use systemd; then
		systemd_dounit init.d/systemd/zapret2.service
		systemd_dounit init.d/systemd/zapret2-list-update.service
		systemd_dounit init.d/systemd/zapret2-list-update.timer
	fi
}

pkg_postinst() {
	elog "zapret2 has been installed to ${ZAPRET_DIR}"
	elog ""
	elog "Before starting the service, create the config file:"
	elog "  cp ${ZAPRET_DIR}/config.default ${ZAPRET_DIR}/config"
	elog "  \${EDITOR} ${ZAPRET_DIR}/config"
	elog ""
	elog "At minimum, set NFQWS2_ENABLE=1 and configure IFACE_WAN"
	elog "and NFQWS2_OPT in the config file."
	elog ""
	if use systemd; then
		elog "To enable and start the service:"
		elog "  systemctl enable --now zapret2.service"
		elog ""
		elog "To enable automatic IP/host list updates (every 2 days):"
		elog "  systemctl enable --now zapret2-list-update.timer"
		elog ""
	fi
	elog "WARNING: On package updates, ${ZAPRET_DIR}/config is"
	elog "preserved only if it already exists — it will NOT be"
	elog "overwritten by config.default. Custom scripts in"
	elog "init.d/sysv/custom.d/ are also preserved."
	elog ""
	elog "Full documentation: ${ZAPRET_DIR}/docs/"
}
