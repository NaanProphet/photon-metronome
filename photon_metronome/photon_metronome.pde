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
// 0.2 - add config file import. CC 123 now resets LED back to white. GUI updated
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
String midiInput;
String sparkCoreIpAddress;
int udpPort;

//Values of the MIDI messages we will be using
byte MIDI_CLOCK_TIMING = (byte)0xF8;
byte MIDI_CLOCK_START = (byte)0xFA;
byte MIDI_CLOCK_CONTINUE = (byte)0xFB;
byte MIDI_CLOCK_STOP = (byte)0xFC;
byte MIDI_CC_STATUS = (byte)0xB0;
byte MIDI_STATUS_NIBBLE = (byte)0xF0;

//MIDI clock spec for number of pulses per quarter note
int CLOCK_RATE_PER_QUARTER_NOTE = 24;

//The CC numbers we want to use to control the LED
//colour values. Change these values if you want to
//use different CC numbers.
byte downbeatCC = (byte)20;
byte tickCc = (byte)21;
byte halfbeatCc = (byte)22;
byte MIDI_CC_ALL_NOTES_OFF = (byte)123;

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
int globalMessageCounter = 0;

//Font variable for user interface
PFont f; 

//=================================================================
//The setup function.
//This is run once when the application is started.

void setup() 
{  

  HashMap<String, String> parsedConfig = readProps(loadStrings("config.properties"));
  midiInput = parsedConfig.get("virtual.midi.port.name");
  sparkCoreIpAddress = parsedConfig.get("spark.core.ip.address");
  udpPort = new Integer(parsedConfig.get("udpPort"));

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
  globalMessageCounter++;
  println("Message " + globalMessageCounter + " first byte raw data is: " + data[0]);

  //if we have received a MIDI CC message on any channel...
  if ((data[0] & MIDI_STATUS_NIBBLE) == MIDI_CC_STATUS)
  {
    byte ccData = data[1];
    println("-found a CC message inside: " + ccData);

    //If we have received a downbeat/"sam" value CC number
    if (ccData == downbeatCC)
    {
      //set redValue based on the CC value
      int ccValue = (int)data[2];
      println("-downbeat CC value is: " + ccValue);
      if (ccValue != 0) {
        redValue = (int)data[2] * 2;
        greenValue = 0;
        blueValue = 0;
      } else {
        setLEDBlack();
      }
    }

    //If we have received a normal "tick" beat CC number
    else if (ccData == tickCc)
    {
      // constant intensity, regardless of non-zero CC value
      int ccValue = (int)data[2];
      println("-tick beat CC value is: " + ccValue);
      if (ccValue != 0) {
        setLEDYellow();
      } else {
        setLEDBlack();
      }
    }

    //If we have received a "open beat"/"khaali" value CC number
    else if (ccData == halfbeatCc)
    {
      //set blueValue based on the CC value
      int ccValue = (int)data[2];
      println("-open beat CC values is: " + ccValue);
      if (ccValue != 0) {
        redValue = 0;
        greenValue = 0;
        blueValue = (int)data[2] * 2;
      } else {
        setLEDBlack();
      }
    }

    //If we have received a stop playing CC signal
    else if (ccData == MIDI_CC_ALL_NOTES_OFF)
    {
      // reset back to original color
      setLEDReady();
    }

    //If we're not currently flashing the LED
    //(meaning the LED is a static colour)
    if (flashingLed == false)
    {
      //Send a new set of colour values to the Spark Core
      //based on the colour values
      byte data_to_send[] = {(byte)redValue, (byte)greenValue, (byte)blueValue};  
      udp.send(data_to_send, sparkCoreIpAddress, udpPort);
    }
  }
  //if we have received a MIDI Clock start or continue message...
  else if (data[0] == MIDI_CLOCK_START || data[0] == MIDI_CLOCK_CONTINUE)
  {
    println("There was a start/continue message");

    //set that we want to flash the LED
    flashingLed = true;

    //start a timer that counts how many MIDI Clock 
    //timing messages we have received 
    midiTimingCounter = 0;
  }

  //if we have received a MIDI Clock timing message...
  else if (data[0] == MIDI_CLOCK_TIMING) 
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

      //Multiply each colour value with the multiplier
      float red_float = (float)redValue * multiplier;
      float green_float = (float)greenValue * multiplier;
      float blue_float = (float)blueValue * multiplier;

      //Create an array of bytes that stores the colour values
      byte data_to_send[] = {(byte)red_float, (byte)green_float, (byte)blue_float};  

      //Send the new colour values to the Spark Core board
      udp.send(data_to_send, sparkCoreIpAddress, udpPort);
    }
  } 

  //if we have received a MIDI Clock stop message...
  else if (data[0] == MIDI_CLOCK_STOP)
  {
    println("There was a stop message");

    //set that we don't want to flash the LED
    flashingLed = false;

    //Send a new set of colour values to the Spark Core
    //based on the colour values
    redValue = 255;
    greenValue = 255;
    blueValue = 255;
    byte data_to_send[] = {(byte)redValue, (byte)greenValue, (byte)blueValue};  
    udp.send(data_to_send, sparkCoreIpAddress, udpPort);
  }
}

void setLEDBlack() {
  redValue = 0;
  greenValue = 0;
  blueValue = 0;
} 

void setLEDYellow() {
  redValue = 255;
  greenValue = 255;
  blueValue = 0;
}

void setLEDReady() {
 redValue = 255;
 greenValue = 255;
 blueValue = 255;
}