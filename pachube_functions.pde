char pachube_data[70];

char *found;
unsigned int successes = 0;
unsigned int failures = 0;
boolean ready_to_update = false;
boolean reading_pachube = false;

boolean request_pause = true;
boolean found_content = false;

unsigned long last_connect = millis();

int content_length;

void pachube_in_out(){

  if (millis() < last_connect) last_connect = millis();

  if (request_pause){
    if ((millis() - last_connect) > interval){
      ready_to_update = true;
      reading_pachube = false;
      request_pause = false;
    }
  }

  if (ready_to_update){
    Serial.println("Connecting...");
    // check if connection to pachube was successful
    if (localClient.connect()) {
        // here we assign comma-separated values to 'pachube_data' variable that will update Pachube datastreams
        // the sprintf function places data into the variable provided as the first argument
        // the data is formatted as described by the second argument
        // the last arguments are the actual pieces of data (which should match the format defined in the second argument)
        sprintf(pachube_data,"%d, %d, %d", avgVOCsensor(), avgMethaneSensor(), avgCOSensor());      // reads data into char array identified, data should match format outlined
        content_length = strlen(pachube_data);                                                      // determine length of actual used spaces in char array
  
        Serial.println("PUT to update");    
  
        // send data to pachube using a put request
        localClient.print("PUT /api/");
        localClient.print(SHARE_FEED_ID);
        localClient.print(".csv HTTP/1.1\nHost: pachube.com\nX-PachubeApiKey: ");
        localClient.print(PACHUBE_API_KEY);
        localClient.print("\nUser-Agent: Arduino (Pachube In Out v1.1)");
        localClient.print("\nContent-Type: text/csv\nContent-Length: ");
        localClient.print(content_length);
        localClient.print("\nConnection: close\n\n");
        localClient.print(pachube_data);
        localClient.print("\n");
  
        // set boolean variables to note that data has been received and processed
        ready_to_update = false;
        request_pause = true;
        last_connect = millis();
        interval = UPDATE_INTERVAL;
  
        Serial.println("finished PUT");

        delay(500);
        localClient.stop();
   
    // if connection to pachube was not successful
    } else {
      Serial.print("connection failed - attempts: ");
      Serial.println(++failures);

      // set boolean variables to appropriate state
      ready_to_update = false;
      request_pause = true;
      last_connect = millis();
      interval = RESET_INTERVAL;

      // reset the ethernet connection to fix the situation
      setupEthernet();
    } // end if connection not successful code
  } // end ready to update if statement

}

void disconnect_pachube(){
  Serial.println("disconnecting.\n=====\n\n");
  localClient.stop();
  ready_to_update = false;
  reading_pachube = false;
  request_pause = true;
  last_connect = millis();
  found_content = false;
  resetEthernetShield();
}
