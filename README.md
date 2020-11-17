# Atari-1nvader
WORK IN PROGRESS - Atari port (parody) of C64 1nvader

---

**13 Nov 2020 -- It Lives!   Muah-ha-ha-ha!**

[![V00 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/00-WIP-FirstSuccessfulRun.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

Finally got something that assembles.  This broken title screen is all it does right now.  Basically, all it does is initialize itself and loops on the Title screen forever.

The stopping point here is that I finally got the animated logo section working.

The big text is made of lines of GTIA 16-grey scale graphics.  The lines are 3 scan lines tall instead of the usual 1 scan line.  (3 scan lines was chosen instead of 4, because 3 scan line GTIA pixels are closer to square on NTSC than 4 scan line pixels.)

GTIA modes are usually seen as lines 1 scan line tall.  Here I stretched them into 3 scan lines tall using ANTIC's vertical fine scroll hack.  Only five lines of pixel data are needed to show 18 scan lines of blocky GTIA pixels.  The Display List has only one LMS to reference the entire image.

Naturally, all of this is supported by Display list interrupts to force the vertical scroll hack, and to turn on and off the GTIA color interpretation in this section of the Title screen.

The animated greyscale pixels is done by page flipping between the four separate images which is performed by updating only an LMS pointer in the Display List.

A color mask travels across the letters from left to right, colorizing the grey pixels.  This is done using the missiles configured for Fifth Player.   A bitmap of the letters is written to the missile memory, and the horizontal position of the missiles is moved from left to right in sync with the graphics letters made of GTIA pixels. 

That's it for now.   You can see other parts of the display below this are messed up as little coding work has been done to support this. 

---

**15 Nov 2020 -- Improved Color Masking**

[![V01 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/01-WIP-ImprovedColorOverlay.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

For the life of me I could not figure out how to optimize the code for managing the VSCROL hack to build 3-scan-line mode F lines.  I tried various ways of breaking the changes up into separate Display List Interrupts, but everything turned out badly.  Best case was a couple lines working, and then the next line was 14 scan lines tall.   I tried following several methods in online tutorials and they did not help.  So, the big logo is managed with one DLI running the entire 18 scan lines, plus some.

The color masking was not working properly.  In the first screen shot it looks correct, but in the actual running version the colors are barely visible on screen.  It turns out a stupid programming trick was changing the colors so rapidly that they were only partly present on screen.

---

**16 Nov 2020 -- Credit Scrolling**

[![V02 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/02-WIP-CoarseScrollCredits.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

Finished the VBI code supporting fine scrolling the two lines of author credits.  Amazingly it appears to be working correctly the first time I assembled it.  It moves the text, pauses, then moves the text in the other direction.

The real fine scrolling need a Display List Interrupt added to set the HSCROL value for each scrolling line.   That will be for another day.  And, as long as I'm in there in the Display List interrupt code, I may as well make pretty gradient colors on the text.

(I accidentally restored the previous verion of the character set.  You can see the zero (0) character doesn't look right. The way the character is designed it will not look right on real hardware using a CRT monitor which is my baseline for acceptable appearance.   Also, the scores use alternate versions of the numbers, so that they look properly white on NTSC, and not pink and green.

---

**DD MMM 2020 -- TO-DO**

[![V03 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/03-WIP-TO-DO.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

WIP

---
