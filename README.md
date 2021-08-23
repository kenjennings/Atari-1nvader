# Atari-1nvader
Atari 8-bit computer port (parody) of Darren Foulds' C64 1nvader game

Darren Foulds: https://github.com/darrenfoulds

1nvader For C64: https://github.com/darrenfoulds/1nvader-c64

---

**Development Progress**

BETA TEST BASELINE - - NO AUDIO YET.  

The game appears to run properly and stably through multiple iterations of its Title-Game-Game Over cycle.

Tested in Atari800 and Altirra emulators. Development/Test configuration is NTSC, Atari 800, 48K.  So, nothing special should be required and it should run on anything.

---

**PLAYTESTERS ON PARADE**

- *VINYLLA* -- The first victim evaluating the barely running XEX before there was a coherent game.

- *PHILSAN* -- Suggested improving the color management to make PAL colors more consistent with NTSC.

---

**1 Aug 2021**

Philsan reported that PAL video mode shows junk at the top of the screen.   Looks like it is residual parts of the mothership.   Changed the erase code for the mothership.

Also, last "fixes" for the baseline to remove the guns between the end game and title screen ended up removing the mothership entirely from the title screen until the motherhip starts moving.  oops.

Added Playtesters to the credit text.

---

**9 Aug 2021**

Philsan reported that PAL colors didn't match NTSC colors.  I had put no thought into PAL at all.  So, I isolated all references to colors in the game to a contiguous block of variables, figured out PAL detection, and when the computer is operating in PAL video mode it overwrites the color references with alternate versions for PAL display.

Also, Philsan noticed that the giant mothership flies "under" the high score text.  This artifact is due to Players/Missiles always having lower priority than  ANTIC Mode 2 text (COLPF1) no matter what PRIOR says about priority.   To resolve this the scrore text is removed during the countdown sequence to start the game.  The scores are redrawn when the actual game starts. 

---

**16 Aug 2021**

After the problems resolved on 9 Aug, somehow the Game Over text display stopped working.  Weird that.

Did you know MADS will accept "rts" in the label position?   Enough said about that stupid programming trick.

---

| **Title** |
| ------- |
| [![TITLE](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/20-BASELINE-TitleTesters.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README_Title.md "Title") | 

| **Game** | 
| ------- |
| [![GAME](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/19-BASELINE-Game.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README_Game.md "Game") |

| **GAME OVER** | 
| ------------- |
| [![GAMEOVER](https://github.com/kenjennings/Atari-1nvader/raw/master/pics/18-BASELINE-GameOver.png)](https://github.com/kenjennings/Atari-1nvader/blob/master/README_GameOver.md "Game Over") |

---
