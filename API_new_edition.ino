/* BasicMSoRo.ino */
/* Author: Caitlin Freeman
 * Last updated: 1/27/22
 * This code enables gait-based control of a multi-limbed robot with
 * with bang-bang (i.e., on/off) actuation. The user will use the 
 * user-defined parameter block to define
 *   1. Arduino pin numbers
 *   2. time constants
 *   3. fundamental locomotion gaits
 * and can control gait switching by manipulating the loop block. 
 * Future work:
 *   1. More advanced gait switching by recognizing common nodes, 
 *      including automatic gait switching handling
 *   2. Communication with MATLAB for feedback control
 *   3. Automatic gait permutation handling
 */


/* User-defined parameters */
const int8_t motor[] ={2,3,5,6,9,10,11,12};      // motor pins on Arduino
const int T_transition = 450;    // total transition time constant in ms.
const int T_unspool = 50;        // motor unspooling time constant in ms.
int8_t cycle1[4]; 
int8_t cycle2[10];                       // input gait cycle 2
String cmd;
int8_t b;
int len;
int8_t g_aa[10];
int g_a[10];
char inString1[10];
String T_d1;
String gtype;
String gnum;
String gnum2;
int gnum1;
int gait_value_int;
String gait_type;
String gait_value;

String check;

/* If you want to use more than 2 cycles make sure to also add variables
 * to define their lengths. 
 */


/* Initializations (should not change) */
const int8_t number_of_motors = sizeof(motor)/ 2;    // bang-bang control
/* If more robot states are desired (e.g., including intermediate actuation
 * states), the exponent base here can be adjusted. 
 */
const int number_of_states = pow(2, number_of_motors);
/* Initialize matrix to store all actuation permutations (robot states). */
int state_matrix[number_of_motors][number_of_states] = { };   
/* Use booleans to avoid excessive / unwanted motor unspooling. */
bool just_curled[number_of_motors] = { };
bool just_relaxed[number_of_motors] = { };
const int8_t cycle1_size = sizeof(cycle1);
const int8_t cycle2_size = sizeof(cycle2);

/* Setup function for communication and state definition (runs once). */
void setup() {
  Serial.begin(9600); // baud rate for serial monitor communication (bps).
  define_states();
  delay(5000);
}


/* Anything placed inside the loop function will cycle continously forever
 * unless interrupts are added. 
 */
void loop() 
{
  while(Serial.available()==0){}
    byte ser_read;
    ser_read = Serial.readBytesUntil(' ', inString1, 100);
    inString1[ser_read] = '\0';
    cmd = String(inString1); /* Initializing the action to be performed - to define gaits("define") or execute the gaits("start")*/
    if(cmd == "define")
    {
      define_cycle();
    }
    if(cmd == "start")
    {
      start_cycle();
    }
}

/* This  function defines a matrix of robot states. Basically, it labels each
 * state with a binary number that corresponds to which motors are on or off.
 * 1 = on, 0 = off 
 */
void define_states() {
  for (int k=0; k<= number_of_states-1; k++) {
    int spacing=1;
    for (int j=number_of_motors-1; j>=0; j--) {
      if (state_matrix[j][k]==0 && k+spacing<=number_of_states-1){
        state_matrix[j][k+spacing]=1;
      }
      spacing = spacing*2;
    }
  }
  for (int m=0; m<=number_of_states-1; m++) {
    /* This part is optional as it just prints the binary value of each 
     *  state number (helpful for debugging).
     */
    Serial.print("State ");
    Serial.print(m+1);
    Serial.print(" = ");
    for (int n=0; n<=number_of_motors-1;n++){
      Serial.print(state_matrix[n][m]);
    }
    Serial.println(" ");
    }
}

/* This  function controls the motor based on the gait cycle (i.e., array of
 * state numbers) provided.
 */
void cycle_through_states (int8_t *cycle, int8_t cycle_size) {
  for (int i=0; i<cycle_size;i++) {
    unsigned long transition_start = millis();
    Serial.print("State ");
    Serial.print(cycle[i]);
    Serial.print(": ");
    for (int j=0; j<=3; j++) {
      Serial.print(state_matrix[j][cycle[i]-1]);
      if (state_matrix[j][cycle[i]-1] == 0 && just_relaxed[j]==false) {
        digitalWrite(motor[2*j], LOW);
        digitalWrite(motor[2*j+1], HIGH);
        just_relaxed[j] = true;
        just_curled[j] = false;
      }
      else if (state_matrix[j][cycle[i]-1] == 1)  {
        digitalWrite(motor[2*j],HIGH);
        digitalWrite(motor[2*j+1], LOW);
        just_relaxed[j] = false;
        just_curled[j] = true;
      }
      if (j==3) {
        delay(T_unspool);
        for (int k=0; k<=3; k++) {
          if (state_matrix[k][cycle[i]-1] == 0) {
            digitalWrite(motor[2*k+1], LOW);
          }
          if (k==3){
            while (millis() -transition_start<= T_transition-1) {
            delay(1);
            }
            Serial.println("");
          }
        }
       }
    }
  }
}


/* This function takes input for defining the gait types. 
 *  Example A = [2,3,5,9];
 */
void define_cycle()
{
byte ser_read;
ser_read = Serial.readBytesUntil(' ', inString1, 100);
inString1[ser_read] = '\0';
gait_type = String(inString1);
int i = 0;
gait_value = "on";
if(gait_type == "A")
{
while(gait_value != "end")
{
Serial.println("Inside A");
ser_read = Serial.readBytesUntil(' ', inString1, 100);
inString1[ser_read] = '\0';
gait_value = String(inString1);
gait_value_int = gait_value.toInt();
Serial.println(gait_value_int);
cycle1[i] = (int8_t)gait_value_int;
i = i+1;    
}
Serial.println("Defined"); /* This is printed so that Matlab can read it from Serial port for acknowledging that gait defining process 
                               has been completed*/
}
}

/*
 * For the given definition of gaits type, this function performs the execution of the gait and number of times it needs to be performed.
 * Example: "start A 12" - Performs gait A for 12 times.
 */
void start_cycle()
{
Serial.println("Inside Start");
byte ser_read;
ser_read = Serial.readBytesUntil(' ', inString1, 100);
inString1[ser_read] = '\0';
gait_type = String(inString1);
Serial.println(gtype);
if(gait_type == "A")
{
ser_read = Serial.readBytesUntil(' ', inString1, 100);
inString1[ser_read] = '\0';
gnum2 = String(inString1);
gnum1 = gnum2.toInt();
Serial.println(gnum1);
  for (int k=0; k<=gnum1 ; k++) 
  {
    cycle_through_states(cycle1, cycle1_size);
  }
}
}


