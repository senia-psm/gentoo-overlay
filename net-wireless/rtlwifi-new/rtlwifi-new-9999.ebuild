# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit linux-mod git-r3

DESCRIPTION="Newest Realtek rtlwifi"
HOMEPAGE="https://github.com/lwfinger/rtlwifi_new/tree/rtw88"

LICENSE="GPL-2 linux-firmware"
SLOT="0"
#KEYWORDS=""
IUSE="
	rtl8723de
	rtl8821ce
	rtl8822be
	rtl8822ce
"

REQUIRED_USE="|| ( ${IUSE} )"

DEPEND="
	virtual/linux-sources
	sys-apps/sed
"
RDEPEND="
	>=sys-kernel/linux-firmware-20180103-r1
"

EGIT_REPO_URI="https://github.com/lwfinger/rtlwifi_new.git"
EGIT_BRANCH="rtw88"

MODDES_LIBDIR="kernel/drivers/net/wireless/realtek/rtw88"
MODULE_NAMES="
	rtw_core(${MODDES_LIBDIR})
	rtw_pci(${MODDES_LIBDIR})
"

pkg_setup() {
	linux-mod_pkg_setup

	BUILD_TARGETS="clean all"

	use rtl8723de && MODULE_NAMES+=" rtw_8723de(${MODDES_LIBDIR})"
	use rtl8723de && MODULE_NAMES+=" rtw_8723d(${MODDES_LIBDIR})"

	use rtl8821ce && MODULE_NAMES+=" rtw_8821ce(${MODDES_LIBDIR})"
	use rtl8821ce && MODULE_NAMES+=" rtw_8821c(${MODDES_LIBDIR})"

	use rtl8822be && MODULE_NAMES+=" rtw_8822be(${MODDES_LIBDIR})"
	use rtl8822be && MODULE_NAMES+=" rtw_8822b(${MODDES_LIBDIR})"

	use rtl8822ce && MODULE_NAMES+=" rtw_8822ce(${MODDES_LIBDIR})"
	use rtl8822ce && MODULE_NAMES+=" rtw_8822c(${MODDES_LIBDIR})"
}

src_prepare() {
	sed -i 's/^KSRC.*$/KSRC\ \:= \/usr\/src\/linux/g' Makefile || die

	default
}

#src_install() {
#	linux-mod_src_install
#
#	insinto /lib/firmware/rtw88/
#	doins *.bin
#}
