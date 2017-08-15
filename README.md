# photon-metronome
Say hello to your new on-stage friend: a wireless metronome that syncs to MIDI signals!

## Why?
Sometimes it's hard to hear on stage. Sound checks may be rushed, and when singing to a background track, timing is crucial. Even in a hall with muddy sound or inadequate monitors, this wireless metronome can help keep people in sync—at the speed of light.

## Setup
The project uses:
* a [Particle Photon Wi-Fi Microprocessor](https://store.particle.io/products/photon) (formerly called Spark Core) as the [IOT](https://en.wikipedia.org/wiki/Internet_of_things) wireless device
* a computer running [Abelton Live](https://www.ableton.com/en/live/) or similar software for sending [MIDI](https://en.wikipedia.org/wiki/MIDI) signals
* a physical router connecting the two (internet is not required)
* a virtual MIDI device, e.g. using Apple's built in IAC driver ([Inter Application Communication](https://developer.apple.com/legacy/library/documentation/mac/pdf/Interapplication_Communication/Intro_to_IAC.pdf)) which part of Audio MIDI Setup in Utilities
* A [Processing](https://processing.org) script which listens to the MIDI signals and sends them to the IOT device over Wi-Fi

## Demos
### 2017-08-15 Visual Metronome Prototype with Ableton Live
Demo track "Ya Devi" by [Sanchit Malhotra](https://www.youtube.com/channel/UCP5zbHm0cLnCYuJd3LlvRZA) from the album Yuva Rhythms: Jagat Janani. Visit https://chykwest.com/yuvarhythms
[![Visual Metronome Prototype with Ableton Live](https://i.imgur.com/fBfgpN0.png)](https://vimeo.com/229690607/b6a2fa1b06 "2017-08-15 Visual Metronome Prototype with Ableton Live")

## References
* How to Build a Wireless Visual Metronome that Synchronizes with your DAW https://ask.audio/articles/how-to-build-a-wireless-visual-metronome-that-synchronizes-with-your-daw
* Using virtual MIDI buses in Live https://help.ableton.com/hc/en-us/articles/209774225-Using-virtual-MIDI-buses-in-Live)
* Manually Assigning MIDI Values in Ableton Live https://www.youtube.com/watch?v=e5kcaVfjqf4)
* MIDI Control Change Messages – Continuous Controllers http://nickfever.com/music/midi-cc-list
* Embedding video in Markdown https://stackoverflow.com/questions/11804820/embed-a-youtube-video
