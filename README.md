# iPlayr

A faithful iPod classic recreation for iOS, built entirely in SwiftUI on top of Apple Music.

Not an iPod-*inspired* player: the click wheel drives every interaction, the menu keeps its
split-screen artwork pane, and the interface colours are sampled from the original iPod artwork
rather than eyeballed.

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)

<div align="center">
  <img src="https://github.com/user-attachments/assets/5ba23608-a129-43af-8e5a-40420519c92c" width="200" />
  <img src="https://github.com/user-attachments/assets/bd7c1f93-0704-4079-af60-5928f0042f54" width="200" />
  <img src="https://github.com/user-attachments/assets/ce615eb9-0662-4f1a-953a-cd76972d2c66" width="200" />
  <img src="https://github.com/user-attachments/assets/3c4a05a6-f250-46cd-8206-04ecc6ea716a" width="200" />
</div>

<div align="center">
  <img src="https://github.com/user-attachments/assets/07fd3811-a954-42f9-83fe-9dc0c5ce4cac" width="840" height="348" />
</div>

## Features

- **Click wheel** — rotate your thumb to scroll, with selection haptics and the original click
  sound. MENU goes back one screen; hold it to jump to the main menu.
- **Split-screen menus** — the artwork pane on the right slowly pans through your album covers,
  just like the 6th generation did.
- **Cover Flow** — flick through your albums in 3D and flip a cover to see its tracks.
- **Now Playing** — scrubbing progress, track skipping, and press-and-hold seeking. Once music is
  playing, a *Now Playing* row appears in the menus to take you back to it.
- **Themes** — silver, black and U2 Special Edition.
- **Your Apple Music library** — albums, playlists and their tracks.

## Requirements

- Xcode 16 or later
- iOS 17.0+
- An active Apple Music subscription
- A physical device is recommended — music playback and battery reporting are limited in the
  simulator

## Getting started

```bash
git clone https://github.com/keremersu35/iPodPlayer.git
cd iPodPlayer/iPlayr
open iPlayr.xcodeproj
```

Set your own signing team, then run. On first launch the app asks for Apple Music access — grant it
from the Sign In menu entry.

## Contributing

Issues and pull requests are welcome. Please keep changes focused and match the surrounding style.
