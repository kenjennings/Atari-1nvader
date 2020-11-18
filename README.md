# Atari-1nvader
WORK IN PROGRESS - Atari port (parody) of C64 1nvader

---

Prior to November there have been several months of occasional hacking around.  A lot of it is figuring out the data used for graphics in the original C64 program and figuring out how to deal with it on the Atari.  For a long while the code was in an unassemble-able state as I worked out how the Atari graphics would function and typing in all those sorts of details.   Also, a lot of why it had been un-assemble-able is that big parts are borrowed structure from the previous project (Pet-Frogger).  If you look at the source you'll see miles of code that is just in comments, and about as much code that has no purpose for the program. Eventually, this will all be cleaned up.

I usually have a number of real life things to do.  On some days maybe I only have an hour or so and sometimes less to look at the coding.  Therefore I need highly regimented and modular thinking about the source, so I can productively work on little parts at one time.  Designing modularity as states and making this structure work took time too.  

Finally, after much hacking around it reached the point of assembling and presenting the basic Title screen.  Now I can work on the visibly functiong parts incrementally, starting with the eye candy features for the Title screen.

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

Finished the VBI code supporting fine scrolling the two lines of author credits.  The actual fine scrolling isn't implemented yet as this needs another DLI to do that work.  However, all the work done in the Vertical Blank Interrutpt appears to be working correctly.  It coarse scrolls the text, pauses, then moves the text in the other direction.

The real fine scrolling on the display needs a Display List Interrupt added to set the HSCROL value for each scrolling line.  That will be for another day. And, as long as I'm in there in the Display List interrupt code, I may as well make pretty gradient colors on the text.

Note that the font shown here for the scores is not the font that will be used.  In the screen shot examples above you see that the font appears legible, but this is only because these screen shots were taken from an emulator which achieves a very limited impersonation of a real CRT display.   On actual hardware using an NTSC CRT display the font is mostly illegible, because single-pixel-wide vertical lines are smaller than a color clock and so appear as a color artifact.  The next version screen shot will show a redesign to correct this.

You can see the zero (0) character in the score doesn't look right. The character is designed with a single-width dot in the center of two vertical lines, also single-width lines.  The Atari800 emulator is at least smart enough to realize these pixels will blend together on screen.  It will not look right on real hardware. This will also be fixed soon.

---

**17 Nov 2020 -- Fine Scrolling Credits and Docs**

[![V03 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/03-0-WIP-FineScrollCredits.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The fine scrolling is working for the author credits, and for the documentation lines.   Each line of text also has its own color gradient/banding.  The creadit lines do double duty to advertise two authors.  The DLI for these lines are changing the color values for two registers.   This is more evident when the lines are partially scrolled between both author's credits.

The font problem for the scores has been addressed.  There are now two versions of number characters in the font.   The version with single-pixel-wide vertical lines is acceptable for the Mode 6 text on screen.   The alternate numbers are designed using two-pixel-wide vertical lines and will be utilized wherever Mode 2 text occurs (the scores at the top and the status at the bottom.  

---

**DD MMM 2020 -- TO-DO**

[![V04 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/03-WIP-TO-DO.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

WIP

