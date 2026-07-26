# **Universal iPod Video Converter**
A terminal wizard to make videos work on any iPod, whether or not with real Apple firmware. Choose the model, the fitting mode and the volume boost you want and it creates the precise ffmpeg settings required for your device. It supports batch folders and keyboard navigation. Designed to make videos on unsupported iPods easier.

## **Features**
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

## **Requirements**
- Bash
- FFmpeg + FFprobe
- `bc`
- Tested on macOS with Bash 3.2
- Works on macOS, Linux, and Windows with a Bash environment (Git Bash/MSYS2/Cygwin)

> For official Apple firmware conversion, FFmpeg must include `libx264` support.

## **Installation**

Clone the repository:

```bash
git clone https://github.com/USERNAME/REPOSITORY.git
cd REPOSITORY
```

Make the script executable:

```bash
chmod +x ipod-video-converter.sh
```

Run the converter:

```bash
./ipod-video-converter.sh
```

## **Usage**

**1.** Select a source video file or folder
**2.** Choose an output destination
**3.** Select the target firmware:
   - Rockbox
   - Official Apple firmware
**4.** Select your iPod model
**5.** Choose video fitting mode
**6.** Choose audio settings
**7.** Wait for conversion to finish

**__The converter will automatically generate a video optimized for your selected iPod.__**

## **Supported Devices**

### **Rockbox**

| Device | Resolution | Format |
| --- | --- | --- |
| iPod Mini (1st/2nd Gen) | 138×110 | MPEG-1 `.mpg` |
| iPod Nano (1st/2nd Gen) | 176×132 | MPEG-1 `.mpg` |
| iPod 4th Gen Monochrome | 160×128 | MPEG-1 `.mpg` |
| iPod Color/Photo (4th Gen) | 220×176 | MPEG-1 `.mpg` |
| iPod Video (5th/5.5 Gen) | 320×240 | MPEG-1 `.mpg` |
| iPod Classic (6th/6.5/7th Gen) | 320×240 | MPEG-1 `.mpg` |

### **Official Apple Firmware**

| Device | Resolution | Format |
| --- | --- | --- |
| iPod Video (5th/5.5 Gen) | 320×240 | H.264/AAC `.m4v` |
| iPod Classic (6th/6.5/7th Gen) | 320×240 | H.264/AAC `.m4v` |
| iPod Nano (3rd/4th Gen) | 320×240 | H.264/AAC `.m4v` |
| iPod Nano (5th Gen) | 376×240 | H.264/AAC `.m4v` |
| iPod Nano (7th Gen) | 432×240 | H.264/AAC `.m4v` |

## **Notes**

- This tool only converts videos. It does **not** install Rockbox or modify iPod firmware.
- Rockbox mode creates files for the Rockbox `mpegplayer` plugin.
- Official firmware mode creates `.m4v` files intended for Apple-compatible syncing.
- iPod Nano 6th Gen is not supported because it removed video playback.
- All iPod Touch models are not supported, this tool is only for legacy clickwheel iPods

## **Troubleshooting**

### **FFmpeg is missing**

Install FFmpeg:

**macOS:**

```bash
brew install ffmpeg
```

**Linux:**

```bash
sudo apt install ffmpeg
```

### **Official firmware conversion fails**

Check that your FFmpeg build includes `libx264`:

```bash
ffmpeg -encoders | grep libx264
```

### **The script says it is corrupted**

The converter performs a syntax check before running.

If it detects corrupted quotes or invalid syntax:

1. Download a fresh copy
2. Avoid editing `.sh` files in TextEdit, Notes, or Pages
3. Use a plain-text editor such as VS Code, BBEdit, or nano

## **Changelog**

See the [Releases](../../releases) page for version history.

## **License**

**__MIT License__**
