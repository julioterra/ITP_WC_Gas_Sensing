// READ TIME FUNCTION: checks if a time interval has passed.
// accepts two arguments: (1) the last time an event took place and (2) the interval length
// returns true if interval time has passed, returns false otherwise
boolean readTime(long _previousRead, long _readInterval) {
  if (millis() - _previousRead > _readInterval) { 
      return true; 
  }
  return false; 
}


// UPDATE METHANE AND CO HEATER FUNCTION: cycles through the various heater temperatures for the methane, carbon monoxide sensor
// sets the time when the cycle changes and increases the counter appropriately.
void updateMethaneOCHeater() {
    if(readTime(methaneCOpreviousCycleTime, methaneCOReadTimeCycle[methaneCOCycleIndex]) == true) {
        analogWrite(methaneCOHeaterPin, methaneCOHeatLevel[methaneCOCycleIndex]);    // sets heater voltage
        methaneCOpreviousCycleTime = millis();                                       // sets time when heater voltage changed
        if(methaneCOCycleIndex < methaneCOCycles-1) methaneCOCycleIndex++;             // updates the cycle phase counter variable
            else methaneCOCycleIndex = 0;                                            // reset cycle phase variable if necessary

        Serial.print("NEW CO/Methane Phase: ");
        Serial.print(methaneCOCycleIndex);
        Serial.print(" Phase Duration: ");
        Serial.print(methaneCOReadTimeCycle[methaneCOCycleIndex]);
        Serial.print(" Heater Voltage Level: ");
        float f = methaneCOHeatLevel[methaneCOCycleIndex]/(float)(255)*5;
        Serial.println(f);
    }
}


// READ METHANE AND CO SENSORS: Reads the sensor at the appropriate times to capture methane and then carbon monoxide respectively.
// Sensor data is saved in to the appropriate arrays and counter is increased.
void readMethaneCOSensors() {  
    if (methaneCOCycleIndex == 1) {                                      // if current cycle phase is 1
        COValues[COCounter] = analogRead(methaneCOHeaterPin);                // read CO value into array and update counter
        
        Serial.print(" CO counter: ");
        Serial.print(COCounter);
        Serial.print(" and values: ");
        Serial.println(COValues[COCounter]); 

        COCounter++; 
        if (COCounter >= (methaneCONumberofReadings - 1)) COCounter = (methaneCONumberofReadings - 1);

    } else if (methaneCOCycleIndex == 4) {                               // if current cycle phase is 4
        methaneValues[methaneCounter] = analogRead(methaneCOHeaterPin);           // read methane value into array and update counter

        Serial.print(" Methane counter ");
        Serial.print(methaneCounter);
        Serial.print(" and values: ");
        Serial.println(methaneValues[methaneCounter]); 

        methaneCounter++;     
        if (methaneCounter >= (methaneCONumberofReadings - 1)) methaneCounter = (methaneCONumberofReadings - 1);
        
    }
}


// READ VOC SENSORS: Reads the latest data from the VOC sensor into an array
// Sensor data is saved into an array and counter is increased.
void readVOCSensors() {
    if (readTime(previousRead, readInterval)) {  
        // read VOC sensor
        previousRead = millis();

        vocValues[vocCounter] = analogRead(vocPin);
        
        Serial.print("time ");
        Serial.print(millis());
        Serial.print(" voc counter ");
        Serial.print(vocCounter);
        Serial.print(" and values: ");
        Serial.println(vocValues[vocCounter]); 

        vocCounter++; 
        if (vocCounter >= (numberOfReadings - 1)) vocCounter = (numberOfReadings - 1);

    }
}



// AVERAGE VOC SENSORS: Averages the sensor readings before sending to pachube
int avgVOCsensor() {
     long sumAverage = 0;
     for (int i = 0; i < vocCounter; i++) 
         { sumAverage = vocValues[i] + sumAverage; } 
     int average = sumAverage / vocCounter;

     Serial.print("VOC sensor - sum ");
     Serial.print(sumAverage);
     Serial.print(" counter ");
     Serial.print(vocCounter);
     Serial.print(": ");
     Serial.println(average);

     vocCounter = 0; 
     return average;
}


// AVERAGE METHANE SENSORS: averages the sensor readings before sending to pachube
int avgMethaneSensor() {
     long sumAverage = 0;
     for (int i = 0; i < methaneCounter; i++) 
         { sumAverage = methaneValues[i] + sumAverage; } 
     int average = sumAverage / methaneCounter;

     Serial.print("Methane sensor - sum ");
     Serial.print(sumAverage);
     Serial.print(" counter ");
     Serial.print(methaneCounter);
     Serial.print(": ");
     Serial.println(average);

     methaneCounter = 0;
     return average;
}


// AVERAGE CARBON MONOXIDE SENSORS: averages the sensor readings before sending to pachube
int avgCOSensor() {
     long sumAverage = 0;
     for (int i = 0; i < COCounter; i++) 
         { sumAverage = COValues[i] + sumAverage; } 
     int average = sumAverage / COCounter;

     Serial.print("CO sensor - sum ");
     Serial.print(sumAverage);
     Serial.print(" counter ");
     Serial.print(COCounter);
     Serial.print(": ");
     Serial.println(average);

     COCounter = 0;
     return average;
}


