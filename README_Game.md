# Atari-1nvader
WORK IN PROGRESS - Atari port (parody) of C64 1nvader

---

**Game Screen Development**

---

**27 Dec 2020 -- Game Screen Startup**

[![V09 WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/09-WIP-GameScreen.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The Game Screen fires up after the countdown.   The transition from Title screen to Game screen is instant and seamless -- no redraw or obvious flicker.  (Because nothing is being redrawn.  Just a few pointers to screen memory.)    

The Player does not move yet.

The panorama of distant mountains continues its motion since it is serviced by the exact same Display List segment, Display List Interrupts, and VBI service code.

The random flashing stars are not yet being serviced for the animation, but the Display List Interrupt to apply color is running to help work out the alignment.

---

**30 Dec 2020 -- It's Full Of Stars...**

[![V10_WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/10-WIP-GameScreenPlusStars.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

The random flashing stars are functioning on the game screen.   Note that the picture is actually cheating and presents stars merged from two different screen grabs.  There are only 4 stars visible at any time, but since they flash so quickly it appears there are more visible.

There is only one line of star data. The 16 lines of stars all refer to the same screen data, so this section of the screen showing the stars takes roughly 100 bytes including all the display list instructions.   

Positioning the star is done by horizontally scrolling the line to a random position.  Fine scrolling is also used, so the stars can be horizontally positioned per pixel/color clock as if the stars are drawn in a pixel-graphics mode.  

The Vertical blank interrupt manages choosing random star locations and setting the stars positions, and running the color fading transitions for each star.  Each star is assigned a random base color.

Each line of stars is serviced by a Display List Interrupt that provides the horizontal fine scrolling control per line and applies the colors to the top/bottom of the star separately from the middle of the star.

---

**DD MMM 2020 -- TO-DO**

[![V11_WIP](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/11-WIP-TO-DO.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)

WIP

---

[ Go Back To MAIN Page ](https://github.com/kenjennings/Atari-1nvader/blob/master/README.md)
