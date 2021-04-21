# Atari-1nvader
WORK IN PROGRESS - Atari port (parody) of C64 1nvader

---

**Game Screen Development**

---

**27 Dec 2020 -- Game Screen Startup**

[![V09 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/09-WIP-GameScreen.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The Game Screen fires up after the countdown.   The transition from Title screen to Game screen is instant and seamless -- no redraw or obvious flicker.  (Because very little is being redrawn.  There are just a few pointers to screen memory being updated in the Display List.)    

The Player does not move yet.

The panorama of distant mountains continues its motion since it is serviced by the exact same Display List segment, Display List Interrupts, and VBI service code.

The random flashing stars are not yet being serviced for the animation, but the Display List Interrupt to apply color is running to help work out the alignment.

---

**30 Dec 2020 -- It's Full Of Stars...**

[![V10_WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/10-WIP-GameScreenPlusStars.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The random flashing stars are functioning on the game screen.   Note that the screen snapshot above is a cheat and presents stars merged from two different screen grabs.  There are only 4 stars visible at any time, but since they flash so quickly it appears there are more visible.

There is only one line of star data. The 16 lines of stars all refer to the same screen data, so this section of the screen showing the stars takes roughly 100 bytes including all the display list instructions.   

Positioning the star is done by horizontally scrolling the line to a random position.  Fine scrolling is also used, so the stars can be horizontally positioned per pixel/color clock as if the stars are drawn in a pixel-graphics mode.  

The Vertical blank interrupt manages choosing random star locations and setting the stars positions, and running the color fading transitions for each star.  Each star is assigned a random base color.

Each line of stars is serviced by a Display List Interrupt that provides the horizontal fine scrolling control per line and applies the colors to the top/middle/bottom of the star.

---

**21 April 2021 -- Alien Antagonist Animation Added**

[![V11_WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/11-WIP-GameWithMothership.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

Demo code is added to do simple imitation of the mothership movement for the game.

The demo code starts the mothership from the top of the screen and animates the movement row by row until it gets to the bottom row.

When the mothership reaches the bottom row the limiting code prevents further movement down, but the bounce logic keeps it moving back and forth.... forever.

A difference from the original game is that there is a transition animation that slides the mothership down to the next row when it reaches the horizontal limit.
 
Mothership speed and score display are not yet functioning.  (Neither are the gun movements.)

---

**DD MMM 2021 -- TO-DO**

[![V12_WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/12-WIP-TO-DO.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

WIP

---

[ Go Back To MAIN Page ](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)
