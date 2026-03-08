# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# LuaJIT is supported via lua_single_target_luajit USE flag
LUA_COMPAT=( lua5-{3..4} luajit )

inherit linux-info lua-single systemd

DESCRIPTION="Anti-DPI tool to bypass HTTP(S)/VPN blocking and throttling"
HOMEPAGE="https://github.com/bol-van/zapret2"
SRC_URI="https://github.com/bol-van/zapret2/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="systemd"

REQUIRED_USE="${LUA_REQUIRED_USE}"

BDEPEND="
	virtual/pkgconfig
"
DEPEND="
	${LUA_DEPS}
	net-libs/libnetfilter_queue
	net-libs/libnfnetlink
	net-libs/libmnl
	sys-libs/zlib
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}"

ZAPRET_DIR=/opt/zapret2

# Mandatory: NFQUEUE — the core packet interception mechanism.
# Either the nftables or iptables NFQUEUE target must be enabled.
# nf_conntrack is required for per-flow packet counting in firewall rules.
# NFT_FLOW_OFFLOAD is optional: only needed when FLOWOFFLOAD=software/hardware.
CONFIG_CHECK="
	~NETFILTER
	~NF_CONNTRACK
	~NF_CONNTRACK_MARK
	~NF_TABLES
	~NF_TABLES_INET
	~NFT_CT
	~NFT_FLOW_OFFLOAD
	~NFT_QUEUE
	~NETFILTER_XT_TARGET_NFQUEUE
	~NETFILTER_XT_MATCH_CONNBYTES
	~SECCOMP
	~SECCOMP_FILTER
"

ERROR_NFT_QUEUE="
	CONFIG_NFT_QUEUE (nftables NFQUEUE target) is not set.
	nfqws2 needs at least one of CONFIG_NFT_QUEUE or
	CONFIG_NETFILTER_XT_TARGET_NFQUEUE to intercept packets.
	If you use iptables instead of nftables, this warning can be ignored.
"
ERROR_NETFILTER_XT_TARGET_NFQUEUE="
	CONFIG_NETFILTER_XT_TARGET_NFQUEUE (iptables NFQUEUE target) is not set.
	nfqws2 needs at least one of CONFIG_NFT_QUEUE or
	CONFIG_NETFILTER_XT_TARGET_NFQUEUE to intercept packets.
	If you use nftables instead of iptables, this warning can be ignored.
"
ERROR_NF_CONNTRACK="
	CONFIG_NF_CONNTRACK is not set. Connection tracking is required
	for per-flow packet counting in nftables (ct original packets)
	or iptables (connbytes) firewall rules.
"

ERROR_NF_TABLES_INET="
	CONFIG_NF_TABLES_INET is not set. The nftables inet address family
	is required for combined IPv4/IPv6 firewall rules.
	If you use iptables instead of nftables, this warning can be ignored.
"

ERROR_NFT_FLOW_OFFLOAD="
	CONFIG_NFT_FLOW_OFFLOAD is not set. This is only needed when
	FLOWOFFLOAD=software or FLOWOFFLOAD=hardware is set in the config.
	If you do not use flow offloading, this warning can be ignored.
"

pkg_setup() {
	lua-single_pkg_setup
	linux-info_pkg_setup
}

src_compile() {
	local target="all"
	use systemd && target="systemd"

	local lua_jit=0
	[[ ${ELUA} == luajit ]] && lua_jit=1

	emake -C nfq2 "${target}" \
		LUA_CFLAGS="$(lua_get_CFLAGS)" \
		LUA_LIB="$(lua_get_LIBS)" \
		LUA_JIT=${lua_jit}

	emake -C ip2net
	emake -C mdig
}

src_install() {
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

	# Config file: installed to /etc/zapret2/config (CONFIG_PROTECT-ed),
	# symlinked from /opt/zapret2/config for non-systemd consumers.
	insinto /etc/zapret2
	newins config.default config
	dosym /etc/zapret2/config "${ZAPRET_DIR}/config"

	# Also keep config.default in place for reference
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
	elog "The config file is at /etc/zapret2/config (symlinked as"
	elog "${ZAPRET_DIR}/config). Edit it before starting the service:"
	elog "  \${EDITOR} /etc/zapret2/config"
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
	elog "On package updates, /etc/zapret2/config is protected by"
	elog "Portage's CONFIG_PROTECT mechanism — your edits will not"
	elog "be overwritten. Use dispatch-conf or etc-update to merge"
	elog "any new defaults after an upgrade."
	elog ""
	elog "Full documentation: ${ZAPRET_DIR}/docs/"
}
