char pachube_data[70];

boolean found_status_200 = false;
boolean found_session_id = false;
boolean found_CSV = false;
char *found;
unsigned int successes = 0;
unsigned int failures = 0;
boolean ready_to_update = true;
boolean reading_pachube = false;

boolean request_pause = false;
boolean found_content = false;

unsigned long last_connect;

int content_length;

void pachube_in_out(){

  if (millis() < last_connect) last_connect = millis();

  if (request_pause){
    if ((millis() - last_connect) > interval){
      ready_to_update = true;
      reading_pachube = false;
      request_pause = false;
      found_status_200 = false;
      found_session_id = false;
      found_CSV = false;

      //Serial.print("Ready to connect: ");
      //Serial.println(millis());
    }
  }

  if (ready_to_update){
    Serial.println("Connecting...");
    if (localClient.connect()) {

      // here we assign comma-separated values to 'data', which will update Pachube datastreams
      // we use all the analog-in values, but could of course use anything else millis(), digital
      // inputs, etc. . i also like to keep track of successful and failed connection
      // attempts, sometimes useful for determining whether there are major problems.

      sprintf(pachube_data,"%d,%d",analogRead(0),analogRead(1)); // 
      // sprintf definition: this function writes into the pachube array data formatted as instructed between "", the number of inputs in the format needs to match the number of arguments after the format
      // e.g. sprintf(pachube_data,"%d,%d,%d,%d,%d,%d,%d,%d",analogRead(0),analogRead(1),analogRead(2),analogRead(3),analogRead(4),analogRead(5), successes + 1, failures);

      // determine the number of data elements that will be sent to Pachube
      content_length = strlen(pachube_data);

      Serial.print("data read ");
      Serial.println(pachube_data);

//      COMMENTED OUT THE "GET" REQUESTS - we don't need any data for our arduino so we don't want to use up our request quota
//      Serial.println("GET request to retrieve");
//      localClient.print("GET /api/");
//      localClient.print(REMOTE_FEED_ID);
//      localClient.print(".csv HTTP/1.1\nHost: pachube.com\nX-PachubeApiKey: ");
//      localClient.print(PACHUBE_API_KEY);
//      localClient.print("\nUser-Agent: Arduino (Pachube In Out v1.1)");
//      localClient.println("\n");

      Serial.println("no GET request sent");
      Serial.print(millis());
      Serial.println(" PUT, to update");      

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

      // tell Arduino that
      reading_pachube = true;           // it is time to read data from Pachube
      ready_to_update = false;          // it is not yet time to make a new request or post new data to Pachube
      request_pause = false;            // it is not time to start the pause countdown
      interval = UPDATE_INTERVAL;       // reset the interval time

    } 
    // if Arduino was not able to connect to Pachube then reset all variables and try again after interval time has passed
    else {
      Serial.print("connection failed!");
      Serial.print(++failures);
      found_status_200 = false;
      found_session_id = false;
      found_CSV = false;
      ready_to_update = false;
      reading_pachube = false;
      request_pause = true;
      last_connect = millis();
      interval = RESET_INTERVAL;
      setupEthernet();
    } // END ELSE STATEMENT
  } // END IF ready_to_update STATEMENT

  // if request to Pachube has been sent then
  while (reading_pachube){
    // check whether data is available to be read, and call the checkForResponse function if data exists
    while (localClient.available()) { checkForResponse(); } 
    // check whether available data has been read (localClient.connected() is set to false once all data has been read), then call disconnect_pachube() function
    if (!localClient.connected()) { disconnect_pachube(); }
  } // END WHILE LOOP
  
} // END FUNCTION

// re-initialize variables to begin pause countdown until the next request and post cycle
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

// read data from the ethernet port 
void checkForResponse(){  
  char c = localClient.read();
  //Serial.print(c);
  buff[pointer] = c;
  if (pointer < 64) pointer++;
  if (c == '\n') {
    found = strstr(buff, "200 OK");                  // strstr(source, search) Returns a pointer to the first occurrence of str2 in str1
    if (found != 0){
      found_status_200 = true; 
      //Serial.println("Status 200");
    }
    buff[pointer]=0;
    found_content = true;
    clean_buffer();    
  }

  if ((found_session_id) && (!found_CSV)){
    found = strstr(buff, "HTTP/1.1");
    if (found != 0){
      char csvLine[strlen(buff)-9];                   // strlen(string) returns the length of a string
      strncpy (csvLine,buff,strlen(buff)-9);          // strncp(destination, source, num char to copy) loads string into a char array

      //Serial.println("This is the retrieved CSV:");     
      //Serial.println("---");     
      //Serial.println(csvLine);
      //Serial.println("---");   
      Serial.println("\n--- updated: ");
      Serial.println(pachube_data);
      Serial.println("\n--- retrieved: ");
      char delims[] = ",";
      char *result = NULL;
      char * ptr;
      result = strtok_r( buff, delims, &ptr );        // strtok_r(string, delimeters) splits up a string into tokens
      int counter = 0;
      while( result != NULL ) {
        remoteSensor[counter++] = atof(result); 
        result = strtok_r( NULL, delims, &ptr );
      }  
      for (int i = 0; i < REMOTE_FEED_DATASTREAMS; i++){
        Serial.print( (int)remoteSensor[i]); // because we can't print floats
        Serial.print("\t");
      }

      found_CSV = true;

      Serial.print("\nsuccessful updates=");
      Serial.println(++successes);

    }
  }

  if (found_status_200){
    found = strstr(buff, "_id=");
    if (found != 0){
      clean_buffer();
      found_session_id = true; 
    }
  }
}

