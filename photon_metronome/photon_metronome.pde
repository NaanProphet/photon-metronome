//This application listens for MIDI Clock and CC messages on its
//MIDI input, and uses them to send UDP messages to a Spark Core
//board to set the colour and brightness of the onboard RGB LED.

//Set midiInput to be the name of your virtual MIDI port
String midiInput = "Photon";

//Set sparkCoreIpAddress to be the IP Address of your Spark Core device
String sparkCoreIpAddress = "192.168.1.12";

//The UDP port number we will send messages to the Spark Core over.
//Make sure this number is the same as the udpPort number in the Spark Core code.
int udpPort = 12348;

//=================================================================

//Import the MidiBus library
import themidibus.*;
//Import the UDP library
import hypermedia.net.*;

//Create a MIDI bus object for receiving MIDI data
MidiBus midiBus;
//Create a UDP object for sending UDP messages to the Spark Core board
UDP udp;

//Values of the MIDI messages we will be using
byte MIDI_CLOCK_TIMING = (byte)0xF8;
byte MIDI_CLOCK_START = (byte)0xFA;
byte MIDI_CLOCK_CONTINUE = (byte)0xFB;
byte MIDI_CLOCK_STOP = (byte)0xFC;
byte MIDI_CC_STATUS = (byte)0xB0;
byte MIDI_STATUS_NIBBLE = (byte)0xF0;

//The CC numbers we want to use to control the LED
//colour values. Change these values if you want to
//use different CC numbers.
byte redCc = (byte)20;
byte greenCc = (byte)21;
byte blueCc = (byte)22;

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

//=================================================================
//The draw function.
//This runs continuously until the application is stopped.

void draw()
{
  //Create a basic graphical interface
  textFont (f, 16);
  fill(200);
  text ("MIDI to Photon", 75, 150);
}

//=================================================================
//The rawMidi function.
//This is run whenever a MIDI message is received from the virtual
//MIDI port, and processes the message accordingly.

void rawMidi(byte[] data)
{
  globalMessageCounter++;
  println("message " + globalMessageCounter + " raw data is: " + (int) data[0]);

  //if we have received a MIDI CC message on any channel...
  if ((data[0] & MIDI_STATUS_NIBBLE) == MIDI_CC_STATUS)
  {
    println("There was a CC message: " + data[1]);

    //If we have received a red value CC number
    if (data[1] == redCc)
    {
      //set redValue based on the CC value
      redValue = (int)data[2] * 2;
    }

    //If we have received a red value CC number
    else if (data[1] == greenCc)
    {
      //set greenValue based on the CC value
      greenValue = (int)data[2] * 2;
    }

    //If we have received a blue value CC number
    else if (data[1] == blueCc)
    {
      //set blueValue based on the CC value
      blueValue = (int)data[2] * 2;
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

      //if we have received 24 timing messages (1 beat)
      if (midiTimingCounter >= 24)
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
    byte data_to_send[] = {(byte)redValue, (byte)greenValue, (byte)blueValue};
    udp.send(data_to_send, sparkCoreIpAddress, udpPort);
  }
}
