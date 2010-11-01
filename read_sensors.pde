// READ TIME FUNCTION: checks to see if interval has passed to do another data read
boolean readTime() {
  if (millis() - previousRead > readInterval) { 
    previousRead = millis();
    return true; 
  }
  return false; 
}


// INIT COUNTER: checks if data has been uploaded and re-initializes the counters for each sensor
boolean initCounter(boolean initFlag) {
  if(initFlag) 
      { for (int i = 0; i < numberOfSensors; i++) sensorCounter[i] = 0; }
  return false;
}



// READ SENSORS: reads the latest data from each sensor into an array
void readSensors() {
  for (int i = 0; i < numberOfSensors; i++) { 
      sensorData[i][sensorCounter[i]] = analogRead(sensorPin[i]);
      sensorCounter[i]++; 
      if (sensorCounter[i] >= (numberOfReadings - 1)) sensorCounter[i] = (numberOfReadings - 1);
      
      Serial.print("sensor ");
      Serial.print(i);
      Serial.print(" counter ");
      Serial.print(sensorCounter[i]);
      Serial.print(": ");
      Serial.println(sensorData[i][sensorCounter[i]]);
  } 
}


// AVERAGE SENSORS: averages the sensor readings before sending to pachube
int avgSensors(int sensorNum) {
     long sumAverage = 0;
     for (int i = 0; i < sensorCounter[sensorNum]; i++) 
         { sumAverage = sensorData[sensorNum][i] + sumAverage; } 
     int average = sumAverage / sensorCounter[sensorNum];

     Serial.print("sum ");
     Serial.print(sumAverage);
     Serial.print(" counter ");
     Serial.print(sensorCounter[sensorNum]);
     Serial.print(" average sensor ");
     Serial.print(sensorNum);
     Serial.print(": ");
     Serial.println(average);

     return average;
}


