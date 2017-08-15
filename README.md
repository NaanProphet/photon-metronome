# photon-metronome
Say hello to your new on-stage friend: a wireless metronome that syncs to MIDI signals!

## Setup
The project uses:
* a [Particle Photon Wi-Fi Microprocessor](https://store.particle.io/products/photon) (formerly called Spark Core) as the [IOT](https://en.wikipedia.org/wiki/Internet_of_things) wireless device
* a computer running [Abelton Live](https://www.ableton.com/en/live/) or similar software for sending [MIDI](https://en.wikipedia.org/wiki/MIDI) signals
* a physical router connecting the two (internet is not required)
* a virtual MIDI device, e.g. using Apple's built in IAC driver ([Inter Application Communication](https://developer.apple.com/legacy/library/documentation/mac/pdf/Interapplication_Communication/Intro_to_IAC.pdf)) which part of Audio MIDI Setup in Utilities
* * A [Processing](https://processing.org) script which listens to the MIDI signals and sends them to the IOT device over Wi-Fi

## References
* How to Build a Wireless Visual Metronome that Synchronizes with your DAW https://ask.audio/articles/how-to-build-a-wireless-visual-metronome-that-synchronizes-with-your-daw
* Using virtual MIDI buses in Live https://help.ableton.com/hc/en-us/articles/209774225-Using-virtual-MIDI-buses-in-Live)
* Manually Assigning MIDI Values in Ableton Live https://www.youtube.com/watch?v=e5kcaVfjqf4)
* MIDI Control Change Messages – Continuous Controllers http://nickfever.com/music/midi-cc-list
