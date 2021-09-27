;*******************************************************************************
;*
;* C64 1NVADER - 2019 Darren Foulds
;*
;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*                                                                             
;*******************************************************************************

; ==========================================================================
; S O U R C E    P R O G R E S S    A N D    C H E C K - I N    N O T E S
; ==========================================================================
;
; Nov 15, 2020
; ============
; Initial file setup and repository upload to GitHub
; ==========================================================================
;
; Nov 17, 2020
; ============
; Credits and Documentation scrolling work
; ----------------------------------------
; The Title screen Author Credits and Documentation scrolling plus color
; gradients work now.
; ==========================================================================
;
; Nov 19, 2020
; ============
; Added mothership 
; ----------------
; But...   somehow when the mothership leaves the screen I broke 
; something about the  GTIA image, or the LMS that points to the image.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Fixed the glitch in the GTIA pixels 
; -----------------------------------
; Stupid programming trick.   
; When the code deletes the mothership from player memory the  index for 
; the loop was incorrectly Y instead of X.   
; At this point Y has the value 255, plus the forced offset from the base 
; of Player 3 memory results in the code slapping a 0 into the LMS address 
; for the GTIA pixels.  
; Derp.
; Putting X where it belongs fixed the stupid.
; ==========================================================================
;
; Nov 21, 2020
; ============
; Added mountains and fixed other things
; --------------------------------------
; The mountains on the bottom of the screen are set up.  Some minor 
; tweaks in various places.
; DLIs are  running for the mountains, the static land, and the color 
; change for the mode 2 status line at the bottom.
; I will change the way the bumpers are drawn, and further redefine the
; character set to show rolling hills on the bottom ground line where 
; the guns will be placed.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; WIP adding rolling hills in static land
; ---------------------------------------
; WIP - Working on redefining more characters to use as rolling hills 
; on the static land.
; Changed the text gradients to be less obnoxious and matching better 
; between Author/Computer, and better transition between the top and 
; bottom of the text.
; ==========================================================================
;
; Nov 22, 2020
; ============
; Fixing DLI timings and getting the guns on screen 
; -------------------------------------------------
; Display should be stable now on Altirra.
; Modified the DLIs to color the guns and bumpers.
; Changed the ground line to show rolling hills.  Sort of.
; ==========================================================================
;
; Dec 8, 2020
; ===========
; Partially working countdown
; ---------------------------
; What it says.  Partially working countdown.
; ==========================================================================
;
; Dec 12, 2020
; ============
; Working Title Screen and Countdown
; ----------------------------------
; All parts of the Title screen including player entry in the game, and 
; idle player removal are working.
; ==========================================================================
;
; Dec 14, 2020
; ============
; Tweaking the idle player 
; ------------------------
; It takes several frames for the idle player to move up to the game 
; play position.
; There was a condition where the Player who presses the button late could 
; have the gun motion still in progress when the Mothership animation starts 
; which would stop the gun animation. 
; So, the Idle Player input is separated from the Idle Player movement toward 
; the playing position to allow the animation part to continue being called 
; during the Mothership animation.
; ==========================================================================
;
; Dec 27, 2020
; ============
; WIP Progress getting the Game screen displayed 
; ----------------------------------------------
; The Title screen transitions seamlessly to the game screen without obvious 
; flicker.  The game screen fires up.  
; Nothing is really animated yet, except the moving mountains which are 
; supplied by the same Display List segment, Display List Interrupts, and 
; maintenance code as from the Title screen.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; WIP -- Starting work on Game Screen 
; -----------------------------------
; There is a game screen executing and it isn't resulting in an immediate 
; crash.
; The VBI for this is calling the Flashing stars loop (but nothing is yet
; appearing.... some bug, probably just lack of DLI running.)
; The VBI also calls the Player/Missile placements, and the ground scrolling 
; code.  The ground code is clearly running, so things are looping where 
; expected.
; The land shifts vertically a few scan lines between the Title screen and 
; the Game screen, so there is an anomaly in the line counts between the 
; two display lists.  They should be identical placements.
; ==========================================================================
;
; Dec 29, 2020
; ============
; Game screen flashing start are somewhat working. 
; ------------------------------------------------
; Almost, but not quite altogether working stars on the game screen.
; Still fixing this.   
; Some star rows are using colors swapped between the lighter and the 
; darker flashing light color.   Weirdly.... Trying to squeak out a good 
; reason for this.
; ==========================================================================
;
; Dec 30, 2020
; ============
; Fixed the flashing stars.
; -------------------------
; The random flashing stars now appear to be functioning.
; ==========================================================================
;
; Apr 21, 2021
; ============
; Animated Alien Antagonist Added
; -------------------------------
; Demo code is added to do a simple imitation of the mothership movement 
; for the game.
; The code starts the mothership from the top of the screen, animates the 
; movement row by row until it gets to the bottom row.
; When the mothership reaches the bottom row the limiter prevent further 
; movement down, but the bounce logic keeps it moving back and forth.... 
; forever.
;
; A difference from the original game is that there is a transition 
; animation  that slides the  mothership down to the next row when it  
; reaches the horizontal limit.
; 
; Speed and score display are not functioning. (Neither are the guns, yet)
; ==========================================================================
;
; Apr 28, 2021
; ============
; Corrected code for Main v VBI roles
; -----------------------------------
; No actual changes in behavior here.
; Moved the Mothership demo movement code into the main game routine where 
; it belongs, so the VBI is only updating the screen graphics.
; ==========================================================================
;
; May 15, 2021
; ============
; Mostly broke it again 
; ---------------------
; Upgraded linux and upgraded eclipse and then had to rebuild atari800 
; emulator and now having some troubles in the emulator.   It's vaguely 
; possible something in the emulator timing is off.   
; The title display is messed up again after updating code in main game.
; Probably typo'd something somewhere.  Maybe a result of moving some 
; things out of page 0.  Going to go back to working on fixing display.
; ==========================================================================
;
; May 21, 2021
; ============
; Debugging the Disaster 
; ----------------------
; atari800 on linux likes it so far....  altirra on windows blows chunks 
; on it after a few seconds on the game screen.   something wrong with 
; DLI, VBI, or main code....  has to be a timing thing....
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Adjusted Gun Movement Speed.
; ----------------------------
; Gun movement should be the correct speed now.  Hoping...
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; In Progress -- Making the Guns Move.
; ------------------------------------
;  Whatever was wrong with rendering the player 0 gun seems to be fixed.   
; I think just a goofy init value caused that.  
; Both guns move when present.  Collision/bounce from the bumpers works 
; when only one gun is present.  If only one gun is present, then the 
; gun will bounce back and forth between bumpers, perpetually.   
; If both guns are present, then the priority logic for anticipating gun 
; collisions does not yet allow the guns to move toward each other as the 
; collision part is only partly implemented.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Gun Motion in progress
; ----------------------
; Working on expanding the player redraw behavior.   Accidentally broke 
; some behaviors of gun 1 and some other behaviorsof gun 2.  OOPS.   
; The game screen and flashing start appear to run OK for atari800 
; emulator.   Your mileage may vary with Altirra -- it could be crashy 
; there due to dodgy DLI timing.
; ==========================================================================
;
; May 22, 2021
; ============
; Making a Mess 
; -------------
; Was working on why the game screen crashes on Altirra.   Succeeded in 
; making a bigger mess.   Undid most of the mess.  The countdown timer 
; is temporarily sped up to make testing less tedious.
; ==========================================================================
;
; May 23, 2021
; ============
; More WIP
; --------
; WIP testing for Altirra
; More WIP on game screen for Altirra
; Yet more Wip testing Altirra
; WIP changing game screen DLI timing
; ==========================================================================
;
; May 24, 2021
; ============
; Clear Status Text Line
; ----------------------
; Clear the status text line when the title is displayed.   Setting the 
; text to black was not sufficient.   Since the text characters are 
; ANTIC Mode 2, they show through the Player objects for the idle guns.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Resolved Altirra Difference 
; ---------------------------
; Timing problems with DLI should be resolved in Altirra.
; This was due to the last DLI for stars occasionally overlapping the 
; next DLI.  
; Removing one line of stars and replacing with a blank instruction 
; solved that.
;
; Status text was displaying on top of the idle guns on the title 
; screen when tested on Windows Altirra, but do not appear in Linux 
; atari800.   On real hardware the text does appear, so the problem is 
; in atari800, and the solution is to REMOVE the statistics text from 
; the display when not needed instead of just setting it black.   
; (Thanks to the author of Altirra for explaining this.)  The  
; correction of the text display  is still on the TODO list.
;
; The code condition in this check-in should be the proper baseline 
; for continuing the game logic.   The  Title and game screens 
; should display  fine without DLI disaster on atari800, Altirra, 
; and real hardware.  
; (The Count down timer is still accelerated to make testing 
; more convenient.)
; ==========================================================================
;
; May 26, 2021
; ============
; Gun Movement Working
; --------------------
; Gun movement, whether one or two guns present, is working.     
; When one gun is present it bounces from bumper to bumper.   
; When two guns, they bounce off the bumpers and off each other.
; Guns start movement in a random direction at the start of each game.
; ==========================================================================
;
; Jun 14, 2021
; ============
; WIP - Still hacking up missile firing.
; --------------------------------------
; WIP -- not working right.  (still)  (again)   
; At the moment this is suffering from premature optimization.
; Tweaked various code that was redundant, and now the guns don't 
; work properly.   Oh, well, come back tomorrow.
; ==========================================================================
;
; Jun 15, 2021
; ============
; Guns Moving Again 
; -----------------
; After a round of optimization to share code between player 1 and 2, 
; got the gun movement back to working order.
; ==========================================================================
;
; Jun 21, 2021
; ============
; Working on Players Shooting
; ---------------------------
; Adding code to support players' guns shooting lasers.   (Nothing 
; visibly happens yet.  Still need to work int the actual code to display.)
; ==========================================================================
;
; Jun 22, 2021
; ============
; Still Working on Shooting.
; --------------------------
; Still WIP.   Yes, there is no laser visible, but the input for 
; shooting is being accepted.
; ==========================================================================
;
; Jun 23, 2021
; ============
; Debugging Laser Glitch in Atari800 
; ----------------------------------
; Cleaned up code to help figure out how HPOSP0/HPOSP1 is sometimes 
; appearing in the left/right oversan area for one frame.   
; Seems to be only two places that touch this -- the VBI sets laser HPOS, 
; and the DLI sets HPOS for the guns.   
; Aside from this, all DLI appear to function properly.
; Tested timing of VBI, and Main line, and very little is happening -- 
; Main actually finishes everything even before the top of the screen 
; starts display, so this is not due to conflict between main and the DLI.
; It may be specific to Atari800.   The behavior seems to go away after 
; a minute or so... why....?   Need to check in Altirra.
; Maybe something incomplete that gets filled in later as the game 
; loops???  Doubtful.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Bang Bang Shoot Shoot
; ---------------------
; Lasers now function (but not collision detection).   
; Some endurance testing in atari800 emulator with both guns against a 
; bumper...  It  seems to function correctly regarding shooting and 
; direction changes. 
; Possible glitchiness remains.   Maybe it is an artifact of atari800 
; emulator.  Need to test in Altirra to figure out if it is real.  
; (When the game starts, sometimes it appears that a laser may flash 
; for a frame  in the overscan area on the left side of the screen.   
; After a while the occasional laser image no longer appears.   
; strangeness.)
; ==========================================================================
;
; Jun 25, 2021
; ============
; Still Debugging Lasers 
; ----------------------
; debugging lasers
; And  optimised something in player movement.
; ==========================================================================
;
; Jun 26, 2021
; ============
; More cleanup 
; ------------
; completely separated all the C64 residual code that I recognize.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Success! ? ? ? 
; --------------
; Per debugging the weird laser anomaly, a review of the label listing 
; showed a number of page zero variables had been pushed up into 
; Page 1/stack area.
; Removed a number of unused variables, and other things defined for 
; the C64.
; Commented out almost all the C64 code in the main file. 
; Build size is now about 2K smaller.
; After a couple simple tests, it appears that the laser firing is 
; stable now.
; ==========================================================================
;
; Jun 28, 2021
; ============
; Debugged why player 2 was not working.
; --------------------------------------
; Duh.   should leave it at that.
;
; When Pmg_DeterminePlayerDraw was optimized to used the X index for 
; the players I forgot to change the inc at the end for the player redraw.
;
; All the pieces-parts  that are supposed to be working appears to be 
; working properly in this version.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; More Refinements. More bugs.
; ----------------------------
; Still looks like the memory cleanup is what fixed the laser shooting 
; visual glitch.
; Added debounce logic to the laser shooting, so the player must release 
; the fire button before shooting again.   The player can't just hold the 
; button down and machine gun the lower rows.
; Added animated window to the game screen's mothership. -- should do 
; the same for the title screen's giant mothership ...  later....  
; at some point.
; The randomized colors for the laser looked nicely psychadelic, but 
; it blends into the randomized stars' colors.   Revised this with a 
; strobing color shot that stands out apart from the stars.
;
; Stupid programming tricks must have broken something else.... 
; Somewhere along the line I am losing track of Player 1/Player2, so that 
; Player 2 is not advancing to the play line during the Title screen, but 
; it is shooting during the game from it's stuck position.
; ==========================================================================
;
; Jun 29, 2021
; ============
; Finally Working Baseline - Guns, Laser, Input 
; ---------------------------------------------
; Finally have Guns, Lasers, Fire button input, Title screen Behavior 
; and Game screen guns/lasers all moving properly and (hopefully ) now 
; unbuggy.
; A couple rounds of premature optimization reduced  assembled size 
; to the low 8,500s.
;
; Next TO-DO is the collision detection, explosion, then the scoring.
; ==========================================================================
;
; Jun 30, 2021
; ============
; Working on explosion 
; --------------------
; Added the DrawExplosion routine.
; Cleaned up unused code, useless blocks of comments.
; Organized variables and restructured the main file .
; ==========================================================================
;
; Jul 1, 2021
; ===========
; Lasers and Explosion mechanics are working.
; -------------------------------------------
; Updated laser logic, so they don't leave residue behind when restarting.
; Updated explosion logic, made the image less busy, lengthened the 
; fade out.
; The mothership now falls back rows when shot and the direction is 
; randomized.
; However, the demo code still doesn't like the forced change 
; in mothership Y position and behaves weirdly.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Partial working explosion. 
; --------------------------
; Collision detection working.   Explosion appears at mothership position.
; Did some violence to the laser code, so that the visual is messed up.   
; I know what I did wrong.  No time to fix it up at the moment.
; The mothership position reset at the time of explosion is "working" .  
; The demo code to keep the mothership moving disagrees with the position 
; change.  This will be fixed with the row, statistics, and scoring logic.
; ==========================================================================
;
; Jul 3, 2021
; ===========
; WIP - Do not build (Seriously)
; ------------------------------
; In the middle of vandalizing the mothership movement code to do the 
; proper game behaviors.  Partly functioning.
; ==========================================================================
;
; Jul 4, 2021
; ===========
; WIP - Fixing Mothership in progress 
; -----------------------------------
; Replacing the demo code with proper game.  
; Mothership start working.   Row to row progression working.
; Still looking at why the reset when it explodes ends up locking the 
; mothership to the side of the screen.
; ==========================================================================
;
; Jul 5, 2021
; ===========
; WIP -- code for working on statistics line
; ------------------------------------------
; More code.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Fixed again. New Baseline 
; -------------------------
; Finally fixed mothership behavior.
; Mothership motion at game start and line by line progression is  working 
; correctly (and positioned correctly).
; Good baseline here to start adding more game behavior.
; Next up should be status line and scoring.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Almost working mothership
; -------------------------
; Found a missing transfer from New Y to Current Y for the mothership, 
; which seemed to be what locked up the row to row progression.
; Mothership mostly behaving much better.
; Current issue is that on entry to the first line at the start of game 
; the mothership is two lines high.  Though I have currently hardcoded the 
; correct starting positions for both in the game init section, something 
; is interfering with the progression to the first line.
; ==========================================================================
;
; Jul 6, 2021
; ===========
; WIP - Add Player Score
; ----------------------
; Added the routine to add the mothership points to the player(s) score.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; WIP - working on text display
; -----------------------------
; Adding support for controlling scores, row count, hits, and the visual 
; display of these values.
; ==========================================================================
;
; Jul 8, 2021
; ===========
; WIP - Scoring and stats 
; -----------------------
; Some kind of scoring is happening.  
; Also, looks like high score is maintained.
; Line counter seems to work.
; Hit counter is not working.  (Not yet hooked up to the explosion code).
; Points for Mothership is dodgy.  no doubt some royal stupidity there.
; ==========================================================================
;
; Jul 9, 2021
; ===========
; WIP scores and status
; ---------------------
; still working on things.
; ==========================================================================
;
; Jul 10, 2021
; ============
; WIP - Scores and stats almost working
; -------------------------------------
; Scores are working.
; Hi score working.
; Stats row counter working.
; Stats line point display (per current row) is working.
;
; TO DO
; Hit counter
; Mothership speed changes.
; Row 22 special behaviors when mothership gets to the last row.
; ==========================================================================
;
; Jul 11, 2021
; ============
; Tweaking Scores and displays
; ----------------------------
; Only the Active player's score appears during the game.
; When the stats line is turned off it is filled with spaces to make sure 
; black character do not show through the idle players.
; Refactored how the line counter digits is generated eliminating one of 
; the 23 byte tables that served the row/value lookup.
; Studied the speed control in the original program and documented the 
; Atari strategy to implement similar results.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Hit Counter Working
; -------------------
; Duh.   Stupid Programmer Tricks.     Got the hit counter working.
;
; Next TO-DO is modifying mothership speed per hit counter value.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Scoring works now 
; -----------------
; Looks like the math is finally working on the scoring.
; The line counter and points for the mothership in the stats are both 
; good, too.
;
; To-Do -- the hit counter is misbehaving.
; ==========================================================================
;
; Jul 12, 2021
; ============
; WIP -- working on row 22
; ------------------------
; Speed progression appears to be correct.  On to working on the last 
; line (22) where the mothership pushes the ships off the screen....
; Started minor tweaks supporting line 22.  Turn off the stats text 
; line when the mothership reaches row 22, and conveniently, the $0 
; value for color can be used as a flag for exception logic rather 
; than needing to compare the row to #22 all the time.
; Happened to notice the color for the mountains were not the right 
; number of scan lines  per color:  3, 5, 3, 5, ... instead of 
; 4, 4, 4,... the DLI was short one WSYNC.
; Happened to also find that the Mothership  Y coordinate location for 
; the first row was set to 38 instead of 36.   ... I think this was 
; accidental residue from debugging when the code was zipping the 
; mothership along the vertical border of the screen instead of 
; entering the line.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Mothership speed progression looks like it works.
; -------------------------------------------------
; Looks like the speed increases for the mothership are working.
; "Looks Like", because now with the speedup  I haven't been able to 
; play it for testing up to 80 hits so far.   
; I'll have to test with a different movement values, and/or debug to 
; the screen to be sure this is indexing properly, and the right speeds 
; are being chosen/added from the speed control table.
; ==========================================================================
;
; Jul 13, 2021
; ============
; WIP - Working on Row 22 
; -----------------------
; added alternate min/max X movement  limits  for mothership based on 
; regular row v the last row. 
; the current  mothership movememt processing will now move the 
; mothership off the screen on the bottom row.
; ==========================================================================
;
; Jul 14, 2021
; ============
; Mothership pushes guns
; ----------------------
; The Mothership on the last row pushes the players off the screen.  
; Either left or right, whatever direction the mothership is going when 
; it enters the bottom row.
;
; Game over mechanics are not done, do there is perpetual rebounding on 
; the bottom row.
; ==========================================================================
;
; Jul 15, 2021
; ============
; WIP -- Making game over screen
; ------------------------------
; Set up display list for game ove.  (it isn't being used yet.)
; ==========================================================================
;
; Jul 17, 2021
; ============
; WIP - working on game over screen
; ---------------------------------
; Nothing running yet.  
; Minor updating  and comment corrections in the display lists.
; ==========================================================================
;
; Jul 28, 2021
; ============
; WIP - Game Over 
; ---------------
; Random garbage accomplished.
; At least it isn't crashing (at the moment).
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; WIP - Game Over Screen
; ----------------------
; Derp.   Stupid programmer trick.   The transition from Game to 
; Game Over screen is now glitch-free.  Animation work may begin.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; WIP - Game Over Screen 
; ----------------------
; Game Over screen in progress.
; The screen is displayed.   
; The colors for the text animation are displayed on temporary characters 
; without animation.
; There is a glitch in the transition from Game screen to Game Over screen.
; The DLI is off for the scrolling landscape for one frame.
; ==========================================================================
;
; Jul 29, 2021
; ============
; WIP - Animated Game Over
; ------------------------
; First display that ends in all the characters present.   
; Though..... they did not animate as intended.   They did not all end in 
; the correct character color.   But, they're on screen.
; ==========================================================================
;
; Jul 31, 2021
; ============
; First Beta Version
; ------------------
; For full testing experience I returned the countdown timer to 
; the original speed.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; BASELINE - Full game cycle functions 
; ------------------------------------
; Game Over hackery is done enough to call this stable.
; After a little work, the game cycle appears to be working and stable 
; enough...   
; Title/Game/Game over/Title/Game/Game over/etc.
; ==========================================================================
;
; Aug 1, 2021
; ===========
; Fixing residual mothership
; --------------------------
; PHILSAN pointed out on PAL there was stuff at the top of the screen.  
; Looks like it is residual mothership parts.
; Removed some optimization from the mothership delete code,  so that 
; should help.
; ALSO, the last iteration of laziness concerning  erasing the guns 
; between the end game and start of title screen  ended up removing the 
; big mothership entirely from the title screen until it started moving.
; ==========================================================================
;
; Aug 3, 2021
; ===========
; PAL is making me nuts 
; ---------------------
; why does it seem like the mothership  color is not changing?
; ==========================================================================
;
; Aug 4, 2021
; ===========
; Still working out PAL colors 
; ----------------------------
; Either I must be reeealy good at interpreting colors, or PAL mode is 
; not updating the screen colors as PAL.
; Temporarily added a tag on the screen next to the high score to let 
; me know the system does recognize it is operating in PAL mode.
; ==========================================================================
;
; Aug 9, 2021
; ===========
; Erase Scores During Countdown 
; -----------------------------
; Playtesters commented that the giant mothership flies behind the 
; scores/high score text.  This is inevitable where Player/Missiles overlap 
; ANTIC Mode 2 COLPF1 text pixels. No changes to priority (PRIOR) can fix 
; this). Therefore, when the countdown starts the scores are removed from 
; the screen to eliminate this inconsistent overlap (underlap(?))  
; The scores are redrawn when the countdown is over and the regular 
; game starts.
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Better PAL colors 
; -----------------
; Decent enough PAL colors that it should now match NTSC (more or less) 
; (plus or minus) (here or there).
; Second joystick is not available at the moment, so I'm not sure about 
; the Player 2 colors at the moment.
; ==========================================================================
;
; Aug 16, 2021
; ============
; Game Over text working again
; ----------------------------
; Stupid programming trick accidentally broke the Game Over text display.
; Did you know that MADS will accept "rts" in the label position?  
; Enough said.
; ==========================================================================
;
; Aug 22, 2021
; ============
; Updating playtesters.
; ---------------------
; Added names to the playtesters in the credits.
; ==========================================================================
;
; Aug 29, 2021
; ============
; Multi-color Mothership 
; ----------------------
; Reworked Player/Missile use to implement multi-color mothership on 
; the title screen and in the game.
; Further updates on PAL colorc v NTSC.
; ==========================================================================
;
; Aug 30, 2021
; ============
; Maybe Fixed Residual Laser Issue
; --------------------------------
; Philsan has a screen shot where a laser is stuck, frozen on the game 
; over screen.
; I had thought the lasers would have all naturally departed the game 
; screen before the Game Over event kicked in.   Guess it isn't so.
; Modified the code so that just before setting the Game Over event it 
; forcibly zeros the lasers.
; ==========================================================================
;
; Sep 9, 2021
; ===========
; PAL Updates
; -----------
; Revised PAL/NTSC selection code.
; Added movement scaling  to make PAL run the same apparent speed as NTSC.
; I hope.
; ==========================================================================
;
; Sep 12, 2021
; ============
; Trying to Improve MistFPGA Compatibility
; ----------------------------------------
; Replaced the VSCROL hack with regular LMS instructions in the 
; display list.
; ==========================================================================
;
; Sep 24, 2021
; ============
; New Font and other WIP 
; ----------------------
; Updates are made to the font to allow for legible Mode 2 text. This 
; includes rework of the characters displaying score.
; Added DLI making gradient on the score line.   Similar gradient will 
; (soon) appear for the status line.
; WIP:
; Added text line for the subtext  under the title graphics.
; Added text  line for displaying OPTIONS and a line for descriptions  
; to the title screen.
; Tweaked display list around to accommodate the extra lines.   This has 
; resulted in some damage to the displays and the Game screen and Game 
; over screens have dropped a scan line or two lower.   OOPS.   
; The display issue is on the short list of fixes.
; ==========================================================================
;
; Sep 27, 2021
; ============
; Beautification Continues
; ------------------------
; New tag line under the title. This will have text that fades in and out.
; New Options line, and Options documentation line.  The Options 
; line has color tables for gradients on COLPF0, COLPF1, COLPF2.
; Score line and Options Documentations use the same code for creating 
; a gradient. 
; Colors have been changed for the scrolling documentation line to 
; provide more contrast to the two different colors. 
; Several DLIs added and others reworked on the title screen.
; STILL TO-DO is to fix the scan line misalignment on the game 
; screen and game over screens. 
; ==========================================================================



; ==========================================================================
; Atari System Includes (MADS assembler versions)
	icl "ANTIC.asm"  ; Display List registers
	icl "GTIA.asm"   ; Color Registers.
	icl "POKEY.asm"  ; Beep Bop Boop.
	icl "PIA.asm"    ; Controllers
	icl "OS.asm"     ; Interrupt definitions.
	icl "DOS.asm"    ; LOMEM, load file start, and run addresses.

	icl "macros.asm" ; Macros (No code/data declared)
; --------------------------------------------------------------------------

; ==========================================================================
; Other general variables specific to the game.

	icl "ata_1nv_page0.asm" ; Page 0 variable declarations  (The file will set ORG) 

	ORG LOMEM_DOS           ; First usable memory after DOS (2.0s)
;	ORG LOMEM_DOS_DUP       ; Use this if LOMEM_DOS won't work.  or just use $5000 or $6000

	icl "ata_1nv_vars.asm"  ; Other variables' declarations
; --------------------------------------------------------------------------

; ==========================================================================
; Include all the code and graphics data parts . . .

	icl "ata_1nv_gfx.asm"       ; Data for Display Lists and Screen Memory (2K)

	icl "ata_1nv_gfx_color.asm" ; Data for NTSC/PAL color values

	icl "ata_1nv_cset.asm"      ; Data for custom character set (1K space)

	icl "ata_1nv_pmg.asm"       ; Data for Player/Missile graphics (and reserve the 2K bitmap).


	icl "ata_1nv_gfx_code.asm"  ; Routines for manipulating screen graphics.

	icl "ata_1nv_pmg_code.asm"  ; Routines for Player/Missile graphics animation.


	icl "ata_1nv_int.asm"       ; Code for I/O, Display List Interrupts, and Vertical Blank Interrupt.

	icl "ata_1nv_audio.asm"     ; The world's lamest sound sequencer.

	icl "ata_1nv_support.asm"   ; The bulk of the game logic code.

	icl "ata_1nv_game.asm"      ; Code for game event loop.

; --------------------------------------------------------------------------


; ==========================================================================
; The Game Entry Point where AtariDOS calls for startup.
; 
; And the perpetual loop calling the game's event dispatch routine.
; The code needs this routine as a starting place, so that the 
; routines called from the subroutine table have a place to return
; to.  Otherwise the RTS from those routines would be at the 
; top level and exit the game.
; --------------------------------------------------------------------------

GameStart

	jsr GameLoop  ; in game.asm

	jmp GameStart ; Do While More Electricity


; ==========================================================================
; Inform DOS of the program's Auto-Run address...
; GameStart is in the "Game.asm' file.
; --------------------------------------------------------------------------

	mDiskDPoke DOS_RUN_ADDR,GameStart
 
	END

