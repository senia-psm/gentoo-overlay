# gentoo-overlay
Yet another Gentoo overlay

# Realtek rtlwifi
See https://github.com/lwfinger/rtlwifi_new

## Add repository with `layman`
```bash
sudo layman -o https://github.com/senia-psm/gentoo-overlay/releases/download/overlay.xml/overlay.xml -L
sudo layman -o https://github.com/senia-psm/gentoo-overlay/releases/download/overlay.xml/overlay.xml -a senia
```

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
