# gentoo-overlay
Yet another Gentoo overlay

# Realtek rtlwifi
See https://github.com/lwfinger/rtlwifi_new

## Add repository with `eselect repository`
```bash
sudo eselect repository add senia git https://github.com/senia-psm/gentoo-overlay.git
sudo emaint sync -r senia
```
See more in [Gentoo Wiki: eselect/repository](https://wiki.gentoo.org/wiki/Eselect/Repository).

## Allow `**` for `rtlwifi-new`
```bash
echo '=net-wireless/rtlwifi-new-9999::senia **' | sudo tee -a /etc/portage/package.keywords/wifi
```

## Add use flags for your drivers
For instance for driver `rtl8723de`:
```bash
echo 'net-wireless/rtlwifi-new rtl8723de' | sudo tee -a /etc/portage/package.use/wifi
```

## Install
```bash
emerge net-wireless/rtlwifi-new
```
