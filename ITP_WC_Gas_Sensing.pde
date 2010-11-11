#include <SPI.h>
#include <Ethernet.h>
#include <string.h>
#include <stdio.h>     // for function sprintf

#undef int()           // needed by arduino 0011 to allow use of stdio

#define SHARE_FEED_ID              11193     // this is your Pachube feed ID that you want to share to
#define REMOTE_FEED_ID             256      // this is the ID of the remote Pachube feed that you want to connect to
#define REMOTE_FEED_DATASTREAMS    4        // make sure that remoteSensor array is big enough to fit all the remote data streams

#define UPDATE_INTERVAL            40000    // if the connection is good wait 10 seconds before updating again - should not be less than 5
#define RESET_INTERVAL             10000    // if connection fails/resets wait 10 seconds before trying again - should not be less than 5

#define PACHUBE_API_KEY            "338dcc0b7a0694cbc34f53416fa5b64355f143760a16ef856f7b68467afab32f" // fill in your API key 
#define numberOfReadings            200
#define methaneCONumberofReadings   100
#define methaneCOCycles             6

byte mac[] = { 0x02, 0xAA, 0xBB, 0xCC, 0x00, 0x11 };   // make sure this is unique on your network
byte ip[] = { 128, 122, 151, 22 };                     // no DHCP so we set our own IP address
byte remoteServer[] = { 209,40,205,190 };              // pachube.com

int methaneCOHeaterPin = 3;                            // pin for analogRead and analogWrite
int methaneValues[methaneCONumberofReadings];          // array for methane sensor values
int methaneCounter;                                    // counter for methane readings
int COValues[methaneCONumberofReadings];               // array for CO sensor values
int COCounter;                                         // counter for CO readings
unsigned long methaneCOpreviousCycleTime;              // variable to save the time when the cycles change
int methaneCOCycleIndex;                               // variable that holds current cycle phase

// array that holds the voltage setting and time for each cycle phase
long methaneCOReadTimeCycle[methaneCOCycles] = {14985, 5, 10, 4985, 5, 10};
int methaneCOHeatLevel[methaneCOCycles] = {10, 10, 10, 45, 45, 45};

int vocPin = 0;                                         // pin for analogRead of VOC sensors
int vocValues[numberOfReadings];                        // array for VOC sensor values
int vocCounter = 0;                                     // counter for VOC sensor readings
unsigned long readInterval = 350;                       // interval of time between each reading for VOC            
unsigned long previousRead = 0;                         // variable to save the time when last read was made
boolean dataSent = true;

float remoteSensor[REMOTE_FEED_DATASTREAMS];        // we know that feed 256 has floats - this might need changing for feeds without floats

void setup() {
    Serial.begin(57600); 
    setupEthernet(); 

    pinMode(methaneCOHeaterPin, OUTPUT);
    
    // initialize variables for reading data from methaneCO sensors
    methaneCOCycleIndex = 0;
    methaneCOpreviousCycleTime = millis();
    methaneCounter = 0;
    COCounter = 0;

    // set the appropriate voltage for methane/CO heater 
    analogWrite(methaneCOHeaterPin, methaneCOHeatLevel[methaneCOCycleIndex]);
   
    // initialize the sensorData array 
    for (int j = 0; j < numberOfReadings; j++) { vocValues[j] = 0; }
    for (int k = 0; k < methaneCONumberofReadings; k++) { 
        methaneValues[k] = 0;
        COValues[k] = 0;
    }
}



void loop() {
    pachube_in_out();           // send data from pachube 
    updateMethaneOCHeater();    // adjust voltage to heater from methane sensor 
    readMethaneCOSensors();     // read sensors
    readVOCSensors();                       
}


