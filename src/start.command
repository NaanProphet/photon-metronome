#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# launch app directly so that it does not get sandboxed
# otherwise config.properties will not be found
${DIR}/photon_metronome.app/Contents/MacOS/photon_metronome
