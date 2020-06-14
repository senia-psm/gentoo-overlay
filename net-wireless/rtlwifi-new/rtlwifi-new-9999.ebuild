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
        rtl8188ee
        rtl8192ce
        rtl8192cu
        rtl8192de
        rtl8192ee
        rtl8192se
        rtl8723ae
        rtl8723be
        rtl8723de
        rtl8821ae
        rtl8822be
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

MODDES_LIBDIR="kernel/drivers/net/wireless/realtek/rtlwifi"
MODULE_NAMES="
        rtl_pci(${MODDES_LIBDIR})
        rtl_usb(${MODDES_LIBDIR})
        rtlwifi(${MODDES_LIBDIR})
        btcoexist(${MODDES_LIBDIR}/btcoexist:${S}:${S}/btcoexist)
        halmac(${MODDES_LIBDIR}/halmac:${S}:${S}/halmac)
        phydm_mod(${MODDES_LIBDIR}/phydm:${S}:${S}/phydm)
"

pkg_setup() {
        linux-mod_pkg_setup

        BUILD_TARGETS="clean all"

        use rtl8188ee && MODULE_NAMES+=" rtl8188ee(${MODDES_LIBDIR}/rtl8188ee:${S}:${S}/rtl8188ee)"

        use rtl8192ce && MODULE_NAMES+=" rtl8192ce(${MODDES_LIBDIR}/rtl8192ce:${S}:${S}/rtl8192ce)"
        use rtl8192cu && MODULE_NAMES+=" rtl8192cu(${MODDES_LIBDIR}/rtl8192cu:${S}:${S}/rtl8192cu)"
        use rtl8192ce || use rtl8192cu && MODULE_NAMES+=" rtl8192c-common(${MODDES_LIBDIR}/rtl8192c:${S}:${S}/rtl8192c)"

        use rtl8192de && MODULE_NAMES+=" rtl8192de(${MODDES_LIBDIR}/rtl8192de:${S}:${S}/rtl8192de)"
        use rtl8192ee && MODULE_NAMES+=" rtl8192ee(${MODDES_LIBDIR}/rtl8192ee:${S}:${S}/rtl8192ee)"
        use rtl8192se && MODULE_NAMES+=" rtl8192se(${MODDES_LIBDIR}/rtl8192se:${S}:${S}/rtl8192se)"

        use rtl8723ae && MODULE_NAMES+=" rtl8723ae(${MODDES_LIBDIR}/rtl8723ae:${S}:${S}/rtl8723ae)"
        use rtl8723be && MODULE_NAMES+=" rtl8723be(${MODDES_LIBDIR}/rtl8723be:${S}:${S}/rtl8723be)"
        use rtl8723de && MODULE_NAMES+=" rtl8723de(${MODDES_LIBDIR}/rtl8723de:${S}:${S}/rtl8723de)"
        use rtl8723ae || use rtl8723be || use rtl8723de && MODULE_NAMES+=" rtl8723-common(${MODDES_LIBDIR}/rtl8723com:${S}:${S}/rtl8723com)"

        use rtl8821ae && MODULE_NAMES+=" rtl8821ae(${MODDES_LIBDIR}/rtl8821ae:${S}:${S}/rtl8821ae)"
        use rtl8822be && MODULE_NAMES+=" rtl8822be(${MODDES_LIBDIR}/rtl8822be:${S}:${S}/rtl8822be)"
}

src_prepare() {
        sed -i 's/^KSRC.*$/KSRC\ \:= \/usr\/src\/linux/g' Makefile || die

        default
}

