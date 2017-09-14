// Keyboard
Hid hi;
HidMsg msg;
0 => int keyboard;
if(!hi.openKeyboard(keyboard))
    me.exit();
chout <= "a - original\n";
chout <= "s - volume\n";
chout <= "d - pitch\n";
chout <= "f - tempo\n";
chout <= "g - drum\n";
chout <= "h - chord\n";
chout <= "j - effect\n";
chout <= "k - stop\n";
chout <= "q - exit\n";

SndBuf original => dac;
SndBuf volume   => dac;
SndBuf pitch    => dac;
SndBuf tempo    => dac;
SndBuf drum     => dac;
SndBuf chord    => dac;
SndBuf effect   => dac;
me.dir() + "/sound/" => string path;
path + "raw.wav"            => original.read;
path + "volume_target.wav"  => volume.read;
path + "pitch_target.wav"   => pitch.read;
path + "tempo_target.wav"   => tempo.read;
path + "drum_target.wav"    => drum.read;
path + "chord_target.wav"   => chord.read;
path + "effect_target.wav"         => effect.read;
0 => original.gain;
0 => volume.gain;
0 => pitch.gain;
0 => tempo.gain;
0 => drum.gain;
0 => chord.gain;
0 => effect.gain;

while(true)
{
    hi => now;
    hi.recv(msg);
    if(msg.isButtonDown())
    {
        if(msg.ascii == 65)
        {
            1 => original.gain;
            0 => volume.gain;
            0 => pitch.gain;
            0 => tempo.gain;
            0 => drum.gain;
            0 => chord.gain;
            0 => effect.gain;
            0 => original.pos;
        }
        else if(msg.ascii == 83)
        {
            0 => original.gain;
            1 => volume.gain;
            0 => pitch.gain;
            0 => tempo.gain;
            0 => drum.gain;
            0 => chord.gain;
            0 => effect.gain;
            0 => volume.pos;
        }
        else if(msg.ascii == 68)
        {
            0 => original.gain;
            0 => volume.gain;
            1 => pitch.gain;
            0 => tempo.gain;
            0 => drum.gain;
            0 => chord.gain;
            0 => effect.gain;
            0 => pitch.pos;
        }
        else if(msg.ascii == 70)
        {
            0 => original.gain;
            0 => volume.gain;
            0 => pitch.gain;
            1 => tempo.gain;
            0 => drum.gain;
            0 => chord.gain;
            0 => effect.gain;
            0 => tempo.pos;
        }
        else if(msg.ascii == 71)
        {
            0 => original.gain;
            0 => volume.gain;
            0 => pitch.gain;
            0 => tempo.gain;
            1 => drum.gain;
            0 => chord.gain;
            0 => effect.gain;
            0 => drum.pos;
        }
        else if(msg.ascii == 72)
        {
            0 => original.gain;
            0 => volume.gain;
            0 => pitch.gain;
            0 => tempo.gain;
            0 => drum.gain;
            1 => chord.gain;
            0 => effect.gain;
            0 => chord.pos;
        }
        else if(msg.ascii == 74)
        {
            0 => original.gain;
            0 => volume.gain;
            0 => pitch.gain;
            0 => tempo.gain;
            0 => drum.gain;
            0 => chord.gain;
            1 => effect.gain;
            0 => effect.pos;
        }
        else if(msg.ascii == 75)
        {
            0 => original.gain;
            0 => volume.gain;
            0 => pitch.gain;
            0 => tempo.gain;
            0 => drum.gain;
            0 => chord.gain;
            0 => effect.gain;
        }
        else if(msg.ascii == 81)
            Std.system("taskkill /f /im chuck.exe");
    }
}
