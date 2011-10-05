/*
 * Garage Keypad
 * Author: Joseph Monti
 */

#include <EEPROM.h>

const int keypad1Pin = 2;
const int keypad2Pin = 3;
const int keypad3Pin = 4;
const int keypad4Pin = 5;
const int keypad5Pin = 6;
const int keypad6Pin = 7;
const int keypad7Pin = 8;

const int garagePin = 9;

const int activeLed = 10;
const int unlockLed = 11;
const int errorLed = 12;

const int KEY_ASTERISK = 10;
const int KEY_ZERO = 11;
const int KEY_POUND = 12;

const long timeoutTime = 5000;
const long debounceTimeout = 50;
const long debounceDelay = 50;

const int ERR_INVALID_CODE = 1;
const int ERR_TIMEOUT = 2;

int secretMaster[] = { 5, 7, 3, 8 };
int master[] = { 5, 7, 3, 8 };

const boolean USE_SERIAL = true;

const byte EERPOM_INIT_MAGIC = 42;

void setup() {
   pinMode(keypad5Pin, OUTPUT);
   pinMode(keypad6Pin, OUTPUT);
   pinMode(keypad7Pin, OUTPUT);
   digitalWrite(keypad5Pin, LOW);
   digitalWrite(keypad6Pin, LOW);
   digitalWrite(keypad7Pin, LOW);
   
   pinMode(keypad1Pin, INPUT);
   pinMode(keypad2Pin, INPUT);
   pinMode(keypad3Pin, INPUT);
   pinMode(keypad4Pin, INPUT);
   
   pinMode(garagePin, OUTPUT);
   digitalWrite(garagePin, LOW);
   
   pinMode(activeLed, OUTPUT);
   pinMode(unlockLed, OUTPUT);
   pinMode(errorLed, OUTPUT);
   digitalWrite(activeLed, LOW);
   digitalWrite(unlockLed, LOW);
   digitalWrite(errorLed, LOW);
   
   if ( EEPROM.read(EERPOM_INIT_MAGIC) == EERPOM_INIT_MAGIC ) {
      for ( int i = 0; i < 4; i++ ) {
         master[i] = EEPROM.read(i);
      }
   } else {
      for ( int i = 0; i < 4; i++ ) {
         EEPROM.write(i, master[i]);
      }
      EEPROM.write(EERPOM_INIT_MAGIC, EERPOM_INIT_MAGIC);
   }
   
   if ( USE_SERIAL ) Serial.begin(9600);
}

void loop() {
   int entered[] = { -1, -1, -1, -1 };
   int button;

   for ( int i = 0; i < 4; i++ ) {
      button = waitForButton( i > 0 );
      if ( button < 0 ) {
         if ( i > 0 ) {
            digitalWrite(activeLed, LOW);
         }
         return;
      }
      if ( i == 0 ) {
         digitalWrite(activeLed, HIGH);
         if ( button == KEY_ASTERISK ) {
            digitalWrite(activeLed, LOW);
            resetCode();
            return;
         } else if ( button == KEY_POUND ) {
            digitalWrite(activeLed, LOW);
            resetCode();
            return;
         }
      }
      entered[i] = button;
   }

   digitalWrite(activeLed, LOW);

   for ( int i = 0; i < 4; i++ ) {
      if ( entered[i] != master[i] ) {
         err( ERR_INVALID_CODE );
         return;
      }
   }
    
   digitalWrite(unlockLed, HIGH);

   openGarage();
    
   delay(3000);

   digitalWrite(unlockLed, LOW);
}

void openGarage() {
   
}

void resetCode() {
   int entered[] = { -1, -1, -1, -1 };
   boolean checkSecretMaster = false;
   
   delay(2000);
   digitalWrite(activeLed, HIGH);
   delay(1000);
   digitalWrite(activeLed, LOW);
   delay(1000);
   digitalWrite(activeLed, HIGH);
   delay(1000);
   digitalWrite(activeLed, LOW);
   delay(1000);
   digitalWrite(activeLed, HIGH);

   for ( int i = 0; i < 4; i++ ) {
      int button = waitForButton( true );
      if ( button < 0 ) {
         digitalWrite(activeLed, LOW);
         return;
      }
      entered[i] = button;
   }

   for ( int i = 0; i < 4; i++ ) {
      if ( entered[i] != master[i] ) {
         checkSecretMaster = true;
         break;
      }
   }
    
   if ( checkSecretMaster ) {
      for ( int i = 0; i < 4; i++ ) {
         if ( entered[i] != secretMaster[i] ) {
            err( ERR_INVALID_CODE );
            return;
         }
      }
   }

   digitalWrite(activeLed, LOW);
   delay(1000);
   digitalWrite(activeLed, HIGH);
   delay(1000);
   digitalWrite(activeLed, LOW);
   delay(1000);
   digitalWrite(activeLed, HIGH);

   for ( int i = 0; i < 4; i++ ) {
      int button = waitForButton( true );
      if ( button == -1 ) {
         digitalWrite(activeLed, LOW);
         return;
      }
      entered[i] = button;
   }

   for ( int i = 0; i < 4; i++ ) {
      master[i] = entered[i];
      EEPROM.write(i, master[i]);
   }
   
   digitalWrite(activeLed, LOW);
   digitalWrite(unlockLed, HIGH);
    
   delay(3000);

   digitalWrite(unlockLed, LOW);
}

int waitForButton( boolean wait ) {
   if ( !wait ) return getDebouncedButton();
   
   long startTimeout;
   int button = -1;

   startTimeout = millis();
   while ( ( button = getDebouncedButton() ) < 0 && ( millis() - startTimeout ) < timeoutTime );
   if ( button < 0 ) {
      // timeout
      err( ERR_TIMEOUT );
   }

   return button;
}

int getDebouncedButton() {
   int button = -1;
   int tmp;
   long debounceTimeoutStart;
   long debounceDelayStart;
   
   debounceTimeoutStart = millis();
   while ( button < 0 && ( millis() - debounceTimeoutStart ) < debounceTimeout ) {
      button = getButton();
      debounceDelayStart = millis();
      while ( (tmp = getButton() ) == button && ( millis() - debounceDelayStart ) < debounceDelay );
      if ( tmp != button ) {
         button = -1;
      }
   }
   
   if ( button < 0 ) return button;
   
   debounceDelayStart = 0;
   while ( true ) {
      tmp = getButton();
      if ( tmp < 0 ) {
         if ( debounceDelayStart == 0 ) {
            debounceDelayStart = millis();
         } else if ( ( millis() - debounceDelayStart ) >= debounceDelay ) {
            if ( USE_SERIAL ) Serial.println(button);
            
            return button;
         }
      } else {
         debounceDelayStart = 0;
      }
   }
   
   return -1;
}

int getButton() {
   int s;
   int v;
   
   for ( int i = 0; i < 3; i++ ) {
      digitalWrite(keypad5Pin + i, HIGH);
      // delay here?
      //delay(1);
      for ( int j = 0; j < 4; j++ ) {
         s = digitalRead(keypad1Pin + j);
         if ( s == HIGH ) {
            digitalWrite(keypad5Pin + i, LOW);
            v = (3 * j) + i + 1;
            if ( v == KEY_ZERO ) {
               v = 0;
            }
            return v;
         }
      }
      digitalWrite(keypad5Pin + i, LOW);
      //delay(1);
   }
   return -1;
}

void err( int code ) {
   for ( int i = 0; i < code; i++ ) {
      if ( i > 0 ) delay(1000);
      digitalWrite(errorLed, HIGH);
      delay(1000);
      digitalWrite(errorLed, LOW);
   }
}
