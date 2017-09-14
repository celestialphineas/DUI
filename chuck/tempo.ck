// Session begin
Std.system("echo ----------------------------------------- >> log.txt");
if(me.args())
    Std.system("echo New BPM Manipulation " + me.arg(0) + ">> log.txt");
else
    Std.system("echo New BPM Manipulation >> log.txt");
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
// Boundaries of input data
1023    => int input_data_max;
0       => int input_data_min;
(input_data_max + input_data_min)/2 => int input_data_median;
input_data_max - input_data_min     => int input_data_range;
// Target bpm
220     => int target_bpm;
(target_bpm - standard_bpm) * input_data_range / 160 + input_data_median
    => int target_input;
// Keyboard input 
512     => int keyboard_input;
10      => int d_keyboard;

[72, 71, 69, 64,
74, 72, 71, 67,
76, 74, 72, 69,
76, 74, 72, 71
// 69, 71, 72, 69,
// 71, 72, 74, 71,
// 72, 74, 76, 77,
// 71, 72, 74, 76
] @=> int scale_list[];

[1.0, 1, 1, 1, 1, 1, 1, 1,
1, 1, 1, 1, 1, 1, 1, 1
// 1, 1, 1, 1, 1, 1, 1, 1,
// 1, 1, 1, 1, 1, 1, 1, 1
] @=> float beat_list[];

[3, 1, 2, 3, 3, 1, 2, 3,
3, 1, 2, 3, 3, 1, 2, 3
// 3, 1, 2, 3, 3, 1, 2, 3,
// 3, 1, 2, 3, 3, 1, 2, 3
] @=> int strength_list[];

fun void update_serial_input()
{
    0 => int testee_query;
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
            hi.recv(msg);
            if(msg.isButtonDown())
            {
                if(msg.ascii == 65)
                {
                    if(serial_input < 1024 - d_keyboard)
                    {
                        d_keyboard +=> keyboard_input;
                        keyboard_input => serial_input;
                    }
                }
                if(msg.ascii == 83)
                {
                    if(serial_input >= d_keyboard)
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

512 => int latest_serial;
fun float evaluate_beat_time(float beat)
{
    serial_input => int now_serial;
    (now_serial - input_data_median) * 160 / input_data_range + standard_bpm
        => int now_bpm;
    if((now_serial - latest_serial) * 160 / input_data_range != 0)
    {
        Std.system("echo BPM: " + Std.itoa(now_bpm) + " >> log.txt");
        chout <= "BPM: " <= now_bpm <= "\n";
        now_serial => latest_serial;
    }
    return 60 / ((latest_serial - input_data_median) * beat * 160. / input_data_range + standard_bpm);
}

// Concurrently run updating serial input
spork ~ update_serial_input();
// Wait for 1 second
1::second => now;

chout <= "BPM manipulation session begins.\n";

Mandolin instrument => dac;

while(true)
{
    for(0 => int i; i < scale_list.cap(); i++)
    {
        Std.mtof(scale_list[i]) => instrument.freq;
        strength_list[i]/10. + 0.5 => instrument.noteOn;
        0.9 * evaluate_beat_time(beat_list[i])::second => now;
        1.0 => instrument.noteOff;
        0.1 * evaluate_beat_time(beat_list[i])::second => now;
    }
}