// Session begin
Std.system("echo ----------------------------------------- >> log.txt");
if(me.args())
    Std.system("echo New Chord Manipulation " + me.arg(0) + ">> log.txt");
else
    Std.system("echo New Chord Manipulation >> log.txt");
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
1023    => int target_input;
// Boundaries of input data
1023    => int input_data_max;
0       => int input_data_min;
(input_data_max + input_data_min)/2 => int input_data_median;
input_data_max - input_data_min     => int input_data_range;

// Import chord
SndBuf raw_track    => dac;
SndBuf chord        => dac;
me.dir() + "/sound/" => string path;
path + "chord_raw.wav"    => raw_track.read;
path + "chord.wav"  => chord.read;
1   => raw_track.gain;
0   => chord.gain;

// Chord switch threshold
680     => int chord_threshold;
0   => int querying;
0   => float relative_time;
fun void timing()
{
    while(true)
    {
        0.01 +=> relative_time;
        0.01::second => now;
    }
}

fun float time2tempo(float rtime)
{
    return rtime/5.333 * 16 + 0.5;
}

fun void update_serial_input()
{
    0 => int testee_query;
    0 => int using_keyboard;
    0 => int n_queries;
    0 => int notified_beginning;
    0 => int notified_device;
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
            1 => querying;
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
            if(relative_time >= 2.664)
            {
                1 => chord.gain;
            }
            else 0 => chord.gain;
        }
        else if(Std.atoi(line) == -2)
        {
            0 => querying;
            0 => testee_query;
            0 => notified_beginning;
            if(!using_keyboard)
            {
                0 => chord.gain;
                Std.system("echo Keyboard operation  at %time% >> log.txt");
                cherr <= "Keyboard operation.\n";
                1 => using_keyboard;
            }
            if(relative_time < 0.1)
                0 => chord.gain;
            hi.recv(msg);
            if(msg.isButtonDown())
            {
                if(msg.ascii == 65)
                {
                    relative_time => time2tempo => float tempo;
                    1 => chord.gain;
                    Std.system("echo Chord: "
                        + Std.ftoa(tempo, 2) + " >> log.txt");
                    chout <= "Chord: " <= time2tempo(relative_time) <= "\n";
                }
                if(msg.ascii == 83)
                {
                    0 => chord.gain;
                }
                0.2::second => now;
            }
        }
        else
        {
            0 => querying;
            0 => testee_query;
            Std.atoi(line) => serial_input;
            if(serial_input != 512 && !notified_beginning)
            {
                Std.system("echo Device manipulation at %time% >> log.txt");
                cherr <= "Device manipulation begins.\n";
                1 => notified_beginning;
            }
            if(serial_input > chord_threshold)
            {
                if(!notified_device)
                {
                    relative_time => time2tempo => float tempo;
                    1 => chord.gain;
                    Std.system("echo Chord: "
                        + Std.ftoa(tempo, 2) + " >> log.txt");
                    chout <= "Chord: " <= time2tempo(relative_time) <= "\n";
                    1 => notified_device;
                }
            }
            else
            {
                0 => chord.gain;
                0 => notified_device;
            }
        }
    }
}

spork ~ update_serial_input();
spork ~ timing();

while(true)
{
    0. => relative_time;
    if(!querying)
    {
        0 => raw_track.pos;
        0 => chord.pos;
        5.5::second => now;
        Std.system("echo One loop done here. >> log.txt");
    }
    else
    {
        0 => chord.gain;
        0 => raw_track.pos;
        0 => chord.pos;
        2.664::second => now;
        1 => chord.gain;
        (5.5 - 2.664)::second => now;
    }
}