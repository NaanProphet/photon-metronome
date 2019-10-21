#!/bin/bash

particle compile photon visualmetronome.ino --saveTo photon.bin
particle flash --usb photon.bin
