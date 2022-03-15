// 8 V with bench power supply (BK Precision 1786B single output)
// Seeduino Xiao microcontroller with ta8428k driver 

// Actuator Resistance Values
  // right limb = 7.9 ohm 
  // left limb = 6.7 ohm 

// PWM-Current Relationship:
  // 60 PWM:
    // right limb = 211 mA
    // left limb = 242 mA

  // 70 PWM
    //left limb = 280 mA
    // right limb = 247 mA

  // 75 PWM
    // left limb = 302 mA
    // right limb = 264 mA

//// Define LEDs on Seeeduino Xiao
//#define PIN_LED_13  (13u)
//#define PIN_LED     PIN_LED_13
//// LED_BUILTIN is already programmed to blink during resets / uploading
//#define LED_BUILTIN PIN_LED
//#define PIN_LED_RXL          (12u)
//#define PIN_LED_TXL          (11u)
//// PIN_LED2 will automatically turn on when any serial communication is being recieved by the seeeduino
//#define PIN_LED2             PIN_LED_RXL
////PIN_LED3 will automatically turn on when any serial communication is being transmitted to the seeeduino
//#define PIN_LED3             PIN_LED_TXL


// Declare variables

// define Seeduino pin numbers. These can be reversed to change the locomotion direction
int left = 8;
int right = 7;
int left_led = 9;
int right_led = 10;
byte m_char;
// boolean flags recording whether LEDs are currently on
bool left_led_on = false;
bool right_led_on = false;

// max pulse width modulation value (out of 225). This results in a max duty cycle of 60/225 = 27%
int pwm_val_l =65;   // left actuator pwm
int pwm_val_r = 70;    // right actuator pwm

// actuation time parameters
const int rise_time = 3000; //  T_r in milliseconds
const int pulse_width = 1000; // T_w in milliseconds, time at max actuation

// initial guess / IC
int T_d = 2000; // T_d in milliseconds, time between left and right actuation


const int time_period = 10000; // T in milliseconds, total time for actuation waveform

// number of steps for data output and analog value writing
const int time_step = 10; // milliseconds
const int N_r = rise_time/ time_step;
const int N = time_period / time_step; 
int N_d = T_d / time_step;
const int N_w = pulse_width / time_step;

// initialize actuators as being off (0 PWM)
int left_signal = 0;
int right_signal = 0;

int i = 0;
// gait (cycle) number
int m = 0;
// current values in mA
float left_current = 0;
float right_current = 0;

// declare functions 
void set_actuation_signal();
void record_actuation_signal();
void run_calibration_routine();

char inString[10];

void setup() {
  // sets ups serial communication so we can plot and record PWM signals
  Serial.begin(9600);
  // define pins as being output
  pinMode(left, OUTPUT);
  pinMode(right, OUTPUT);

// Because we are only transmitting and not recieving serial communication, we will use PIN_LED2 to show actuation timing
  pinMode(left_led,OUTPUT);
  pinMode(right_led,OUTPUT);
  // initially set actuator signals to LOW (0 PWM)
set_actuation_signal();
  // initial delay to allow time to set up power and camera
  delay(5000);

  // CALIBRATION ROUTINE- RUNS ONCE
  
 //run_calibration_routine(); // not  needed for feedback control, only to calibrate shape space equations
}



void loop() {
// each loop is one locomotion gait cycle. It can be divided into four actuation blocks: left limb (2s), both limbs (2s), right limb(2s), no limbs (6s)
  byte inChar;
 if (Serial.available() > 0) {
    inChar = Serial.readBytesUntil('\n', inString, 10);
    inString[inChar] = '\0';
    T_d = atoi(inString);
}
int N_d = T_d / time_step;
for (i = 1; i <= N  ; i++) // each loop (cycle) runs for N steps (T ms)
{
// First part of loop: sets the current for left and right limbs
    // start with left limb actuation
  if (i <= N_r)  
  {
    left_signal = i*pwm_val_l/N_r; // if time <= rise time, do ramp input for left limb up to pwm_val_l
  }

  if (i > N_d && i <= N_d+N_r) // if time> time_delay, do ramp input for right limb up to pwm_val_r for duration of rise_time 
  {
    right_signal = (i-N_d)*pwm_val_r/N_r;
  }

  if (i ==N_r+1) {
    left_signal = pwm_val_l; // as soon as rise_time has passed, set left limb to max current pwm_val_l
    // statements
  }
  if (i==N_d+N_r+1){ // if time_delay + rise_time has passed (right limb has reached max pwm_val_r), hold at max current pwm_val_r
    right_signal = pwm_val_r;
    // statements
  }
  if (i ==N_r+N_w+1) { // if rise_time+pulse_width has passed (left limb has completed actuation), send left limb to 0 
    left_signal = 0;
    // statements
  }
  if (i==N_d + N_r+N_w+1){ // if rise_time+pulse_width +time_delay has passed (right limb has completed actuation), send right limb to 0 
    right_signal = 0;
  }


//Second part of loop: actual functions to write current to the outputs and record in serial monitor / plotter
  set_actuation_signal();
  record_actuation_signal(); // This function includes the time step 

// Third part of loop:control LEDs to signal max actuation
    if (left_led_on == false && left_signal == pwm_val_l) 
    {
    digitalWrite(left_led, HIGH);
    left_led_on = true;
    }
    if (right_led_on == false && right_signal == pwm_val_r) 
    {
    digitalWrite(right_led, HIGH);
    right_led_on = true;
    }
    if (left_led_on == true && left_signal == 0)
      {
    digitalWrite(left_led, LOW);
    left_led_on = false;
    }
    if (right_led_on == true && right_signal == 0) 
    {
    digitalWrite(right_led, LOW);
    right_led_on = false;
    }
    
  }
m = m+1;
m_char = (byte)m;
Serial.println(m_char);
}


// Function Definitions
void set_actuation_signal() {
  // This function sets the left limb output to left_signal (PWM) and the right limb output to right_signal (PWM) 
  // This is considered an analog output, but is really just a pulse-modulated digital output
  analogWrite(left,left_signal);
  analogWrite(right,right_signal);
}


void record_actuation_signal() {
  // This function sends the left_signal and right_signal PWM values to the Serial Monitor and Serial Plotter in increments of 
  // time_step milliseconds 
   delay(time_step);
   left_current = (float) left_signal*242/pwm_val_l;
   right_current = (float) right_signal*247/pwm_val_r;
//SerialUSB.print("Left_Current:");
//SerialUSB.print(left_current);
//SerialUSB.print(" , ");
//SerialUSB.print("Right_Current:");
//SerialUSB.print(right_current);
//SerialUSB.print(" , ");
//SerialUSB.println(300);


}

void run_calibration_routine() {
   // actuate and relax left limb
 for (i = 1; i <= 2*N_r ; i++) {
        left_signal = i*pwm_val_l/N_r;
        set_actuation_signal();
        record_actuation_signal();
         }
      
        digitalWrite(left_led, HIGH);
for (int i = 1; i <=2*N_r; i++){
record_actuation_signal();
}
   left_signal = 0;
   set_actuation_signal();
   digitalWrite(left_led, LOW);

for (int i = 1; i <= 2*N_r; i++){
record_actuation_signal();
}


  // actuate and relax right limb
  for (i = 1; i <= 2*N_r ; i++) {
        right_signal = i*pwm_val_r/N_r;
        if (right_signal ==0) {
          right_signal = 1;
        }
        set_actuation_signal();
        record_actuation_signal();
         }
      
        digitalWrite(right_led, HIGH);
for (int i = 0; i <= 2*N_r; i++){
record_actuation_signal();
}
   right_signal = 0;
   set_actuation_signal();
   digitalWrite(right_led, LOW);

for (int i = 0; i <= 2*N_r; i++){
record_actuation_signal();
}


    // actuate and relax both limbs
  for (i = 1; i <= N_r ; i++) {
        left_signal = i*pwm_val_l/N_r;
        if (left_signal ==0) {
          left_signal = 1;
        }
        right_signal = i*pwm_val_r/N_r;
        if (right_signal ==0) {
          right_signal = 1;
        }
        set_actuation_signal();
        record_actuation_signal();
         }
      digitalWrite(left_led, HIGH);
        digitalWrite(right_led, HIGH);
for (int i = 0; i <= N_r; i++){
record_actuation_signal();
}
   right_signal = 0;
   left_signal = 0;
   set_actuation_signal();
   digitalWrite(left_led,LOW);
   digitalWrite(right_led, LOW);

for (int i = 0; i <= 2*N_r; i++){
record_actuation_signal();
}


}
