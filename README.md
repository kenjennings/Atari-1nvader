# Atari-1nvader
WORK IN PROGRESS - Atari port (parody) of C64 1nvader

It Lives!   Muah-ha-ha-ha!

[![V00 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/00-WIP-FirstSuccessfulRun.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

Finally got something that assembles.  This broken title screen is all it does right now.  Basically, all it does is initialize itself and loops on the Title screen forever.

The stopping point here is that I finally got the animated logo section working.

The big text is made of lines of GTIA 16-grey scale graphics.  The lines are 3 scan lines tall instead of the usual 1 scan line.  (3 scan lines was chosen instead of 4, because 3 scan line GTIA pixels are closer to square on NTSC than 4 scan line pixels.)

GTIA modes are usually seen as lines 1 scan line tall.  Here I stretched them into 3 scan lines tall by using the vertical fine scroll hack.  This means there are only six lines of pixel data needed instead of 18 and this section of the Display List has only one LMS to reference the image.

Naturally, all of this is supported by Display list interrupts to force the vertical scroll hack, and to turn on and off the GTIA color interpretation in this section of the Title screen.

The animated greyscale pixels is done by page flipping between four separate images just by updating the LMS pointer in the Display List.

A color mask travels across the letters from left to right, colorizing the grey pixels.  This is done using the missiles configured for Fifth Player.   A bitmap of the letters is written to the missile memory, and the horizontal position of the missiles is moved from left to right in sync with the graphics letters made of GTIA pixels. 

That's it for now.   You can see other parts of the display below this are messed up as little coding work has been done to support this. 

