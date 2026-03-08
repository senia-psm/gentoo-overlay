# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

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

	emake -C ip2net "${target}"
	emake -C mdig "${target}"
}

src_install() {
	dosbin nfq2/nfqws2
	dobin ip2net/ip2net
	dobin mdig/mdig

	insinto /usr/share/${PN}
	doins -r lua files
	doins config.default

	dodoc docs/*.md
}
