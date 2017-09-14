// Session begin
Std.system("echo ----------------------------------------- >> log.txt");
if(me.args())
    Std.system("echo New Effect Manipulation " + me.arg(0) + ">> log.txt");
else
    Std.system("echo New Effect Manipulation >> log.txt");
Std.system("echo %date:~0,4%-%date:~5,2%-%date:~8,2% %time% >> log.txt");
// Check connectivity
cherr <= "Checking serial ports...\n";
SerialIO.list() @=> string serial_list[];

for(int i; i < serial_list.cap(); i++)
{
    cherr <= i <= ": " <= serial_list[i] <= IO.newline();
}

// Allow the user to select the devices via arguments
2 => int device;

if(device >= serial_list.cap())
{
    cherr <= "Serial device " <= device <= " is not available\n";
    me.exit(); 
}

SerialIO cereal;
if(!cereal.open(device, SerialIO.B9600, SerialIO.ASCII))
{
	cherr <= "Unable to open serial device '" <= serial_list[device] <= "'\n";
	me.exit();
}

// Keyboard
Hid hi;
HidMsg msg;
0 => int keyboard;
if(!hi.openKeyboard(keyboard))
    me.exit();
cherr <= "Keyboard is ready.\n";

cherr <= "Fine.\n";

//==============================================================================

// Global serial input variable
512     => int serial_input;
// Standard bpm
160     => int standard_bpm;
// Target effect
// For definition, see below
9999    => int target_input;
// Boundaries of input data
1023    => int input_data_max;
0       => int input_data_min;
(input_data_max + input_data_min)/2 => int input_data_median;
input_data_max - input_data_min     => int input_data_range;

// Effects to import
SndBuf hipass   => dac;
SndBuf filter   => dac;
SndBuf original => dac;
SndBuf delayed  => dac;
SndBuf reverb   => dac;
SndBuf target_track => dac;
me.dir() + "/sound/" => string path;
path + "hipass.wav" => hipass.read;
path + "filter.wav" => filter.read;
path + "raw.wav"    => original.read;
path + "delay.wav"  => delayed.read;
path + "reverb.wav" => reverb.read;
path + "target.wav" => target_track.read;

// Effect threshold
205 => int threshold0;
410 => int threshold1;
614 => int threshold2;
820 => int threshold3;

// Keyboard input 
512     => int keyboard_input;
204     => int d_keyboard;

//==============================================================================
0 => int testee_query;

fun void update_serial_input()
{
    0 => int using_keyboard;
    0 => int n_queries;
    0 => int notified_beginning;
    while(true)
    {
        cereal.onLine() => now;
        cereal.getLine() => string line;
        if(line == "over")
        {
            0 => testee_query;
            0 => using_keyboard;
            cherr <= "Over.\n";
            Std.system("echo Test over             at %time% >> log.txt");
            Std.system("taskkill /f /im chuck.exe");
        }
        if(Std.atoi(line) == -1)
        {
            0 => using_keyboard;
            0 => notified_beginning;
            if(!testee_query)
            {
                Std.system(
                    "echo Testee query "
                    + Std.itoa(n_queries)
                    + "      at %time% >> log.txt");
                cherr <= "Testee query " + Std.itoa(n_queries++) + "\n";
                1 => testee_query;
            }
            target_input => serial_input;
        }
        else if(Std.atoi(line) == -2)
        {
            0 => testee_query;
            0 => notified_beginning;
            if(!using_keyboard)
            {
                keyboard_input => serial_input;
                Std.system("echo Keyboard operation  at %time% >> log.txt");
                cherr <= "Keyboard operation.\n";
                1 => using_keyboard;
            }
            // hi => now;
            hi.recv(msg);
            if(msg.isButtonDown())
            {
                if(msg.ascii == 65)
                {
                    if(serial_input < threshold3)
                    {
                        d_keyboard +=> keyboard_input;
                        keyboard_input => serial_input;
                    }
                }
                if(msg.ascii == 83)
                {
                    if(serial_input > threshold0)
                    {
                        d_keyboard -=> keyboard_input;
                        keyboard_input => serial_input;
                    }
                }
                0.2::second => now;
            }
        }
        else
        {
            0 => testee_query;
            0 => using_keyboard;
            Std.atoi(line) => serial_input;
            if(serial_input != 512 && !notified_beginning)
            {
                Std.system("echo Device manipulation at %time% >> log.txt");
                cherr <= "Device manipulation begins.\n";
                1 => notified_beginning;
            }
        }
    }
}

fun void switch_effect()
{
    serial_input => int serial_now;
    6 => int state;
    while(1)
    {
        serial_input => serial_now;
        if(serial_now <= threshold0)
        {
            if(state != 0)
            {
                Std.system("echo State 1: High pass    at %time% >> log.txt");
                chout <= "State 1: High pass\n";
            }
            0 => state;
        }
        else if(serial_now <= threshold1)
        {
            if(state != 1)
            {
                Std.system("echo State 2: Low pass     at %time% >> log.txt");
                chout <= "State 2: Low pass\n";
            }
            1 => state;
        }
        else if(serial_now <= threshold2)
        {
            if(state != 2)
            {
                Std.system("echo State 3: Orginal      at %time% >> log.txt");
                chout <= "State 3: Orginal\n";
            }
            2 => state;
        }
        else if(serial_now <= threshold3)
        {
            if(state != 3)
            {
                Std.system("echo State 4: Delayed      at %time% >> log.txt");
                chout <= "State 4: Delayed\n";
            }
            3 => state;
        }
        else if(serial_now <= 1023)
        {
            if(state != 4)
            {
                Std.system("echo State 5: Reverb       at %time% >> log.txt");
                chout <= "State 5: Reverb\n";
            }
            4 => state;
        }
        else
            5 => state;
        
        if(state == 0)
        {
            1 => hipass.gain;
            0 => filter.gain;
            0 => original.gain;
            0 => delayed.gain;
            0 => reverb.gain;
            0 => target_track.gain;
        }
        else if(state == 1)
        {
            0 => hipass.gain;
            1 => filter.gain;
            0 => original.gain;
            0 => delayed.gain;
            0 => reverb.gain;
            0 => target_track.gain;
        }
        else if(state == 2)
        {
            0 => hipass.gain;
            0 => filter.gain;
            1 => original.gain;
            0 => delayed.gain;
            0 => reverb.gain;
            0 => target_track.gain;
        }
        else if(state == 3)
        {
            0 => hipass.gain;
            0 => filter.gain;
            0 => original.gain;
            1 => delayed.gain;
            0 => reverb.gain;
            0 => target_track.gain;
        }
        else if(state == 4)
        {
            0 => hipass.gain;
            0 => filter.gain;
            0 => original.gain;
            0 => delayed.gain;
            1 => reverb.gain;
            0 => target_track.gain;
        }
        else if(state == 5)
        {
            0 => hipass.gain;
            0 => filter.gain;
            0 => original.gain;
            0 => delayed.gain;
            0 => reverb.gain;
            1 => target_track.gain;
        }
        else
        {
            0 => hipass.gain;
            0 => filter.gain;
            1 => original.gain;
            0 => delayed.gain;
            0 => reverb.gain;
            0 => target_track.gain;
        }
        
        0.01::second => now;
    }
}

// Concurrently run updating serial input
spork ~ update_serial_input();
spork ~ switch_effect();

// Wait for 1 second
chout <= "Effect manipulation session begins.\n";

// Main program
while(true)
{
    0 => hipass.pos;
    0 => filter.pos;
    0 => original.pos;
    0 => delayed.pos;
    0 => reverb.pos;
    0 => target_track.pos;
    5.333::second => now;
    if(!testee_query) Std.system("echo One loop done here. >> log.txt");
}