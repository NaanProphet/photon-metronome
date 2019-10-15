//This application listens for MIDI Clock and CC messages on its //<>//
//MIDI input, and uses them to send UDP messages to a Particle
//board to set the colour and brightness of the onboard RGB LED.

//Original with gratitude from:
//https://ask.audio/articles/how-to-build-a-wireless-visual-metronome-that-synchronizes-with-your-daw

//Modified by @NaanProphet
//https://github.com/NaanProphet/

//=================================================================

// code version
// version history:
// 0.1-alpha.1 - initial prototype with Abelton Live. cycle support via track output
// 0.1-alpha.2 - add config file import. CC 123 now resets LED back. GUI updated
// 0.1-alpha.3 - config file improved, RGB colors now injectable via JSON
// 0.1-alpha.4 - refactored MIDI CC conditionals to strategy pattern, for easier scaling
// 0.1 - MIDI CC multiplier support based on envelope
// 0.2 - support for multiple Photon devices
// 0.3-beta.1 - simplifying config property key names and improving error handling
String version = "0.3-beta.1";

//Import the MidiBus library
import themidibus.*;
//Import the UDP library
import hypermedia.net.*;
//Java libraries
import java.util.Arrays;
import java.util.List;
import java.util.Set;

//Create a MIDI bus object for receiving MIDI data
MidiBus midiBus;
//Create a UDP object for sending UDP messages to the Particle device
UDP udp;
//Font variable for user interface
PFont f;

//Config values
private static final String CONFIG_FILE = "config.properties";
private static final String MIDI_CC_PROP_NAME_PREFIX = "led";

private static final String KEY_MIDI_PORT_NAME = "virtual.midi.port.name";
private static final String KEY_PARTICLE_DEVICE_IP = "particle.device.ip.address";
private static final String KEY_PARTICLE_UDP_PORT = "udpPort";
private static final String KEY_STANDBY_LED_COLOR = "standby.led.color";
private static final String KEY_USE_CC_MULTIPLIER = "use.cc.envelope.for.intensity";

private String midiInput;
private String[] particleDevices;
private int udpPort;
private LEDSignal standbyLED;
private boolean useMultiplier;

//Values of the MIDI messages we will be using
private static final byte MIDI_CLOCK_TIMING = (byte)0xF8;
private static final byte MIDI_CLOCK_START = (byte)0xFA;
private static final byte MIDI_CLOCK_CONTINUE = (byte)0xFB;
private static final byte MIDI_CLOCK_STOP = (byte)0xFC;
private static final byte MIDI_CC_STATUS = (byte)0xB0;
private static final byte MIDI_STATUS_NIBBLE = (byte)0xF0;
//MIDI clock spec for number of pulses per quarter note
private static final int CLOCK_RATE_PER_QUARTER_NOTE = 24;
private static final int MIDI_CC_ENVELOPE_MAX_VAL = 127;

//The CC numbers we want to use to control the LED
//colour values. Change these values if you want to
//use different CC numbers. 20-31 are undefined as per
//the spec, so these are available to use
private static final HashMap<Byte, LEDSignal> MIDI_CC_SIGNALS = new HashMap<Byte, LEDSignal>();
private static final byte MIDI_CC_ALL_NOTES_OFF = (byte)123;
private static class LEDSignal {
  private int redValue;
  private int greenValue;
  private int blueValue;
  private LEDSignal(int redValue, int greenValue, int blueValue) {
    this.redValue = redValue;
    this.greenValue = greenValue;
    this.blueValue = blueValue;
  }
}

private static final int GUI_BACKGROUND_RGB = 0;

//Variables to hold the static colour values
int redValue = 255;
int greenValue = 255;
int blueValue = 255;

//Variable that is set to true when we want to
//flash the LED.
boolean flashingLed = false;

//Variable used to count the number of MIDI
//Clock timing messages we receive
int midiTimingCounter = 0;

//Global message counter
int messageCounter = 0;

String startupErrors = "";

//=================================================================
//The setup function.
//This is run once when the application is started.

void setup()
{  
  //Prepare GUI window
  size(300, 300);
  
  //Setup font
  f = createFont("Arial", 16);
  textFont(f);
  textAlign(CENTER, CENTER);
  
  HashMap<String, String> parsedConfig = readProps(CONFIG_FILE);
  
  if (parsedConfig == null) {
    startupErrors += "Cannot find " + CONFIG_FILE + " file!";
    return;
  } 
  
  if (!validate(parsedConfig)) {
    return;
  }
  
  midiInput = parsedConfig.get(KEY_MIDI_PORT_NAME);
  particleDevices = splitTokens(parsedConfig.get(KEY_PARTICLE_DEVICE_IP), ",");
  udpPort = new Integer(parsedConfig.get(KEY_PARTICLE_UDP_PORT));
  standbyLED = parseLEDValues(parseJSONObject(parsedConfig.get(KEY_STANDBY_LED_COLOR)));
  useMultiplier = new Boolean(parsedConfig.get(KEY_USE_CC_MULTIPLIER)).booleanValue();

  for (String key : parsedConfig.keySet()) { //<>//
    if (key.startsWith(MIDI_CC_PROP_NAME_PREFIX)) {
      JSONObject ccConfig = parseJSONObject(parsedConfig.get(key));
      byte ccType = (byte) ccConfig.getInt("ccValue");
      MIDI_CC_SIGNALS.put(ccType, parseLEDValues(ccConfig));
    }
  }

  //List all the available MIDI inputs/ouputs on the output console.
  MidiBus.list();
  
  //Check if MIDI device exists
  List<String> availableInputs = Arrays.asList(MidiBus.availableInputs());
  List<String> availableOutputs = Arrays.asList(MidiBus.availableOutputs());
  
  if (!availableInputs.contains(midiInput) || !availableOutputs.contains(midiInput)) {
    startupErrors += "MIDI device [" + midiInput + "] not found! ";
    startupErrors += "Available inputs are: " + availableInputs;
    return;
  }

  //Set the MIDI bus object to receive from
  midiBus = new MidiBus(this, midiInput, -1);
  
  println("midiBus is: " + midiBus);

  //Setup the UDP connection
  udp = new UDP(this, udpPort-1);

}

//Parses a Java-esque properties file
HashMap<String, String> readProps(String configFile) {
  
  String[] in = loadStrings(configFile);
  
  if (in == null) {
    //cannot find file
    return null;
  }

  HashMap<String, String> out = new HashMap<String, String>();
  for (String propLine : in) {
    if (propLine.startsWith("#") ) {
      continue;
    }
    String[] props = split(propLine, "=");
    if (props.length != 2) {
      continue;
    }
    out.put(props[0], props[1]);
  }

  return out;
}

private LEDSignal parseLEDValues(JSONObject entry) {
  int red = entry.getInt("red");
  int green = entry.getInt("green");
  int blue = entry.getInt("blue");
  LEDSignal ledColors = new LEDSignal(red, green, blue);
  return ledColors;
}

private boolean validate(HashMap<String, String> config) {
  
  // add all expected keys
  ArrayList<String> expectedKeys = new ArrayList<String>();
  expectedKeys.add(KEY_MIDI_PORT_NAME);
  expectedKeys.add(KEY_PARTICLE_DEVICE_IP);
  expectedKeys.add(KEY_PARTICLE_UDP_PORT);
  expectedKeys.add(KEY_STANDBY_LED_COLOR);
  expectedKeys.add(KEY_USE_CC_MULTIPLIER);
  
  // subtract the difference
  Set<String> actualKeys = config.keySet();
  // mutatates the collection
  expectedKeys.removeAll(actualKeys);
  
  if (expectedKeys.size() != 0) {
    startupErrors += "Missing config keys " + expectedKeys;
    return false;
  }
  return true;
}

//=================================================================
//The draw function.
//This runs continuously until the application is stopped.

void draw()
{
  // must be in draw function, otherwise text is blurry
  background(GUI_BACKGROUND_RGB);
 
  fill(255, 255, 255);
  textSize(20);
  text ("MIDI Photon Metronome", width * 0.5, 50);
  
  textSize(16);
  text ("version: " + version, width * .75, 275);
  
  if (startupErrors.length() != 0) {
    fill(255, 0, 0);
    //text box with wrapping
    text (startupErrors, 0, 0, 300, 300);
  } else {
    int rowSpacing = 25;
    int rowPos = 120;
    text ("MIDI Sync Input Device: " + midiInput, width * 0.5, rowPos);
    for (int i=0; i < particleDevices.length; i++) {
      rowPos += rowSpacing;
      text ("Output IP Address " + i + ": " + particleDevices[i], width * 0.5, rowPos);
    }
    rowPos += rowSpacing;
    text ("Output UDP Port: " + udpPort, width * 0.5, rowPos);
  }
}

//=================================================================
//The rawMidi function.
//This is run whenever a MIDI message is received from the virtual
//MIDI port, and processes the message accordingly.

void rawMidi(byte[] data)
{
  messageCounter++;
  println("Message " + messageCounter);

  byte midiStatus = data[0];

  //if we have received a MIDI CC message on any channel...
  if ((midiStatus & MIDI_STATUS_NIBBLE) == MIDI_CC_STATUS)
  {
    byte ccMessageType = data[1];
    // value of the envelope: 0-127
    int ccMessageValue = (int)data[2];
    println("-found a CC message inside: " + ccMessageType + " with value: " + ccMessageValue);

    LEDSignal ledSignal = MIDI_CC_SIGNALS.get(ccMessageType);

    //If we have received a stop playing CC signal
    if (ccMessageType == MIDI_CC_ALL_NOTES_OFF) {
      // reset back to original color
      setLEDReady();
    } else if (ccMessageValue == 0) {
      // wait until next beat
      setLEDBlack();
    }

    //If we have received a non-zero downbeat CC number
    else if (ledSignal != null)
    {
      // constant intensity, regardless of non-zero CC value
      setLED(ledSignal.redValue, ledSignal.greenValue, ledSignal.blueValue);
    }

    //If we're not currently flashing the LED
    //(meaning the LED is a static colour)
    if (flashingLed == false)
    {
      if (useMultiplier) {
        sendData((float)ccMessageValue/MIDI_CC_ENVELOPE_MAX_VAL);
      } else {
        sendData();
      }
    }
  }

  //if we have received a MIDI Clock start or continue message...
  else if (midiStatus == MIDI_CLOCK_START || midiStatus == MIDI_CLOCK_CONTINUE)
  {
    println("There was a start/continue message");

    //set that we want to flash the LED
    flashingLed = true;

    //start a timer that counts how many MIDI Clock
    //timing messages we have received
    midiTimingCounter = 0;
  }

  //if we have received a MIDI Clock timing message...
  else if (midiStatus == MIDI_CLOCK_TIMING)
  {
    println("There was a timing tick");

    //if we want to flash the LED
    if (flashingLed == true)
    {
      //Add 1 to the timing counter value
      midiTimingCounter++;

      //if we have received a full set of timing messages (1 beat)
      if (midiTimingCounter >= CLOCK_RATE_PER_QUARTER_NOTE)
      {
        //reset the timing value
        midiTimingCounter = 0;
      }

      //Send a new set of colour values to the Particle device
      //based on the value of midiTimingCounter...

      //Disable "breathing" for a crisper visual
      float multiplier = midiTimingCounter == 0 ? 1 : 0;

      sendData(multiplier);
    }
  }

  //if we have received a MIDI Clock stop message...
  else if (midiStatus == MIDI_CLOCK_STOP)
  {
    println("There was a stop message");

    //set that we don't want to flash the LED
    flashingLed = false;

    //Send a new set of colour values to the Particle device
    //based on the colour values
    setLEDReady();
    sendData();
  }
}

void sendData() {
  sendData(1.0);
}

void sendData(float multiplier) {

  //Multiply each colour value with the multiplier
  float red_float = (float)redValue * multiplier;
  float green_float = (float)greenValue * multiplier;
  float blue_float = (float)blueValue * multiplier;

  //Create an array of bytes that stores the colour values
  byte data_to_send[] = {(byte)red_float, (byte)green_float, (byte)blue_float};

  //Send the new colour values to the Particle device
  println("-sending LED data:", red_float, green_float, blue_float);
  for (int i=0; i < particleDevices.length; i++) {
    udp.send(data_to_send, particleDevices[i], udpPort);
  }
}

private void setLEDBlack() {
  setLED(0, 0, 0);
}

private void setLEDReady() {
  setLED(standbyLED.redValue, standbyLED.blueValue, standbyLED.greenValue);
}

private void setLED(int red, int green, int blue) {
  redValue = red;
  greenValue = green;
  blueValue = blue;
}
