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

The fine scrolling is working for the author credits, and for the documentation lines.   Each line of text also has its own color gradient/banding.  The credit lines do double duty to advertise two authors.  The DLI for these lines are changing the color values for two registers.   This is more evident when the lines are partially scrolled between both author's credits.

The font problem for the scores has been addressed.  There are now two versions of number characters in the font.   The version with single-pixel-wide vertical lines is acceptable for the Mode 6 text on screen.   The alternate numbers are designed using two-pixel-wide vertical lines and will be utilized wherever Mode 2 text occurs (the scores at the top and the status at the bottom.  

---

**18 Nov 2020 -- Title Screen Mothership**

[![V04 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/04-WIP-Mothership.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

Worked on the movement of the giant mothership on the Title screen.  Because the game does not yet accept user input, for demonstration purposes the mothership begins in the state to move up the screen as if a new game is starting. 

---

**21 Nov 2020 -- Mountains Majesty**

[![V05 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/05-WIP-Mountains.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The mountains are set up.  A DLI changes the colors from the top of mountains down to the bottom.

I made some minor tweaks to the image for the big mothership.

Fixed a problem with the long documentation.  It turned out the scrolling was broken and did not end at the correct enpoint, scrolling off into memory endlessly.

A DLI sets the colors for the static ground line at the bottom where the ships will be placed.  Also, a DLI sets the proper colors for the Mode 2 line of text at the bottom which shows the line statistics.

Further TO-DO: 

I will be changing the shape of the bumper. In the Mode 6 text the character is twice as wide as it appears on the C64 versions.  To give the Atari the same size of playfield for the guns I need to change the character image to fit into half the character.  This also means a special bumper character will be needed for the left and right sides of the line.

I will also change the characters in the ground line below the mountains to present rolling hills. 

---

**22 Nov 2020 -- We need guns.  Lots of guns.**

[![V06 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/06-WIP-LandAndGuns.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

Fixed DLI timings.  Now the display is stable on the Altirra emulator.

Adjusted the pairs of base colors for each row of the scrolling author credits and documentation to be more compatible/matching values.

Added the guns to the display in the ground view.  For demonstration purposes the guns travel across the screen and wrap around to the other side of the playfield.

Added color changes for the guns and the bumpers to the DLI.  It turned out there is not enough time available to transisiton the colors for five color registers per line (the background, ground, the two guns and the bumpers).  Reducing it to four was also not quite good enough -- the second gun had a visible color issue when it moved too far to the left side of the screen.  For the time being the DLI sets only the base color for the background one time, and runs a color gradient for the bumper and the two guns.   The ground color is actually the last value set from the mountains above.

The font was reworked to change the shape of the bumpers, and to make the ground characters look like rolling hills.  Initially, the ground looked great when the DLI was transitioning the colors for the background and the ground.  I may remove the gradient on the bumpers which then allows time for the ground gradient.   Another idea is to remove the background color entirely from the ground line, and change the ground characters to show pointed hill shapes instead.

---

**27 Nov 2020 -- Revised Land And Guns**

[![V07 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/07-WIP-NewLandAndGuns.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

After several experiments with the land row where the guns reside I decided a version of small triangular mountains imitating the larger ones scrolling above looked the best.  The mountains are the same shapes drawn in two different shades of brown to provide variety.

A little input was added for demonstration purposes.  The players' guns start in alternating positions - on the land line for the active guns, or the statistics line for the idle guns.  When the user presses joystick 1 button the Players move up or down to the opposite position.

---

**08 Dec 2020 -- Countdown**

[![V08 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/08-WIP-Countdown.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

Title screen complete.

The Countdown to game entry is working.   Press the appropriate joystick button and the Player's gun advances from the idle line to the active player line immediately above. The countdown begins, 3..., 2..., 1..., !GO!.

There is a color rainbow gradient running on the countdown text.  Some Display List tweaking was necessary to get this into a position that matched VCOUNT and looked centered between the top of the display and the big logo.

During the countdown the idle player pulses black to white as long as the Player remains indecisive.

After the countdown runs out the giant Mothership flies up and off the screen. 

If the idle player did not press their button during the countdown, then the player is removed  from the screen (slides down) during the big Mothership animation. 

---

**27 Dec 2020 -- Game Screen Startup**

[![V09 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/09-WIP-GameScreen.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The Game Screen fires up after the tranisition from the countdown.   The transition is instant and seamless -- no redraw or obvious flicker.  (Because nothing is being redrawn.  Just a few pointers to screen memory.)    

The Player does not move yet.

The panorama of distant mountains continues its motion as it is serviced by the exact same Display List segment, Display List Interrupts, and VBI service code.

The random flashing stars are not yet being serviced for the animation, but the Display List Interrupt to apply color is running to help work out the alignment.

---

**30 Dec 2020 -- It's Full Of Stars...**

[![V10_WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/10-WIP-GameScreenPlusStars.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The random flashing stars are functioning on the game screen.   Note that the picture is actually cheating and presents stars merged from two different screen grabs.  There are only 4 stars visible at any time, but since they flash so quickly it appears there are more visible.

There is only one line of star data. The 16 lines of stars all refer to the same screen data, so this section of the screen showing the stars takes roughly 100 bytes including all the display list instructions.   

Positioning the star is done by horizontally scrolling the line to a random position.  Fine scrolling is also used, so the stars can be positioned per pixel/color clock as if the stars are drawn in a pixel-graphics mode.  

Each star is assigned a random base color.   The Vertical blank interrupt manages positioning stars, and running the color fading transitions for each star.

Each line of stars is serviced by a Display List Interrupt to that provides the horizontal fine scrolling control per line and colors the top/bottom of the star separately from the middle of the star.

---

**DD MMM 2020 -- TO-DO**

[![V11_WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/11-WIP-TO-DO.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

WIP
