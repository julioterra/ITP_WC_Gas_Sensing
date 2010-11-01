Client localClient(remoteServer, 80);      // sets up the arduino as a client of the pachube server
unsigned int interval;                     // 

char buff[64];
int pointer = 0;

void setupEthernet() {
  resetEthernetShield();
  Client remoteClient(255);                // creates a second client using port 255 of remote server 
  delay(500);
  interval = UPDATE_INTERVAL;
  Serial.println("setup complete");
}

void clean_buffer() {
  pointer = 0;
  memset(buff,0,sizeof(buff));     // memset clears the array buff, and keeps the size unchanged
}

// begin ethernet connection using IP and MAC address
void resetEthernetShield(){
  Serial.println("reset ethernet");
  Ethernet.begin(mac, ip);
}

