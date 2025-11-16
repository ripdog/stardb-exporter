# stardb-exporter

## Instructions

This method will not work on any kind of VPN

- Download and install pcap

  - Windows: [Npcap Installer](https://npcap.com/#download) (Ensure `Install Npcap in WinPcap API-compatible mode` is ticked) \
    **Also ensure, that you're using the latest version of Npcap**
  - Linux: Figure it out, lol. The package should be called libpcap
  - Macos: Use brew https://formulae.brew.sh/formula/libpcap

- Note for WiFi users:

  - Windows: During Npcap installation, ensure `Support raw 802.11 traffic (and monitor mode) for wireless adapters` is ticked.
- Linux and Macos: Make sure you enable monitor mode for your wireless adapter.

- Download the latest release:
  - [Windows](https://github.com/juliuskreutz/stardb-exporter/releases/latest/download/stardb-exporter.exe)
  - [Linux AppImage (recommended)](https://github.com/juliuskreutz/stardb-exporter/releases/latest/download/stardb-exporter-*-x86_64.AppImage)
  - [Linux binary](https://github.com/juliuskreutz/stardb-exporter/releases/latest/download/stardb-exporter-linux)
  - [MacOs](https://github.com/juliuskreutz/stardb-exporter/releases/latest/download/stardb-exporter-macos)
- Launch the game to the point where.
  - HSR: The train is right before going into hyper speed
  - Genshin: Right before entering the door
- Execute the exporter (You might need to do this as admin/root) and wait for it to say `Device <i> ready~!`.
- Go into hyperspeed/Enter the door and it should copy the export to your clipboard.
- Paste it [here](https://stardb.gg/import).

### Linux AppImage usage

1) Download `stardb-exporter-<version>-x86_64.AppImage` from the latest release assets.  
2) Make it executable: `chmod +x ./stardb-exporter-*-x86_64.AppImage`  
3) (Recommended, so you don't need sudo) give it raw-socket capability:  
   `sudo setcap CAP_NET_RAW=+ep ./stardb-exporter-*-x86_64.AppImage`  
4) Run it: `./stardb-exporter-*-x86_64.AppImage`  
If you skip step 3, you may need to run with `sudo` for capture access.

## Building from source

For linux users, you need to set the `CAP_NET_RAW` capability

```sh
sudo setcap CAP_NET_RAW=+ep target/release/stardb-exporter
```

### Building the Linux AppImage locally

Requirements: `libpcap-dev`, `patchelf`, `libfuse2`, `curl`, `jq` and Rust.

```sh
sudo apt-get update
sudo apt-get install -y libpcap-dev patchelf libfuse2 curl jq
./scripts/build_appimage.sh
```

The resulting `stardb-exporter-<version>-x86_64.AppImage` will be in `target/`.
If you need raw socket access without running as root, give the AppImage the capability (requires sudo):

```sh
sudo setcap CAP_NET_RAW=+ep ./target/stardb-exporter-*-x86_64.AppImage
```

## Special thanks

Thank you [@IceDynamix](https://github.com/IceDynamix) for providing the building blocks for this with their [reliquary](https://github.com/IceDynamix/reliquary) project!

Thank you [@hashblen](https://github.com/hashblen) for creating protocol parsers that don't need any further updates ([auto-reliquary](https://github.com/hashblen/auto-reliquary) and [auto-artifactarium](https://github.com/hashblen/auto-artifactarium))!

Thank you [@emmachase](https://github.com/emmachase) for providing support wherever she can!
