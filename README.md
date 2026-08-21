# Universal iPod Video Converter
A free, open-source Bash utility for converting videos to formats compatible with legacy clickwheel iPods. It supports both Rockbox MPEG-1 playback and official Apple firmware H.264 playback using FFmpeg-powered, device-specific presets.

<img alt="Static Badge" src="https://img.shields.io/badge/github-Universal%20iPod%20Video%20Converter-green?logo=github"> <img alt="GitHub top language" src="https://img.shields.io/github/languages/top/Mochagoma/Universal-iPod-Video-Converter"> <img alt="GitHub Downloads (all assets, all releases)" src="https://img.shields.io/github/downloads/Mochagoma/Universal-iPod-Video-Converter/total?color=9d00ff"> <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Mochagoma/Universal-iPod-Video-Converter?style=flat&color=%23FFFF00&"> <img alt="GitHub Release" src="https://img.shields.io/github/v/release/Mochagoma/Universal-iPod-Video-Converter">

> [!NOTE]
> This tool converts videos only. It does not install Rockbox or modify your iPod's firmware.
<p align="center">
  <img width="480" height="377" alt="Usage-Example" src="https://github.com/user-attachments/assets/17179118-50a5-423d-b5ff-5bf71885a71d" />
</p>

<p>&nbsp;</p>

<details>
<summary><strong>Table of Contents</strong></summary>

  - [Features](#features)
  - [Requirements](#requirements)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Install FFmpeg](#install-ffmpeg)
      - [macOS](#macos)
      - [Linux](#linux)
    - [Install yt-dlp](#install-yt-dlp)
  - [Usage](#usage)
  - [Supported Devices](#supported-devices)
    - [Rockbox](#rockbox)
    - [Official Apple Firmware](#official-apple-firmware)
  - [Notes](#notes)
  - [Troubleshooting](#troubleshooting)
    - [FFmpeg is missing](#ffmpeg-is-missing)
      - [macOS](#macos-1)
      - [Linux](#linux-1)
    - [yt-dlp downloads are unavailable](#yt-dlp-downloads-are-unavailable)
    - [Official firmware conversion fails](#official-firmware-conversion-fails)
    - [The script says it is corrupted](#the-script-says-it-is-corrupted)
  - [Changelog](#changelog)
  - [License](#license)

</details>

## Features
- Supports Rockbox MPEG-1 video playback
- Supports official Apple firmware H.264 video playback
- Downloads and converts YouTube videos and playlists using `yt-dlp`
- Device-specific presets for supported iPods
- Automatic resolution and aspect ratio handling
- Batch folder conversion
- Letterbox, pillarbox, crop, and resize modes
- Audio volume boost options
- Live conversion progress with FPS, file size, and ETA
- YouTube video and playlist downloads using `yt-dlp`
- YouTube download progress with percentage, speed, size, and ETA
- Input validation and detailed error reporting
- Cleans up failed or corrupted output files

## Requirements
- Bash
- FFmpeg + FFprobe
- `bc`
- `yt-dlp` for YouTube video or playlist downloads
- Tested on macOS with Bash 3.2
- Works on macOS, Linux, and Windows with a Bash environment (Git Bash/MSYS2/Cygwin)

> For official Apple firmware conversion, FFmpeg must include `libx264` support.

## Dependencies

This project relies on the following external software:

- [Bash](https://www.gnu.org/software/bash/)
- [FFmpeg / FFprobe](https://ffmpeg.org/)
- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) for YouTube downloads
- `bc`
- Standard Unix command-line utilities:
  - `find`
  - `grep`
  - `sed`
  - `stat`
  - `mktemp`
  - `tput`

These dependencies are not included with this project and remain licensed separately under their respective licenses.

## Installation

Clone the repository:

```bash
git clone https://github.com/mochagoma/Universal-iPod-Video-Converter.git
cd Universal-iPod-Video-Converter
```

### Install FFmpeg

#### macOS

If you already have Homebrew installed:

```bash
brew install ffmpeg
```

If you don't have Homebrew installed:

1. Install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install FFmpeg:

```bash
brew install ffmpeg
```

#### Linux

```bash
sudo apt install ffmpeg
```

### Install yt-dlp

Install `yt-dlp` if you plan to download videos or playlists from YouTube.

#### macOS

```bash
brew install yt-dlp
```

#### Linux

```bash
sudo apt install yt-dlp
```

If your package manager does not provide `yt-dlp`:

```bash
python3 -m pip install --user yt-dlp
```

The script checks for `yt-dlp` only when the YouTube option is selected, so it is not required for local conversion.

Make the script executable:

```bash
chmod +x Uni-iPod-Converter.sh
```

Run the converter:

```bash
./Uni-iPod-Converter.sh
```

## Usage

**1.** Select a source video file or folder

**2.** Choose an output destination

**3.** Select the target firmware:
- Rockbox
- Official Apple firmware

**4.** Select your iPod model

**5.** Choose video fitting mode

**6.** Choose audio settings

**7.** Wait for conversion to finish

To download from YouTube, select the YouTube option at the source menu, then enter a video or playlist URL. All conversion settings are chosen before the download begins. Videos from a playlist are converted through the same batch pipeline as a local folder.

**The converter will automatically generate a video optimized for your selected iPod.**

## Supported Devices

### Rockbox

| Device | Resolution | Format |
| --- | --- | --- |
| iPod Mini (1st/2nd Gen) | 138×110 | MPEG-1 `.mpg` |
| iPod Nano (1st/2nd Gen) | 176×132 | MPEG-1 `.mpg` |
| iPod 4th Gen Monochrome | 160×128 | MPEG-1 `.mpg` |
| iPod Color/Photo (4th Gen) | 220×176 | MPEG-1 `.mpg` |
| iPod Video (5th/5.5 Gen) | 320×240 | MPEG-1 `.mpg` |
| iPod Classic (6th/6.5/7th Gen) | 320×240 | MPEG-1 `.mpg` |

### Official Apple Firmware

| Device | Resolution | Format |
| --- | --- | --- |
| iPod Video (5th/5.5 Gen) | 320×240 | H.264/AAC `.m4v` |
| iPod Classic (6th/6.5/7th Gen) | 320×240 | H.264/AAC `.m4v` |
| iPod Nano (3rd/4th Gen) | 320×240 | H.264/AAC `.m4v` |
| iPod Nano (5th Gen) | 376×240 | H.264/AAC `.m4v` |
| iPod Nano (7th Gen) | 432×240 | H.264/AAC `.m4v` |

## Notes

- This tool only converts videos. It does **not** install Rockbox or modify iPod firmware.
- Rockbox mode creates files for the Rockbox `mpegplayer` plugin.
- Official firmware mode creates `.m4v` files intended for Apple-compatible syncing.
- YouTube downloads require an internet connection and `yt-dlp`.
- YouTube playlists are treated as batch conversions, with each downloaded item converted separately.
- iPod Nano 6th Gen is not supported because it removed video playback.
- All iPod Touch models are not supported; this tool only supports legacy clickwheel iPods.

## Troubleshooting

### FFmpeg is missing

#### macOS

If you already have Homebrew installed:

```bash
brew install ffmpeg
```

If you don't have Homebrew installed:

1. Install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install FFmpeg:

```bash
brew install ffmpeg
```

#### Linux

```bash
sudo apt install ffmpeg
```

### yt-dlp downloads are unavailable

Check that `yt-dlp` is installed and available on your `PATH`:

```bash
yt-dlp --version
```

If it is missing or outdated:

```bash
python3 -m pip install --user --upgrade yt-dlp
```

YouTube URLs must begin with `http://` or `https://`.

### Official firmware conversion fails

Check that your FFmpeg build includes `libx264`:

```bash
ffmpeg -encoders | grep libx264
```

### The script says it is corrupted

The converter performs a syntax check before running.

If it detects corrupted quotes or invalid syntax:

1. Download a fresh copy.
2. Avoid editing `.sh` files in TextEdit, Notes, or Pages.
3. Use a plain-text editor such as VS Code, BBEdit, or nano.

## Changelog

See the [Releases](../../releases) page for version history.

## License

[MIT License](../../blob/main/LICENSE)
# Universal iPod Video Converter

A free, open-source Bash utility for converting videos into formats compatible with legacy clickwheel iPods. It supports both Rockbox MPEG-1 playback and official Apple firmware H.264 playback using FFmpeg-powered, device-specific presets.

> [!NOTE]
> This tool converts videos only. It does not install Rockbox or modify your iPod's firmware.

## Features

- Supports Rockbox MPEG-1 video playback
- Supports official Apple firmware H.264/AAC video playback
- Downloads and converts YouTube videos and playlists with `yt-dlp`
- Device-specific presets for supported iPods
- Automatic resolution and aspect-ratio handling
- Batch folder conversion
- Letterbox, pillarbox, crop, and resize modes
- Audio volume boost options
- Live conversion and YouTube download progress with percentage, speed, size, and ETA
- Playlist item progress labels during YouTube downloads
- Detailed validation and error reporting
- Temporary-download cleanup and failed-output cleanup
- Completion summary with converted file sizes and total elapsed time

## Requirements

- Bash
- FFmpeg and FFprobe
- `bc`
- `yt-dlp` for YouTube video or playlist downloads
- Tested on macOS with Bash 3.2
- Works on macOS, Linux, and Windows with a Bash environment such as Git Bash, MSYS2, or Cygwin

> For official Apple firmware conversion, FFmpeg must include `libx264` support.

## Dependencies

This project relies on the following external software:

- [Bash](https://www.gnu.org/software/bash/)
- [FFmpeg / FFprobe](https://ffmpeg.org/)
- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) for YouTube downloads
- `bc`
- Standard Unix command-line utilities:
  - `find`
  - `grep`
  - `sed`
  - `stat`
  - `mktemp`
  - `tput`

These dependencies are not included with this project and remain licensed separately under their respective licenses.

## Installation

Clone the repository:

```bash
git clone https://github.com/mochagoma/Universal-iPod-Video-Converter.git
cd Universal-iPod-Video-Converter
```

Make the script executable:

```bash
chmod +x Uni-iPod-Converter.sh
```

### Install FFmpeg and bc

#### macOS

With Homebrew:

```bash
brew install ffmpeg bc
```

If Homebrew is not installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ffmpeg bc
```

#### Debian or Ubuntu Linux

```bash
sudo apt update
sudo apt install ffmpeg bc
```

### Install yt-dlp

Install `yt-dlp` if you plan to download from YouTube.

#### macOS with Homebrew

```bash
brew install yt-dlp
```

#### Debian or Ubuntu Linux

```bash
sudo apt install yt-dlp
```

If your distribution does not provide a current package:

```bash
python3 -m pip install --user yt-dlp
```

The converter checks for `yt-dlp` only when the YouTube source option is selected, so it is not required for local-file conversion.

## Usage

Run the converter:

```bash
./Uni-iPod-Converter.sh
```

The wizard guides you through the following steps:

1. Choose a local video or folder, or select YouTube video/playlist download.
2. Enter the source path or YouTube URL.
3. Choose an output destination.
4. Select Rockbox or official Apple firmware.
5. Select your iPod model.
6. Choose a video fitting mode.
7. Choose an audio volume setting.
8. Wait for the download, if applicable, and conversion to finish.

For YouTube downloads, the script asks all conversion settings before downloading. The downloaded files then pass through the same batch conversion pipeline used for local folders.

## Supported Devices

### Rockbox

| Device | Resolution | Format |
| --- | --- | --- |
| iPod Mini (1st/2nd Gen) | 138x110 | MPEG-1 `.mpg` |
| iPod Nano (1st/2nd Gen) | 176x132 | MPEG-1 `.mpg` |
| iPod 4th Gen Monochrome | 160x128 | MPEG-1 `.mpg` |
| iPod Color/Photo (4th Gen) | 220x176 | MPEG-1 `.mpg` |
| iPod Video (5th/5.5 Gen) | 320x240 | MPEG-1 `.mpg` |
| iPod Classic (6th/6.5/7th Gen) | 320x240 | MPEG-1 `.mpg` |

### Official Apple Firmware

| Device | Resolution | Format |
| --- | --- | --- |
| iPod Video (5th/5.5 Gen) | 320x240 | H.264/AAC `.m4v` |
| iPod Classic (6th/6.5/7th Gen) | 320x240 | H.264/AAC `.m4v` |
| iPod Nano (3rd/4th Gen) | 320x240 | H.264/AAC `.m4v` |
| iPod Nano (5th Gen) | 376x240 | H.264/AAC `.m4v` |
| iPod Nano (7th Gen) | 432x240 | H.264/AAC `.m4v` |

## Notes

- Rockbox mode creates files for the Rockbox `mpegplayer` plugin.
- Official firmware mode creates `.m4v` files intended for Apple-compatible syncing.
- iPod Nano 6th Gen is not supported because it removed video playback.
- iPod Touch models are not supported; this tool targets legacy clickwheel iPods.
- YouTube downloads require an internet connection and a working `yt-dlp` installation.
- A YouTube playlist is treated as a batch conversion and each downloaded item is converted separately.

## Troubleshooting

### FFmpeg or FFprobe is missing

Install FFmpeg using your operating system's package manager:

```bash
# macOS
brew install ffmpeg

# Debian or Ubuntu Linux
sudo apt install ffmpeg
```

### YouTube downloads are unavailable

Check that `yt-dlp` is installed and available on your `PATH`:

```bash
yt-dlp --version
```

Then install or update it:

```bash
python3 -m pip install --user --upgrade yt-dlp
```

A YouTube URL must begin with `http://` or `https://`.

### Official firmware conversion fails

Check that your FFmpeg build includes `libx264`:

```bash
ffmpeg -encoders | grep libx264
```

If no result appears, install a full FFmpeg build or reinstall FFmpeg through your package manager.

### The script says it is corrupted

The converter performs a syntax check before running. If it detects corrupted quotes or invalid syntax:

1. Download a fresh copy.
2. Avoid editing `.sh` files in TextEdit, Notes, or Pages.
3. Use a plain-text editor such as VS Code, BBEdit, or nano.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the current release notes or visit the [Releases](../../releases) page for version history.

## License

[MIT License](../../blob/main/LICENSE)
