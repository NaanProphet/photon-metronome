// Require WiFi but not Internet
SYSTEM_MODE(SEMI_AUTOMATIC);

// UDP Port used for receiving data from the MIDI-to-Spark-Core application
unsigned int udpPort = 12348;
// A UDP instance to let us receive data/packets over UDP
UDP Udp;

//====================================================================
//The setup function.
//This is run when the device is first started.

void setup()
{
    // Connect to router to receive UDP signals
    WiFi.connect();

    // Get control of the RGB LED
    RGB.control(true);
    // Set LED to be white
    RGB.color(255, 255, 255);

    // start the UDP connection
    Udp.begin(udpPort);

    // Open the serial port
    Serial.begin(9600);
    // Give the serial port time to open
    delay(1000);

    // Display the device IP Address over serial
    Serial.print("Device IP Address: ");
    Serial.print(WiFi.localIP());
    Serial.print("\n");

    // Display the connected network name over serial
    Serial.print("Device Network: ");
    Serial.print(WiFi.SSID());
    Serial.print("\n");

    // Display the UDP port over serial
    Serial.print("UDP Port Number: ");
    Serial.print(udpPort);
    Serial.print("\n");

    // If you have attached an external RGB LED to the device,
    // set the three PWM pins that the LED is attached to
    // to be output pins, e.g:
    // pinMode(A0, OUTPUT);
    // pinMode(A1, OUTPUT);
    // pinMode(A4, OUTPUT);
}

//====================================================================
//The main function.
//This is run continuously until the device is turned off.

void loop()
{
    // Check if data has been received on the UDP port
    if (Udp.parsePacket() > 0)
    {
        char red, green, blue;
        int count = Udp.available();
        Serial.println("Received num bytes: " + count);
        
        if (count == 1) {
            // Single byte performance mode
            char alias = Udp.read();
            switch (alias) {
                case 'A':
                    red = 0;
                    green = 255;
                    blue = 0;
                    break;
                case 'B':
                    red = 255;
                    green = 255;
                    blue = 0;
                    break;
                case 'C':
                    red = 255;
                    green = 0;
                    blue = 0;
                    break;
                case 'S':
                    red = 255;
                    green = 255;
                    blue = 255;
                    break;
                case 'Z':
                    red = 0;
                    green = 0;
                    blue = 0;
                    break;
                default:
                    Serial.println("ERROR unknown single byte received: " + alias);
            }
        } else {
            // Read the first byte of data received.
            // This is the LED red value.
            red = Udp.read();

            // Read the second byte of data received.
            // This is the LED green value.
            green = Udp.read();

            // Read the third byte of data received.
            // This is the LED blue value.
            blue = Udp.read();
        }

        // Ignore other bytes of data received
        Udp.flush();

        // set LED colour based on the data received
        RGB.color(red, green, blue);

        // If you have attached an external RGB LED to the device,
        // set the colour of the LED here using the values of
        // red, green, and blue, making sure the colour
        // values are being sent to the relevant pins, e.g:
        // analogWrite(A0, red);
        // analogWrite(A1, green);
        // analogWrite(A4, blue);
    }
}
