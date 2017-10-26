# photon-metronome
Say hello to a wireless metronome that syncs to MIDI signals!

## Why?
Sometimes it's hard to hear on stage. Sound checks may be rushed, monitors may be of poor quality, or the hall itself may not be designed acoustically. When singing to a background track, timing is crucial. This wireless metronome serves to help keep people in sync—at the speed of light—by providing a visual reference (akin to its conception in Karnātik music).

## Setup
The metronome works by sending MIDI signals to a small microprocessor over Wi-Fi. A Java program runs locally on the person's machine listening to the MIDI messages and sends RGB values for the LED as UDP packets through a router. After initial setup, **internet itself is not required during use** which makes the metronome remarkably resilient for stage use. Any simple 802.11 b/g router can provide the Wireless conduit between the machine and the LED board, making something like the 2004 Apple AirPort Express an especially elegant and portable solution.

Components include:
* a computer, assumed to be a laptop
* a [Particle Photon Wi-Fi Microprocessor](https://store.particle.io/products/photon) (formerly called Spark Core) as the [IOT](https://en.wikipedia.org/wiki/Internet_of_things) wireless LED device
* a 802.11 b/g router connecting the two
* software like [Abelton Live](https://www.ableton.com/en/live/) or similar for generating MIDI [MIDI](https://en.wikipedia.org/wiki/MIDI) signals
* a virtual MIDI device for piping the MIDI signals from the DAW to the processing application, e.g. using Apple's built-in IAC driver ([Inter Application Communication](https://developer.apple.com/legacy/library/documentation/mac/pdf/Interapplication_Communication/Intro_to_IAC.pdf)) part of Audio MIDI Setup in Utilities
* a [Processing](https://processing.org) script that can run as a standalone executable that listens to the MIDI signals and sends them to the IOT device over Wi-Fi

## Demos
### 2017-08-15 Visual Metronome Prototype with Ableton Live
Demo track "Ya Devi" by [Sanchit Malhotra](https://www.youtube.com/channel/UCP5zbHm0cLnCYuJd3LlvRZA) from the album Yuva Rhythms: Jagat Janani. Visit https://chykwest.com/yuvarhythms
[![Visual Metronome Prototype with Ableton Live](https://i.imgur.com/fBfgpN0.png)](https://vimeo.com/229690607/b6a2fa1b06 "2017-08-15 Visual Metronome Prototype with Ableton Live")

## Newb Epiphanies/Discoveries

### Particle Board
* Can't flash DFU firmware if the USB cable doesn't have data pins (looking at you portable USB power bank cables) https://community.particle.io/t/solved-dfu-util-no-dfu-capable-usb-device-available/33011/3
* If you switch the firmware into `SEMI_AUTOMATIC` mode, and don't call `connect()` then it will never connect to a router. `Particle.connect()` is for Wi-Fi + Internet and `WiFi.connect()` is only for Wi-Fi. https://community.particle.io/t/wifi-but-no-internet/18479/3
* The WiFi connection info indeed persists between reboots!
* The Photon's DeviceID is specified at http://build.particle.io even when the device is offline. Needed for flashing DFU firmware via the CLI manually via `particle flash`.

### SSDs Help Prevent Dropped Packets
Heavy project files (large number of stemmed tracks, effects, etc.) creates in high I/O to the hard drive. In such cases, UDP packets seem to be dropping on the computer side and never get sent to the device!! This results in either the click never being sent, or the signal to turn the LED back to black to not be sent, etc. Using an SSD has not yet exhibited these problems.

## How to Setup the Particle Photon with an AirPort Express
### Flashing the Firmware over USB
* Plug board into computer's USB. Brand new devices will already be flashing blue (listening mode). If device is solid cyan, push and hold setup for approx 3 seconds to go solid blue.
* Plug Airport Express in. Internet is required for initial setup, so connect it to an actual network via Ethernet cable. LED should go from flashing yellow to solid green.
* Connect laptop to the Airport Express network and verify internet is working
* We'll be setting up over USB. Visit https://docs.particle.io/guide/getting-started/connect/photon/ for an overview
* Open Terminal and type `particle setup` to login with your credentials, creating one if necessary
* It should detect the device saying `I have detected a Photon connected via USB.` If not, double check the USB cable actually supports data and not just power! Select the detected Photon device and continue.
* Answer Yes to `Shall I have the Photon scan for available Wi-Fi networks?`
* Select the Airport Express' wireless network. Autodetect security type and enter the password.
* Photon will now reboot. Menu screen changes to `It doesn't look like your Photon has made it to the cloud yet.` Once the device LED is solid cyan, select `Check again to see if the Photon has connected`
* Name your photon (e.g. `metronome-ninja`)
* Installer exits. Now it's time update the firmware so we don't check the internet on startup anymore.
* To flash the new firmware over USB, we'll be following this guide https://docs.particle.io/guide/tools-and-features/cli/core/#update-your-device-remotely
* Download the photon-metronome firmware from GitHub https://raw.githubusercontent.com/NaanProphet/photon-metronome/master/visualmetronome.ino
* Compile/valide source (optional) `particle compile core visualmetronome.ino`
* Flash from source `particle flash my_device_name visualmetronome.ino` where `my_device_name` is the same one we named before. To confirm type `particle list`
* That's it!

### Helpful tips
* Use KisMac2 to detect WiFi networks
* Use Angry IP Scanner to view devices on the network. (May have to scan a few times before it starts detecting properly.) Photon devices are under MAC Vendor of `Universal Global Scientific
* Can self-assign the laptop's IP so it never conflicts—just have to remember to change TCP settings back to DHCP afterwards. E.g. 10.0.1.1 is the base station, so setting the laptop to 10.0.1.9 will leave 2-8 for Photon devices. Default subnet mask is 255.255.255.0


### Troubleshooting
If you brick it:
* Boot into DFU mode and use dfu-util method following this guide https://docs.particle.io/faq/particle-devices/led-troubleshooting/photon/#manual-firmware-update
* If the device is still flashing yellow after restarting, then issue `particle update`

## References
* How to Build a Wireless Visual Metronome that Synchronizes with your DAW https://ask.audio/articles/how-to-build-a-wireless-visual-metronome-that-synchronizes-with-your-daw
* Using virtual MIDI buses in Live https://help.ableton.com/hc/en-us/articles/209774225-Using-virtual-MIDI-buses-in-Live)
* Manually Assigning MIDI Values in Ableton Live https://www.youtube.com/watch?v=e5kcaVfjqf4)
* MIDI Control Change Messages – Continuous Controllers http://nickfever.com/music/midi-cc-list
* Embedding video in Markdown https://stackoverflow.com/questions/11804820/embed-a-youtube-video
* Ableton Download Archive https://www.ableton.com/en/download/archive/
