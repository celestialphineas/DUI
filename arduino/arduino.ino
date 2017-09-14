/* Based on CustomKeypad.pde
   Original author Alexander Brevig
*/
#include <Keypad.h>

const byte ROWS = 4; //four rows
const byte COLS = 4; //four columns
//define the cymbols on the buttons of the keypads

int v0 = 0;
int v1 = 0;
int v2 = 0;
int v3 = 0;
int v4 = 0;
int v5 = 0;
char trans;
char hexaKeys[ROWS][COLS] = {
    {'0', '1', '2', '3'},
    {'4', '5', '6', '7'},
    {'8', '9', 'A', 'B'},
    {'C', 'D', 'E', 'F'}};
byte rowPins[ROWS] = {9, 8, 7, 6}; //connect to the row pinouts of the keypad
byte colPins[COLS] = {5, 4, 3, 2}; //connect to the column pinouts of the keypad

//initialize an instance of class NewKeypad
Keypad customKeypad = Keypad(makeKeymap(hexaKeys), rowPins, colPins, ROWS, COLS);

void setup()
{
  Serial.begin(9600);
}

void loop()
{
  char customKey = customKeypad.getKey();
  if (customKey)
  {
    trans = customKey;
  }
  if (trans)
  {
    switch (trans)
    {
    case '0':
      v0 = analogRead(0);
      Serial.println(v0);
      break;

    case '1':
      v1 = analogRead(1);
      Serial.println(v1);
      break;

    case '2':
      v2 = analogRead(3);
      Serial.println(v2);
      break;

    case '3':
      v3 = analogRead(4);
      Serial.println(v3);
      break;

    case '4':
      v4 = analogRead(5);
      v4 = 394.58 + 4.94991 * v4 - 0.00974494 * v4 * v4;
      if (v4 < 0)
      {
        v4 = 0;
      }
      if (v4 > 1023)
      {
        v4 = 1023;
      }
      Serial.println(v4);
      break;

    case '5':
      Serial.println("-1");
      break;

    case '6':
      Serial.println("-2");
      break;

    case '7':
      Serial.println("512");
      break;

    case '8':
      Serial.println("over");
      break;

    default:
      Serial.println("512");
      break;
    }
  }
  else
  {
    Serial.println("512");
  }
  delay(50);
}
