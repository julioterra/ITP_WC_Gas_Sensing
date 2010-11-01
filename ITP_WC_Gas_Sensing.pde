#include <SPI.h>

/* ==============================
 * ITP WC - GAS SENSOR READINGS
 *
 * This code was developed based on a template provided by pachube. It was created
 * for a project titled ITP WC, that is being developed by Adib Dada, Julio Terra,
 * Macaulay Campbel and Marko Marinquez.
 *
 * This code was adapted by Julio Terra.
 *
 * Pachube is www.pachube.com - connect, tag and share real time sensor data
 * code by usman (www.haque.co.uk), may 2009
 * copy, distribute, whatever, as you like.
 *
 * =============================== */


#include <Ethernet.h>
#include <string.h>


#undef int() // needed by arduino 0011 to allow use of stdio
#include <stdio.h> // for function sprintf

#define SHARE_FEED_ID              11193     // this is your Pachube feed ID that you want to share to

#define REMOTE_FEED_ID             256      // this is the ID of the remote Pachube feed that you want to connect to
#define REMOTE_FEED_DATASTREAMS    4        // make sure that remoteSensor array is big enough to fit all the remote data streams

#define UPDATE_INTERVAL            40000    // if the connection is good wait 10 seconds before updating again - should not be less than 5
#define RESET_INTERVAL             10000    // if connection fails/resets wait 10 seconds before trying again - should not be less than 5

#define PACHUBE_API_KEY            "338dcc0b7a0694cbc34f53416fa5b64355f143760a16ef856f7b68467afab32f" // fill in your API key 
#define numberOfSensors             2
#define numberOfReadings            200

byte mac[] = { 0x02, 0xAA, 0xBB, 0xCC, 0x00, 0x11 };   // make sure this is unique on your network
byte ip[] = { 128, 122, 151, 22 };                     // no DHCP so we set our own IP address
byte remoteServer[] = { 209,40,205,190 };              // pachube.com

int sensorPin[numberOfSensors] = {0,1};
int sensorData[numberOfSensors][numberOfReadings];
int sensorCounter[numberOfSensors] = {0,0};
boolean dataSent = true;
unsigned long readInterval = 350;
unsigned long previousRead = 0;

float remoteSensor[REMOTE_FEED_DATASTREAMS];        // we know that feed 256 has floats - this might need changing for feeds without floats

void setup()
{
  Serial.begin(57600); 
  setupEthernet(); 
 
  // initialize the sensorData array 
  for (int i = 0; i < numberOfSensors; i++) {
    for (int j = 0; j < numberOfReadings; j++) { sensorData[i][j] = 0; }
  }    
}

void loop()
{
  // send data from pachube
  pachube_in_out();        

  // read data from sensors if appropriate interval has passed  
  if (readTime() == true) {
      dataSent = initCounter(dataSent);    // re-init counter when dataSent flag is set to true (re-initialize dataSent flag)
      readSensors();                       // read sensors
  }
}



