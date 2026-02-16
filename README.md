YouTube.pak
Lightweight YouTube browser for TrimUI devices

==================================================
DESCRIPTION
==================================================

YouTube.pak is a lightweight YouTube browser designed
for TrimUI handheld devices. It supports video search,
channel subscriptions, streaming via MPV, and downloading
videos directly to your SD card.

The interface is optimized for performance and stability
without heavy UI elements such as icons or overlays.

==================================================
INSTALLATION
==================================================

Manual Installation

1. Copy folder:

   YouTube.pak

   to:

   /Tools/tg5040/YouTube.pak

   on your SD Card.


2. MPV.pak is REQUIRED for streaming

   Download from:
   https://github.com/tenlevels/PakUI

   Then copy:

   Emus/tg5040/MPV.pak

   to:

   /Emus/MPV.pak

   on your SD Card.


3. Create media folder:

   /Roms/Media Player (MPV)


==================================================
COMPATIBILITY
==================================================

Works on:

- Stock OS
- MinUI
- NextUI
- PakUI

As long as folder locations are correct.


==================================================
IMPORTANT NOTES
==================================================

* Streaming feature requires MPV.pak installed.
** Streaming from search results redirects to MPV player.
*** Download may fail if Media Player (MPV) folder does not exist.


==================================================
FEATURES
==================================================

--------------------------------------------------
Search Video
--------------------------------------------------

- Search YouTube directly from device
- Displays top 5 results
- Instant streaming support
- Download videos up to 1080p (MP4 AVC1)

--------------------------------------------------
Channel Subscription
--------------------------------------------------

- Add custom YouTube channels
- Auto handle detection (@channel)
- Clean display names
- Prevent duplicate entries

Channel menu options:

Get Last Five Videos
Download Latest Video


--------------------------------------------------
Streaming Mode
--------------------------------------------------

Press Y on search results.

Uses MPV player with smart stream selector:

AVC1 ≤1080p preferred
Fallback ≤720p

Optimized to avoid lag on TrimUI hardware.


--------------------------------------------------
Download Mode
--------------------------------------------------

Videos downloaded as:

MP4 (AVC1 + MP4A)
Max 1080p

Saved to:

/Roms/Media Player (MPV)


--------------------------------------------------
Tools Menu (Press Y on Main Menu)
--------------------------------------------------

Add New Channel
Remove Channel
Update yt-dlp


Add Channel accepts:

Channel Name
@Handle
Full YouTube URL

Auto features:

- Adds @handle automatically
- Formats display name
- Prevent duplicate channel


==================================================
CONTROLS
==================================================

Main Menu

D-Pad : Navigate
A      : Select
B      : Back / Exit
Y      : Open Tools Menu


Search Results

A : Open Info / Download
Y : Stream Video
B : Back


Channel Menu

A : Select Option
B : Back


==================================================
FOLDER STRUCTURE
==================================================

Tools/
 └── tg5040/
     └── YouTube.pak

Emus/
 └── MPV.pak

Roms/
 └── Media Player (MPV)/


==================================================
TECHNICAL NOTES
==================================================

- Uses yt-dlp for video extraction
- Streaming handled via MPV.pak
- No heavy UI elements (icons/logos disabled)
- Optimized for low CPU usage


==================================================
TROUBLESHOOTING
==================================================

Stream returns to list:

Check:
 /Emus/MPV.pak exists


Download finished but file missing:

Ensure folder exists:
 /Roms/Media Player (MPV)


Channel shows empty videos:

Make sure channel handle is valid:
 @channelname


==================================================
CREDITS
==================================================

yt-dlp project
MPV Player
PakUI by tenlevels

==================================================
