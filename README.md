# Universal-iPod-Video-Converter
A free, open-source Bash utility for converting videos to formats compatible with legacy clickwheel iPods. It supports both Rockbox MPEG-1 playback and official Apple firmware H.264 playback using FFmpeg-powered, device-specific presets.

> [!NOTE]
> This tool converts videos only. It does not install Rockbox or modify your iPod's firmware.

<img width="480" height="377" alt="Usage-Example" src="https://github.com/user-attachments/assets/17179118-50a5-423d-b5ff-5bf71885a71d" />

## Features
- Supports Rockbox MPEG-1 video playback
- Supports official Apple firmware H.264 video playback
- Device-specific presets for supported iPods
- Automatic resolution and aspect ratio handling
- Batch folder conversion
- Letterbox, pillarbox, crop, and resize modes
- Audio volume boost options
- Live conversion progress with FPS, file size, and ETA
- Input validation and detailed error reporting
- Cleans up failed or corrupted output files

## Requirements
- Bash
- FFmpeg + FFprobe
- `bc`
- Tested on macOS with Bash 3.2
- Works on macOS, Linux, and Windows with a Bash environment (Git Bash/MSYS2/Cygwin)

> For official Apple firmware conversion, FFmpeg must include `libx264` support.

## Dependencies

This project relies on the following external software:

- [**Bash**](https://www.gnu.org/software/bash/)
- [**FFmpeg / FFprobe**](https://ffmpeg.org/)
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

See the [**Releases**](../../releases) page for version history.

## License

[**MIT License**](../../blob/main/LICENSE)
