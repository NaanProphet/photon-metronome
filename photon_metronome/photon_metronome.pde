//This application listens for MIDI Clock and CC messages on its
//MIDI input, and uses them to send UDP messages to a Spark Core
//board to set the colour and brightness of the onboard RGB LED.

//Original with gratitude from:
//https://ask.audio/articles/how-to-build-a-wireless-visual-metronome-that-synchronizes-with-your-daw

//Modified by @NaanProphet
//https://github.com/NaanProphet/

//=================================================================

// code version
// version history:
// 0.1 - initial prototype with Abelton Live. cycle support via track output
// 0.2 - add config file import. CC 123 now resets LED back. GUI updated
// 0.3 - config file improved, RGB colors now injectable via JSON
String version = "0.2";

//Import the MidiBus library
import themidibus.*;
//Import the UDP library
import hypermedia.net.*;

//Create a MIDI bus object for receiving MIDI data
MidiBus midiBus;
//Create a UDP object for sending UDP messages to the Spark Core board
UDP udp;

//Config values
private static final String CONFIG_FILE = "config.properties";
private static final String KEY_MIDI_PORT_NAME = "virtual.midi.port.name";
private static final String KEY_PARTICLE_CORE_IP = "spark.core.ip.address";
private static final String KEY_PARTICLE_UDP_PORT = "udpPort";
String midiInput;
String sparkCoreIpAddress;
int udpPort;

//Values of the MIDI messages we will be using
private static final byte MIDI_CLOCK_TIMING = (byte)0xF8;
private static final byte MIDI_CLOCK_START = (byte)0xFA;
private static final byte MIDI_CLOCK_CONTINUE = (byte)0xFB;
private static final byte MIDI_CLOCK_STOP = (byte)0xFC;
private static final byte MIDI_CC_STATUS = (byte)0xB0;
private static final byte MIDI_STATUS_NIBBLE = (byte)0xF0;

//MIDI clock spec for number of pulses per quarter note
private static final int CLOCK_RATE_PER_QUARTER_NOTE = 24;

//The CC numbers we want to use to control the LED
//colour values. Change these values if you want to
//use different CC numbers.
//20-31 are undefined as per the spec, hence these defaults
private byte CC_TYPE_DOWNBEAT = (byte)20;
private byte CC_TYPE_TICK = (byte)21;
private byte CC_TYPE_HALFBEAT = (byte)22;
private static final byte MIDI_CC_ALL_NOTES_OFF = (byte)123;
private JSONObject downbeatRGB;
private JSONObject tickRGB;
private JSONObject halfbeatRGB;

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

//Font variable for user interface
PFont f;

//=================================================================
//The setup function.
//This is run once when the application is started.

void setup()
{

  HashMap<String, String> parsedConfig = readProps(loadStrings(CONFIG_FILE));
  midiInput = parsedConfig.get(KEY_MIDI_PORT_NAME);
  sparkCoreIpAddress = parsedConfig.get(KEY_PARTICLE_CORE_IP);
  udpPort = new Integer(parsedConfig.get(KEY_PARTICLE_UDP_PORT));
  CC_TYPE_DOWNBEAT = (byte)(Integer.parseInt((parsedConfig.get("midi.cc.downbeat"))));
  CC_TYPE_TICK = (byte)(Integer.parseInt((parsedConfig.get("midi.cc.tick"))));
  CC_TYPE_HALFBEAT = (byte)(Integer.parseInt(parsedConfig.get("midi.cc.emptybeat")));
  downbeatRGB = parseJSONObject(parsedConfig.get("led.downbeat"));
  tickRGB = parseJSONObject(parsedConfig.get("led.tick"));
  halfbeatRGB = parseJSONObject(parsedConfig.get("led.emptybeat"));

  size(300, 300);
  background(0);

  //List all the available MIDI inputs/ouputs on the output console.
  MidiBus.list();

  //Set the MIDI bus object to receive from
  midiBus = new MidiBus(this, midiInput, -1);

  //Setup the UDP connection
  udp = new UDP(this, udpPort-1);

  //Setup font
  f = createFont ("Arial", 16, true);
}

//Parses a Java-esque properties file
HashMap<String, String> readProps(String[] in) {

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

//=================================================================
//The draw function.
//This runs continuously until the application is stopped.

void draw()
{

  //Create a basic graphical interface
  textFont (f, 16);
  fill(200);
  textAlign(CENTER);
  text ("MIDI Visual Metronome", width * 0.5, 75);
  text ("MIDI Sync Input Device: " + midiInput, width * 0.5, 140);
  text ("Output IP Address: " + sparkCoreIpAddress, width * 0.5, 165);
  text ("Output UDP Port: " + udpPort, width * 0.5, 190);
  text ("version: " + version, width * .75, 275);
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

    //If we have received a stop playing CC signal
    if (ccMessageType == MIDI_CC_ALL_NOTES_OFF)
    {
      // reset back to original color
      setLEDReady();
    } else if (ccMessageValue == 0) {
      setLEDBlack();
    }

    //If we have received a downbeat/"sam" value CC number
    else if (ccMessageType == CC_TYPE_DOWNBEAT)
    {
      setLED(downbeatRGB);
    }

    //If we have received a normal "tick" beat CC number
    else if (ccMessageType == CC_TYPE_TICK)
    {
      // constant intensity, regardless of non-zero CC value
      setLED(tickRGB);
    }

    //If we have received a "open beat"/"khaali" value CC number
    else if (ccMessageType == CC_TYPE_HALFBEAT)
    {
      setLED(halfbeatRGB);
    }

    //If we're not currently flashing the LED
    //(meaning the LED is a static colour)
    if (flashingLed == false)
    {
      sendData();
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

      //Send a new set of colour values to the Spark Core
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

    //Send a new set of colour values to the Spark Core
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

  //Send the new colour values to the Spark Core board
  udp.send(data_to_send, sparkCoreIpAddress, udpPort);
}

void setLEDBlack() {
  setLED(0, 0, 0);
}

void setLEDYellow() {
  setLED(255, 255, 0);
}

void setLEDRed() {
  setLED(255, 0, 0);
}

void setLEDBlue() {
  setLED(0, 0, 255);
}

void setLEDReady() {
  setLED(255, 255, 255);
}

void setLED(int red, int green, int blue) {
  redValue = red;
  greenValue = green;
  blueValue = blue;
}

void setLED(JSONObject rgbValues) {
  redValue = rgbValues.getInt("red");
  greenValue = rgbValues.getInt("green");
  blueValue = rgbValues.getInt("blue");
}
