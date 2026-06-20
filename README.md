<img src="https://github.com/user-attachments/assets/73c3e46f-a74a-4d96-9c4f-ae30f28378be" />

# 240-MP

240-MP is a retro VCR-style Emby/Jellyfin media frontend for Raspberry Pi, preferably hooked up to a CRT TV over composite video.

This project is an Emby/Jellyfin-focused fork of [anthonycaccese/240-MP](https://github.com/anthonycaccese/240-MP). Playback experiences are handled via modules so new integrations can be added without reshaping the shell. This fork includes Local Files, Video on Demand for local Emby/Jellyfin servers, and Ambient Mode for looping video/audio ambience.

It launches [mpv](https://mpv.io/) as the playback engine. The easiest setup is to download the ready-to-flash Raspberry Pi image from the latest release, write it to an SD card, and boot the Pi. The default image is set up for CRT/composite output, GPIO IR remote support, SSH debugging, and Emby/Jellyfin use.

## Video Overview

Watch on YouTube: https://youtu.be/r-gylGDoELY

## Photos

| Module Selection | Item Detail |
| --- | --- |
| <img src="https://github.com/user-attachments/assets/9472d55a-4617-4a7f-80c4-32aa28494048" /> | <img src="https://github.com/user-attachments/assets/4f7d8230-860a-4ace-9370-9f59f43289c0" /> |

| Resume Option | Playback | Settings |
| --- | --- | --- | 
| <img src="https://github.com/user-attachments/assets/490e9ebd-fab2-4fd1-9959-35ebb619eff0" /> | <img src="https://github.com/user-attachments/assets/a3c768c7-6ede-4cdf-9d03-90aee7b8cdfb" /> | <img src="https://github.com/user-attachments/assets/0fd48977-8776-4334-b34e-d12256f23b97" /> |

## Current Features

### Local Files Module
- Supported file types: `"mp4", "mkv", "avi", "mov", "m4v", "webm", "wmv", "flv", "f4v", "mpg", "mpeg", "vob"`
- Playlist support using `m3u` and `m3u8` files
- Folder browsing
- Loop playback
- Shuffle playback
- Playback history
- Switch audio/subtitle tracks during playback

### Video on Demand Module
- Designed for CRT navigation (simple, fast, list browsing)
- Supported library types: `Movies, TV Shows, Other Videos`
- Local-only server sign in with a manually entered LAN URL
- Select specific libraries to display
- Continue Watching and Resume
- Autoplay next episode in a season (optional, off by default)
- Playlist and Collection support
- Select preferred audio/subtitle track before playback and switch tracks during playback
- Full library browsing by letter
- Show/Season browsing
- Video quality selection: Auto direct play with AV1-to-H.264 fallback, plus forced transcode options

### Ambient Mode Module
- Supported video file types: `"mp4", "mkv", "avi", "mov", "m4v", "webm", "wmv", "flv", "f4v", "mpg", "mpeg", "vob"`
- Playlist support for audio tracks using `m3u` and `m3u8` files
- Mix video with a different audio track
- Loops forever until you stop it

### Global
- Color schemes, including the Off Air CRT/static theme
- Keyboard, USB remote, and controller input support
- Settings toggle for SSH access on ready-to-flash Pi images
- Media Keys during video playback (volume +/-, mute, play/pause, stop, seek, next chapter, previous chapter)
- Local HTTP playback-control API for companion apps and voice-assistant bridges

## Install 
- [Ready-to-flash Raspberry Pi image](INSTALL.md#option-1-flash-the-ready-to-flash-image-recommended)
- [On a Raspberry Pi](INSTALL.md#on-a-raspberry-pi)
- [Build from source / local macOS testing](BUILDING.md)

## Hardware Testing
- Primary target: Raspberry Pi 4 with composite output to a CRT
- Also expected to work on Raspberry Pi OS Lite arm64 over HDMI
- Raspberry Pi 3/3B+ can work with lower playback headroom; see [BUILDING.md](BUILDING.md#video-decode-tuning-mpv_video_args)
- Raspberry Pi 5 is best treated as HDMI-first unless your composite hardware path is known-good

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full text.

You are free to use, study, and modify this code. If you distribute a modified version, you must also distribute it under GPL-3.0 and make the source available.
