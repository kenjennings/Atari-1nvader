# Atari-1nvader
Atari 8-bit computer port (parody) of Darren Foulds' C64 1nvader game

Darren Foulds: https://github.com/darrenfoulds

1nvader For C64: https://github.com/darrenfoulds/1nvader-c64

---

**Development Progress**

BETA TEST BASELINE - - NO AUDIO YET.  

The game appears to run (mostly, almost) properly and stably through multiple iterations of its Title-Game-Game Over cycle.

Tested in Atari800 and Altirra emulators. Development/Test configuration is NTSC, Atari 800, 48K.  So, nothing special should be required and it should run on anything.

---

**ATARI PLAYTESTER PARADE**

- *VINYLLA* -- The first victim evaluating the barely running XEX before there was a coherent game.

- *PHILSAN* -- Suggested improving the color management to make PAL colors more consistent with NTSC.

- *LEVEL42* -- Suggested making the mothership multi-color.

---

**1 Aug 2021**

Philsan reported that PAL video mode shows junk at the top of the screen.   Looks like it is residual parts of the mothership.   Changed the erase code for the mothership.

Also, last "fixes" for the baseline to remove the guns between the end game and title screen ended up removing the mothership entirely from the title screen until the motherhip starts moving.  oops.

Added Playtesters to the credit text.

---

**9 Aug 2021**

Philsan reported that PAL colors didn't match NTSC colors.  I had put no thought into PAL at all.  So, I isolated all references to colors in the game to a contiguous block of variables, figured out PAL detection, and when the computer is operating in PAL video mode it overwrites the color references with alternate versions for PAL display.

Also, Philsan noticed that the giant mothership flies "under" the high score text.  This artifact is due to Players/Missiles always having lower priority than  ANTIC Mode 2 text (COLPF1) no matter what PRIOR says about priority.   To resolve this the score text is removed during the countdown sequence to start the game.  The scores are redrawn when the actual game starts. 

---

**16 Aug 2021**

After the problems resolved on 9 Aug, somehow the Game Over text display stopped working.  Weird that.

Did you know MADS will accept "rts" in the label position?   Enough said about that stupid programming trick.

---

**29 Aug 2021**

Playtester Level42 suggested making the mothership multi-color. 

Reworked the Player/Missile use to make a multi-color mothership on the title screen and in the game.  Also, the motherships have animated running lights and windows.

Due to the way Player/Missile multi-color players work, there is an unavoidable difference between the PAL and NTSC rendering of the motherships.   The overlay color produced by the two players' color is based on OR'ing the binary value of the two registers together -- NOT merging the aparent color displayed.   As a result, the PAL values used to make the two red colors for the mothership combine to result in nicely light-blue lights and windows.  In NTSC different values produce the reds, and the binary OR combining these values is still in the red area of the palette, so the lights are red.

Updated the Playtesters list accordingly, and while I was here, updated the Documentation scroller to have two gradient colors in the text.

---

**9 Sep 2021**

Revised the PAL v NTSC selection code.

Added generalized movement control based on PAL v NTSC for the players, lasers, and game mothership.  These should now run on PAL at the same apparent speed as NTSC.  The motion determination is read from tables and set by the VBI on every frame.   The changes to make this work in the main code were very little.   Instead of inc, dec, adding/subtracting fixed values the code uses the values determined by the VBI.

---

**12 Sep 2021**

Tentative fix to allow MiSTer FPGA (Atari on a chip) to display the title screen properly.

Eliminated the overly clever VSCROL hack to turn single scan-line mode F into three scan lines which are the basis for the chunky GTIA pixels for the 1NVADER logo.   Replaced it with just regular LMS instructions in the display list to repeat the data.   

Nothing too brilliant and time critical is going on at this part of the screen, so the VSCROL hack which saves ANTIC DMA time was just overkill for the display.

---

| **Title** |
| ------- |
| [![TITLE](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/21-BETA-Title.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README_Title.md "Title") | 

---

| **Game** | 
| ------- |
| [![GAME](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/22-BETA-Game.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README_Game.md "Game") |

---

| **GAME OVER** | 
| ------------- |
| [![GAMEOVER](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/18-BASELINE-GameOver.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README_GameOver.md "Game Over") |

---
