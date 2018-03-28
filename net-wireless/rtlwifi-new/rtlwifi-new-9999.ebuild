# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit linux-mod git-r3

DESCRIPTION="Newest Realtek rtlwifi"
HOMEPAGE="https://github.com/lwfinger/rtlwifi_new/tree/extended"

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

REQUIRED_USE="|| (  )"

DEPEND="
        virtual/linux-sources
        sys-apps/sed
"
RDEPEND="
        >=sys-kernel/linux-firmware-20180103-r1
"

EGIT_REPO_URI="https://github.com/lwfinger/rtlwifi_new.git"
EGIT_BRANCH="extended"

MODDES_LIBDIR="kernel/drivers/net/wireless/realtek/rtlwifi"
MODULE_NAMES="
        rtl_pci()
        rtl_usb()
        rtlwifi()
        btcoexist(/btcoexist::/btcoexist)
        halmac(/halmac::/halmac)
        phydm_mod(/phydm::/phydm)
"

pkg_setup() {
        linux-mod_pkg_setup

        BUILD_TARGETS="clean all"

        use rtl8188ee && MODULE_NAMES+=" rtl8188ee(/rtl8188ee::/rtl8188ee)"

        use rtl8192ce && MODULE_NAMES+=" rtl8192ce(/rtl8192ce::/rtl8192ce)"
        use rtl8192cu && MODULE_NAMES+=" rtl8192cu(/rtl8192cu::/rtl8192cu)"
        use rtl8192ce || use rtl8192cu && MODULE_NAMES+=" rtl8192c-common(/rtl8192c::/rtl8192c)"

        use rtl8192de && MODULE_NAMES+=" rtl8192de(/rtl8192de::/rtl8192de)"
        use rtl8192ee && MODULE_NAMES+=" rtl8192ee(/rtl8192ee::/rtl8192ee)"
        use rtl8192se && MODULE_NAMES+=" rtl8192se(/rtl8192se::/rtl8192se)"

        use rtl8723ae && MODULE_NAMES+=" rtl8723ae(/rtl8723ae::/rtl8723ae)"
        use rtl8723be && MODULE_NAMES+=" rtl8723be(/rtl8723be::/rtl8723be)"
        use rtl8723de && MODULE_NAMES+=" rtl8723de(/rtl8723de::/rtl8723de)"
        use rtl8723ae || use rtl8723be || use rtl8723de && MODULE_NAMES+=" rtl8723-common(/rtl8723com::/rtl8723com)"

        use rtl8821ae && MODULE_NAMES+=" rtl8821ae(/rtl8821ae::/rtl8821ae)"
        use rtl8822be && MODULE_NAMES+=" rtl8822be(/rtl8822be::/rtl8822be)"
}

src_prepare() {
        sed -i 's/^KSRC.*$/KSRC\ \:= \/usr\/src\/linux/g' Makefile || die

        default
}
