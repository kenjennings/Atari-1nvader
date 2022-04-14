;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; MENUTASTIC
; ==========================================================================
; 
; Code and data operating Menus used for choosing configuration.
;
; OPTION key cycles through the title for each menu.
;
; SELECT key cycles through the items on the menu.
;
; START key chooses the menu item. 
;
; Typical use is a menu of mutual exclusion values on one configuration 
; variable with different values for each item on the menu. 
;
; --------------------------------------------------------------------------


; ==========================================================================
; MENUTASTIC - TITLE SCREEN OPTIONS MANAGEMENT VARIABLES . . .
; ==========================================================================

gOSS_ScrollState   .byte 0 ; Status of scrolling: 1=scrolling. 0=not scrolling. -1=scroll just stopped. 

gOSS_Mode          .byte 0 ; 0=Off  -1=option menu  +1=is select menu.

OSS_TIMER_EXTEND = 2      ; restart value for gOSS_TimeExt
gOSS_TimeExt       .byte 0 ; 255 jiffies is not enough to read menus and debate
gOSS_Timer         .byte 0 ; Counts 255 to 0 waiting for reading comprehension and input.  When this reaches 0 without input, then erase menu.

gCurrentOption     .byte 0 ; Remember the last OPTION visited.

gCurrentSelect     .byte 0 ; Remember the last SELECT visited.

gCurrentMenuEntry  .byte 0 ; Menu entry number for Option and Select.

gCurrentMenuText   .word 0 ; pointer to text for the menu 

gOSSCompareResult  .byte 0 ; Set by the compare() function if current menu is the variable value.

gOSSDisplayOffset  .byte 0 ; +17 for Left position. Then +20 more == Right Buffer. 


; ==========================================================================
; MENUTASTIC - ENUMERATE STANDARD FUNCTIONS
; ==========================================================================

MENU_DONOTHING  = 0 ; ID for generic library to do nothing, but will return Z flag (BEQ)
MENU_DOONETHING = 1 ; ID for generic library to do nothing, but will return !Z flag (BNE)
MENU_SETVALUE   = 2 ; ID for generic library function to set config value to current menu item
MENU_SETTOGGLE  = 3 ; ID for generic library function to flip a value between 2 values
MENU_GETITEM    = 4 ; ID for generic library function to report if config variable matches current menu item
MENU_GETTOGGLE  = 5 ; ID for generic library function to report if toggle is set on or off. 
MENU_ONDISPLAY  = 6 ; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.



; ==========================================================================
; MENUTASTIC - CONFIG VALUES
; ==========================================================================
; 
; The Actual Variables that hold the currently configured values.
; 
; Each is declared as an eight byte structure:
; .byte == actual value
; .byte == default for variable.  For Toggles this should be 0.
; .word == Set function.  jsr address for custom function 
;          or MENU_SET* number.
; .word == Get function.  jsr address for custom function 
;          or MENU_GET* number.  (match variable to current 
;          select menu item.)
; .word == Display function.  jsr address for custom function or 
;          MENU_ONDISPLAY ID.  (Display On/OFF)
; --------------------------------------------------------------------------

; OFFSET values for structure.
;
; e.g.   lda [TABLE_CONFIG_VARIABLE+CONFIG_VAR_VALUE],X  
; where  X  is the variable number * 8.  (See CONFIG_* below).

CONFIG_VAR_VALUE     = 0 ; Actual configuration variable byte value.
CONFIG_VAR_DEFAULT   = 1 ; Configuration default byte value.
CONFIG_VAR_SETVALUE  = 2 ; Word-1 address of Set Value function OR Menutastic function ID
CONFIG_VAR_CMPVALUE  = 4 ; Word-1 address of Set Value function OR Menutastic function ID
CONFIG_VAR_ONDISPLAY = 6 ; Word-1 address of Set Value function OR Menutastic function ID

; Declare all the User's variables....

TABLE_CONFIG_VARIABLES

; Define a convenient "handle" that is the real offset into this table.
; Note that each is +8 bytes and in this iteration of menu handling 
; it will be used as a byte value.  Thus this system allows up to 32
; values configured by menus.   We're using 9.

CONFIG_LASERRESTART = 0       ; offset into this list of declared structures below.

gConfigLaserRestart
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_LASERSPEED = 8         ; entry occurrence * sizeof structure

gConfigLaserSpeed        
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_1NVADERSTARTSPEED = 16 ; entry occurrence * sizeof structure

gConfig1nvaderStartSpeed 
	.byte $01                 ; Value
	.byte $01                 ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_1NVADERHITCOUNTER = 24 ; entry occurrence * sizeof structure

gConfig1nvaderHitCounter 
	.byte 10                  ; Value
	.byte 10                  ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_1NVADERMAXSPEED  = 32  ; entry occurrence * sizeof structure

gConfig1nvaderMaxSpeed   
	.byte 9                   ; Value
	.byte 9                   ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_TWOPLAYERMODE = 40     ; entry occurrence * sizeof structure

gConfigTwoPlayerMode     
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_ONSIEMODE = 48         ; entry occurrence * sizeof structure

gConfigOnesieMode             ; Toggle on/off -- players take turns shooting.
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.
	.word MENU_GETITEM        ; Compare variable to current menu item.  CHANGE THIS *************************************************
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results. CHANGE THIS *****************************

CONFG_SETALLDEFAULTS = 56     ; entry occurrence * sizeof structure

gConfigSetAllDefaults         ; A variable is still needed for the custom Set code.
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word MENU_SETVALUE       ; Set variable to menu item. CHANGE THIS *************************************************************
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results. CHANGE THIS *****************************

CONFG_CHEATMODE = 64          ; entry occurrence * sizeof structure

gConfigCheatMode         
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word MENU_SETVALUE       ; Set variable to menu item.     CHANGE THIS **********************************
	.word MENU_GETITEM        ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results. CHANGE THIS *****************************



; ==========================================================================
; MENUTASTIC - MENU LABELS AND DESCRIPTIONS
; ==========================================================================
;
; This is not actually a "GFX ASSET".  The following are not directly 
; addressed or used as screen memory.    There is a separate buffer that  
; is used for scrolling and the Display List only points to that bufffer.
;
; Presenting options and descriptions is done by copying the text declared 
; below into the scrolling buffer.
; 
; The Menu text has two parts.  They are expected to be contiguous:
; The first 20 bytes is the line of Mode 6 Menu Title text.   
; The next 40 bytes is a line of Mode 2 text for more verbose description.
;
; --------------------------------------------------------------------------

; Left Buffer v Right Buffer for GFX indicator that this value is ON or OFF.
OSS_ONOFF_LEFT  = 17 ; offset from first position to print ON or OFF state.
OSS_ONOFF_RIGHT = 37 ; offset from first position to print ON or OFF state.

; OPTION MENUS ================================================

GFX_OPTION_1                 
	.sb "LASER RESTART MENU  "
GFX_OPTION_1_TEXT
	.sb +$40,"SET@THE@HEIGHT@THE@LASER@CAN@RESTART@@@@"

GFX_OPTION_2
	.sb "LASER SPEED MENU    "
GFX_OPTION_2_TEXT
	.sb +$40,"SET@THE@SPEED@OF@THE@LASER@SHOTS@@@@@@@@"

GFX_OPTION_3
	.sb "1NVADER STARTUP MENU"
GFX_OPTION_3_TEXT
	.sb +$40,"SET@THE@START@SPEED@FOR@THE@1NVADER@@@@@"

GFX_OPTION_4
	.sb "1NVADER SPEEDUP MENU"
GFX_OPTION_4_TEXT
	.sb +$40,"SET@THE@NUMBER@OF@HITS@FOR@SPEEDUP@@@@@@"

GFX_OPTION_5
	.sb "1NVADER SPEED MENU  "
GFX_OPTION_5_TEXT
	.sb +$40,"SET@THE@MAX@SPEED@OF@1NVADER@@@@@@@@@@@@"

GFX_OPTION_6
	.sb "TWO PLAYER MENU     "
GFX_OPTION_6_TEXT
	.sb +$40,"CHOOSE@THE@TWO@PLAYER@GAME@MODE@@@@@@@@@"

GFX_OPTION_7
	.sb "OTHER STUFF MENU    "
GFX_OPTION_7_TEXT
	.sb +$40,"MISCELLANEOUS@OTHER@THINGS@@@@@@@@@@@@@@" 


; SELECT Laser Restart Menu ===================================

GFX_MENU_1_1                 
	.sb "MID AUTO SHOT       "
GFX_MENU_1_1_TEXT
	.sb +$40,"AUTO@RESTART@LASER@HALF@WAY@UP@SCREEN@@@"

GFX_MENU_1_2
	.sb "SHORT AUTO SHOT     "
GFX_MENU_1_2_TEXT
	.sb +$40,"AUTO@RESTART@LASER@NEAR@BOTTOM@OF@SCREEN"

GFX_MENU_1_3
	.sb "FAR AUTO SHOT       "
GFX_MENU_1_3_TEXT
	.sb +$40,"AUTO@RESTART@LASER@NEAR@TOP@OF@SCREEN@@@"

GFX_MENU_1_4
	.sb "MID SHOT            "
GFX_MENU_1_4_TEXT
	.sb +$40,"MUST@RELEASE@BUTTON@TO@RESTART@LASER@@@@"

GFX_MENU_1_5
	.sb "SHORT SHOT          "
GFX_MENU_1_5_TEXT
	.sb +$40,"MUST@RELEASE@BUTTON@TO@RESTART@LASER@@@@"

GFX_MENU_1_6
	.sb "FAR SHOT            "
GFX_MENU_1_6_TEXT
	.sb +$40,"MUST@RELEASE@BUTTON@TO@RESTART@LASER@@@@"
 
 
; SELECT Laser Speed Menu =====================================

GFX_MENU_2_1                 
	.sb "REGULAR LASERS      "
GFX_MENU_2_1_TEXT
	.sb +$40,"THE@NORMAL@DEFAULT@SPEED@FOR@LASERS@@@@@"

GFX_MENU_2_2 
	.sb "FAST LASERS         "
GFX_MENU_2_2_TEXT
	.sb +$40,"FASTER@LASERS@MAY@NOT@HELP@SO@MUCH@@@@@@"

GFX_MENU_2_3 
	.sb "SLOW LASERS         "
GFX_MENU_2_3_TEXT
	.sb +$40,"PAINFULLY@SLOW@LASERS@@@@@@@@@@@@@@@@@@@"


; SELECT 1NVADER Startup Menu =================================

GFX_MENU_3_1                 
	.sb "REGULAR START 1     "
GFX_MENU_3_1_TEXT
	.sb +$40,"NORMAL@DEFAULT@1NVADER@START@SPEED@@@@@@"

GFX_MENU_3_2 
	.sb "START AT 3          "
GFX_MENU_3_2_TEXT
	.sb +$40,"1NVADER@STARTS@AT@SPEED@3@@@@@@@@@@@@@@@"

GFX_MENU_3_3 
	.sb "START AT 5          "
GFX_MENU_3_3_TEXT
	.sb +$40,"1NVADER@STARTS@AT@SPEED@5@@@@@@@@@@@@@@@"

GFX_MENU_3_4 
	.sb "START AT 7          "
GFX_MENU_3_4_TEXT
	.sb +$40,"1NVADER@STARTS@AT@SPEED@7@@@@@@@@@@@@@@@"

GFX_MENU_3_5 
	.sb "START AT MAX        "
GFX_MENU_3_5_TEXT
	.sb +$40,"1NVADER@AT@MAXIMUM@SPEED@LIKE@A@BOSS@@@@"


; SELECT 1NVADER Speedup Menu =================================

GFX_MENU_4_1                 
	.sb "EVERY 10 HITS       "
GFX_MENU_4_1_TEXT
	.sb +$40,"DEFAULT@"
	.byte GAME_HYPHEN_CHAR
	.sb +$40,"@SPEEDUP@EVERY@TEN@HITS@@@@@@@@"

GFX_MENU_4_2
	.sb "EVERY 7 HITS        "
GFX_MENU_4_2_TEXT
	.sb +$40,"SPEED@UP@EVERY@SEVEN@HITS@@@@@@@@@@@@@@@"

GFX_MENU_4_3
	.sb "EVERY 5 HITS        "
GFX_MENU_4_3_TEXT
	.sb +$40,"SPEED@UP@EVERY@FIVE@HITS@@@@@@@@@@@@@@@@"

GFX_MENU_4_4
	.sb "EVERY 3 HITS        "
GFX_MENU_4_4_TEXT
	.sb +$40,"SPEED@UP@EVERY@THREE@HITS@@@@@@@@@@@@@@@"

GFX_MENU_4_5
	.sb "EVERY 10,9,8...     "
GFX_MENU_4_5_TEXT
	.sb +$40,"PROGRESSIVELY@FEWER@SHOTS@PER@INCRMENT@@"

GFX_MENU_4_6
	.sb "NO SPEEDUP          "
GFX_MENU_4_6_TEXT
	.sb +$40,"REMAIN@AT@STARTUP@SPEED@@@@@@@@@@@@@@@@@"


; SELECT 1NVADER Max Speed Menu ===============================

GFX_MENU_5_1                 
	.sb "1NVADER SPEED 1     "
GFX_MENU_5_1_TEXT
	.sb +$40,"SLOWEST@MAXIMUM@SPEED@@@@@@@@@@@@@@@@@@@"

GFX_MENU_5_2               
	.sb "1NVADER SPEED 3     "
GFX_MENU_5_2_TEXT
	.sb +$40,"SPEEDUP@TO@THREE@@@@@@@@@@@@@@@@@@@@@@@@"

GFX_MENU_5_3               
	.sb "1NVADER SPEED 5     "
GFX_MENU_5_3_TEXT
	.sb +$40,"SPEEDUP@TO@FIVE@@@@@@@@@@@@@@@@@@@@@@@@@"

GFX_MENU_5_4               
	.sb "MAXIMUM SPEED       "
GFX_MENU_5_4_TEXT
	.sb +$40,"UP@TO@MAXIMUM@SPEED@@@@@@@@@@@@@@@@@@@@@"


; SELECT Two Player Modes Menu ================================

GFX_MENU_6_1                   
	.sb "FR1GULAR            " ; guns bounce
GFX_MENU_6_1_TEXT
	.sb +$40,"GUNS@BOUNCE@OFF@EACH@OTHER@@@@@@@@@@@@@@"

GFX_MENU_6_2 
	.sb "FR1GNORE            " ; guns ignore each other
GFX_MENU_6_2_TEXT
	.sb +$40,"GUNS@IGNORE@EACH@OTHER@@@@@@@@@@@@@@@@@@"

GFX_MENU_6_3                 
	.sb "FRENEM1ES           " ; Attached to each other
GFX_MENU_6_3_TEXT
	.sb +$40,"GUNS@ARE@ATTACHED@TO@EACH@OTHER@@@@@@@@@"

GFX_MENU_6_4 
	.sb "FRE1GHBORS          " ; Separated in center
GFX_MENU_6_4_TEXT
	.sb +$40,"STAY@IN@YOUR@OWN@YARD@AND@OFF@MY@LAWN@@@"


; SELECT Other things Menu ====================================

GFX_MENU_7_1                   
	.sb "ONES1ES             " ; 2P - Take turns shooting
GFX_MENU_7_1_TEXT
	.sb +$40,"TWO@PLAYERS@TAKE@TURNS@SHOOTING@@@@@@@@@"

GFX_MENU_7_2 
	.sb "RESET ALL           " ; Return all game value to default
GFX_MENU_7_2_TEXT
	.sb +$40,"RESTORE@ALL@SETTINGS@TO@DEFAULTS@@@@@@@@"

GFX_MENU_7_3 
	.sb "CHEAT MODE          " ; Alien never reaches bottom.
GFX_MENU_7_3_TEXT
	.sb +$40,"ALIEN@NEVER@REACHES@BOTTOM@@@@@@U@R@LAME"



; ==========================================================================
; MENUTASTIC -- MENUS, SELECTIONS, OPTIONS
; ==========================================================================
; Press OPTION key to cycle through top level menu. 
; Press SELECT key to cycle through SELECT menu lists.
; Press START key to engage the choice on the SELECT Menu.
;
; OPTION entries point to first entry on SELECT menu.
; SELECT entries point to *function() to set/unset item.
; --------------------------------------------------------------------------

; List of the variables IDs utilized for each of the SELECT menus entries

TABLE_MENU_CONFIG_VARIABLES
	.byte 0                        ; 0 - Top level Option menu list are not Select menu entries
	.byte 0                        ; 1 
	.byte 0                        ; 2
	.byte 0                        ; 3 
	.byte 0                        ; 4
	.byte 0                        ; 5
	.byte 0                        ; 6 
	.byte 0                        ; 7   Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte CONFIG_LASERRESTART      ; 8   Regular Laser Auto Restart (Default)
	.byte CONFIG_LASERRESTART      ; 9   Short Laser Auto Restart
	.byte CONFIG_LASERRESTART      ; 10  Long Laser Auto Restart
	.byte CONFIG_LASERRESTART      ; 11  Regular Laser Manual Restart
	.byte CONFIG_LASERRESTART      ; 12  Regular Laser Manual Restart
	.byte CONFIG_LASERRESTART      ; 13  Regular Laser Manual Restart
	.byte 0                        ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte CONFIG_LASERSPEED        ; 15  Regular laser speed  (Default)
	.byte CONFIG_LASERSPEED        ; 16  Fast laser speed (+2)
	.byte CONFIG_LASERSPEED        ; 17  Slow laser speed (-2)
	.byte 0                        ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte CONFIG_1NVADERSTARTSPEED ; 19 1nvader Start Speed 1 (Default)
	.byte CONFIG_1NVADERSTARTSPEED ; 20 1nvader Start Speed 3
	.byte CONFIG_1NVADERSTARTSPEED ; 21 1nvader Start Speed 5
	.byte CONFIG_1NVADERSTARTSPEED ; 22 1nvader Start Speed 7
	.byte CONFIG_1NVADERSTARTSPEED ; 23 1nvader Start Speed MAX
	.byte 0                        ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte CONFIG_1NVADERHITCOUNTER ; 25 1nvader speed up every 10 hits (Default)
	.byte CONFIG_1NVADERHITCOUNTER ; 26 1nvader speed up every 7 hits
	.byte CONFIG_1NVADERHITCOUNTER ; 27 1nvader speed up every 5 hits
	.byte CONFIG_1NVADERHITCOUNTER ; 28 1nvader speed up every 3 hits 
	.byte CONFIG_1NVADERHITCOUNTER ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte CONFIG_1NVADERHITCOUNTER ; 30 1nvader speed up no speedup
	.byte 0                        ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte CONFIG_1NVADERMAXSPEED   ; 32 Max speed 1
	.byte CONFIG_1NVADERMAXSPEED   ; 33 Max speed 3
	.byte CONFIG_1NVADERMAXSPEED   ; 34 Max speed 5
	.byte CONFIG_1NVADERMAXSPEED   ; 35 Max speed MAX (Default)
	.byte 0                        ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte CONFIG_TWOPLAYERMODE     ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte CONFIG_TWOPLAYERMODE     ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte CONFIG_TWOPLAYERMODE     ; 39 FRENEM1ES - Guns attached to each other.           
	.byte CONFIG_TWOPLAYERMODE     ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                        ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte CONFIG_ONSIEMODE         ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte CONFG_SETALLDEFAULTS     ; 43 Reset all values to defaults
	.byte CONFG_CHEATMODE          ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                        ; 45 Return to Select entry 42



; Data/Value/Flag passed to routines to set the value or match the current value.

TABLE_OPTION_ARGUMENTS
	.byte 0                              ; 0 - Top level Option menu list are not Select menu entries
	.byte 0                              ; 1 
	.byte 0                              ; 2
	.byte 0                              ; 3 
	.byte 0                              ; 4
	.byte 0                              ; 5
	.byte 0                              ; 6 
	.byte 0                              ; 7  Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte $00 ; gConfigLaserRestart      ; 8   Regular Laser Auto Restart (Default)
	.byte $01 ; gConfigLaserRestart      ; 9   Short Laser Auto Restart
	.byte $02 ; gConfigLaserRestart      ; 10  Long Laser Auto Restart
	.byte $80 ; gConfigLaserRestart      ; 11  Regular Laser Manual Restart
	.byte $81 ; gConfigLaserRestart      ; 12  Short Laser Manual Restart
	.byte $82 ; gConfigLaserRestart      ; 13  Long Laser Manual Restart
	.byte 0                              ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte $00 ; gConfigLaserSpeed        ; 15  Regular laser speed (Default)
	.byte $01 ; gConfigLaserSpeed        ; 16  Fast laser speed (+2)
	.byte $02 ; gConfigLaserSpeed        ; 17  Slow laser speed (-2)
	.byte 0                              ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte $01 ; gConfig1nvaderStartSpeed ; 19 1nvader Start Speed 1 (Default)
	.byte $03 ; gConfig1nvaderStartSpeed ; 20 1nvader Start Speed 3
	.byte $05 ; gConfig1nvaderStartSpeed ; 21 1nvader Start Speed 5
	.byte $07 ; gConfig1nvaderStartSpeed ; 22 1nvader Start Speed 7
	.byte $09 ; gConfig1nvaderStartSpeed ; 23 1nvader Start Speed MAX
	.byte 0                              ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte 10  ; gConfig1nvaderHitCounter ; 25 1nvader speed up every 10 hits (Default)
	.byte 7   ; gConfig1nvaderHitCounter ; 26 1nvader speed up every 7 hits
	.byte 5   ; gConfig1nvaderHitCounter ; 27 1nvader speed up every 5 hits
	.byte 3   ; gConfig1nvaderHitCounter ; 28 1nvader speed up every 3 hits 
	.byte 128 ; gConfig1nvaderHitCounter ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte 0   ; gConfig1nvaderHitCounter ; 30 1nvader speed up no speedup
	.byte 0                              ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte $01 ; gConfig1nvaderMaxSpeed   ; 32 Max speed 1
	.byte $03 ; gConfig1nvaderMaxSpeed   ; 33 Max speed 3
	.byte $05 ; gConfig1nvaderMaxSpeed   ; 34 Max speed 5
	.byte $09 ; gConfig1nvaderMaxSpeed   ; 35 Max speed MAX (Default)
	.byte 0                              ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte $00 ; gConfigTwoPlayerMode     ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte $01 ; gConfigTwoPlayerMode     ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte $02 ; gConfigTwoPlayerMode     ; 39 FRENEM1ES - Guns attached to each other.           
	.byte $03 ; gConfigTwoPlayerMode     ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                              ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte 0   ; gConfigOnesieMode        ; 42 TOGGLE - ONES1ES - 2P take turns shooting. (Default - Off)
	.byte 0   ; gConfigSetAllDefaults    ; 43 Reset all values to defaults
	.byte 0   ; gConfigCheatMode         ; 44 TOGGLE - Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                              ; 45 Return to Select entry 42



; Control path -- Where to go from OPTION menu when SELECT is pressed...

TABLE_OPTIONS_SELECTMENUS
	.byte 8  ; 8  SELECT Laser Restart Menu
	.byte 15 ; 15 SELECT Laser Speed Menu
	.byte 19 ; 19 SELECT 1NVADER Startup Menu
	.byte 25 ; 25 SELECT 1NVADER Speedup Menu
	.byte 32 ; 32 SELECT 1NVADER Max Speed Menu
	.byte 37 ; 37 SELECT Two Player Modes Menu
	.byte 42 ; 42 SELECT Other things Menu
	.byte 0  ; Go back to first menu.


; Table of pointers to strings for displayed text.
;                   A N D
; Control paths for looping from end back to start of a menu.
;
; The Menu text has two parts.  They are expected to be contiguous:
; The first 20 bytes is the line of Mode 6 Menu Title text.   
; The next 40 bytes is a line of Mode 2 text for more verbose description.
;
; This table implements special behavior:  If the HIGH byte
; of a pointer is 0, then the low byte is the new index
; value to use.   This allows a forward iteration through 
; the list to be reset to the first entry for that group of 
; Select menu entries.

TABLE_OPTIONS_LO
	.byte <GFX_OPTION_1 ; 0
	.byte <GFX_OPTION_2 ; 1 
	.byte <GFX_OPTION_3 ; 2
	.byte <GFX_OPTION_4 ; 3 
	.byte <GFX_OPTION_5 ; 4
	.byte <GFX_OPTION_6 ; 5
	.byte <GFX_OPTION_7 ; 6 
	.byte 0             ; 7   Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte <GFX_MENU_1_1 ; 8   Regular Laser Auto Restart (Default)
	.byte <GFX_MENU_1_2 ; 9   Short Laser Auto Restart
	.byte <GFX_MENU_1_3 ; 10  Long Laser Auto Restart
	.byte <GFX_MENU_1_4 ; 11  Regular Laser Manual Restart
	.byte <GFX_MENU_1_5 ; 12  Regular Laser Manual Restart
	.byte <GFX_MENU_1_6 ; 13  Regular Laser Manual Restart
	.byte 8             ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte <GFX_MENU_2_1 ; 15  Regular laser speed  (Default)
	.byte <GFX_MENU_2_2 ; 16  Fast laser speed (+2)
	.byte <GFX_MENU_2_3 ; 17  Slow laser speed (-2)
	.byte 15            ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte <GFX_MENU_3_1 ; 19 1nvader Start Speed 1 (Default)
	.byte <GFX_MENU_3_2 ; 20 1nvader Start Speed 3
	.byte <GFX_MENU_3_3 ; 21 1nvader Start Speed 5
	.byte <GFX_MENU_3_4 ; 22 1nvader Start Speed 7
	.byte <GFX_MENU_3_5 ; 23 1nvader Start Speed MAX
	.byte 19            ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte <GFX_MENU_4_1 ; 25 1nvader speed up every 10 hits (Default)
	.byte <GFX_MENU_4_2 ; 26 1nvader speed up every 7 hits
	.byte <GFX_MENU_4_3 ; 27 1nvader speed up every 5 hits
	.byte <GFX_MENU_4_4 ; 28 1nvader speed up every 3 hits 
	.byte <GFX_MENU_4_5 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte <GFX_MENU_4_6 ; 30 1nvader speed up no speedup
	.byte 25            ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte <GFX_MENU_5_1 ; 32 Max speed 1
	.byte <GFX_MENU_5_2 ; 33 Max speed 3
	.byte <GFX_MENU_5_3 ; 34 Max speed 5
	.byte <GFX_MENU_5_4 ; 35 Max speed MAX (Default)
	.byte 32            ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte <GFX_MENU_6_1 ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte <GFX_MENU_6_2 ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte <GFX_MENU_6_3 ; 39 FRENEM1ES - Guns attached to each other.           
	.byte <GFX_MENU_6_4 ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 37            ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte <GFX_MENU_7_1 ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte <GFX_MENU_7_2 ; 43 Reset all values to defaults
	.byte <GFX_MENU_7_3 ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 42            ; 45 Return to Select entry 42

TABLE_OPTIONS_HI
	.byte >GFX_OPTION_1 ; 0
	.byte >GFX_OPTION_2 ; 1 
	.byte >GFX_OPTION_3 ; 2
	.byte >GFX_OPTION_4 ; 3 
	.byte >GFX_OPTION_5 ; 4
	.byte >GFX_OPTION_6 ; 5
	.byte >GFX_OPTION_7 ; 6 
	.byte 0             ; 7   Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte >GFX_MENU_1_1 ; 8   Regular Laser Auto Restart (Default)
	.byte >GFX_MENU_1_2 ; 9   Short Laser Auto Restart
	.byte >GFX_MENU_1_3 ; 10  Long Laser Auto Restart
	.byte >GFX_MENU_1_4 ; 11  Regular Laser Manual Restart
	.byte >GFX_MENU_1_5 ; 12  Regular Laser Manual Restart
	.byte >GFX_MENU_1_6 ; 13  Regular Laser Manual Restart
	.byte 0             ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte >GFX_MENU_2_1 ; 15  Regular laser speed  (Default)
	.byte >GFX_MENU_2_2 ; 16  Fast laser speed (+2)
	.byte >GFX_MENU_2_3 ; 17  Slow laser speed (-2)
	.byte 0             ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte >GFX_MENU_3_1 ; 19 1nvader Start Speed 1 (Default)
	.byte >GFX_MENU_3_2 ; 20 1nvader Start Speed 3
	.byte >GFX_MENU_3_3 ; 21 1nvader Start Speed 5
	.byte >GFX_MENU_3_4 ; 22 1nvader Start Speed 7
	.byte >GFX_MENU_3_5 ; 23 1nvader Start Speed MAX
	.byte 0             ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte >GFX_MENU_4_1 ; 25 1nvader speed up every 10 hits (Default)
	.byte >GFX_MENU_4_2 ; 26 1nvader speed up every 7 hits
	.byte >GFX_MENU_4_3 ; 27 1nvader speed up every 5 hits
	.byte >GFX_MENU_4_4 ; 28 1nvader speed up every 3 hits 
	.byte >GFX_MENU_4_5 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte >GFX_MENU_4_6 ; 30 1nvader speed up no speedup
	.byte 0             ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte >GFX_MENU_5_1 ; 32 Max speed 1
	.byte >GFX_MENU_5_2 ; 33 Max speed 3
	.byte >GFX_MENU_5_3 ; 34 Max speed 5
	.byte >GFX_MENU_5_4 ; 35 Max speed MAX (Default)
	.byte 0             ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte >GFX_MENU_6_1 ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte >GFX_MENU_6_2 ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte >GFX_MENU_6_3 ; 39 FRENEM1ES - Guns attached to each other.           
	.byte >GFX_MENU_6_4 ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0             ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte >GFX_MENU_7_1 ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte >GFX_MENU_7_2 ; 43 Reset all values to defaults
	.byte >GFX_MENU_7_3 ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0             ; 45 Return to Select entry 42


; ==========================================================================
; MENUTASTIC - VBI MANAGEMENT
; ==========================================================================
; Manage Option/Select/Start Menus.
;
; This is the part called by the Vertical Blank Interrupt.
;
; This manages scrolling if text is in motion, collects input if 
; there is no scrolling motion, and manager the input timout timer.
;
; 1) If menu is in motion, continue the motion.  End.
; 2) If menu is not in motion, collect input from Option/Select/Start keys
; 3) If there is input, restart the input timer.
; 4) If there is no input, decrement the input timer.  End.
;
; Time value is observed by main code which will react to 0 timer value
; by erasing the option menu text from the screen.
;
; --------------------------------------------------------------------------

vbi_ManageMenutastic 

	lda gOSS_ScrollState       ; Scrolling status.  1, scrolling. 0, no scroll. -1 scroll just stopped. 
	beq b_vmm_OptNotMoving     ; 0, no scroll. Go do the timer and console button reading.

	jsr Gfx_ScrollOSSText      ; update the LMS in the display list to coarse scroll
	bne b_vmm_EndManageMenus   ; Always non-zero exit from Gfx_ScrollOSSTest

b_vmm_OptNotMoving
	jsr libAnyConsoleButton    ; Is a console key pressed?
	bmi b_vmm_GoodConsoleInput ; -1 == yes. 0 or 1 == Nope

	dec gOSS_TimeExt           ; 255 jiffies is not enough time for reading comprehension.
	bpl b_vmm_SkipJiffyClock   ; Did not go negative, so don't 

	lda #OSS_TIMER_EXTEND      ; Reset the timer extention.
	sta gOSS_TimeExt
	dec gOSS_Timer             ; when this is 0, Main code erases text.

b_vmm_SkipJiffyClock
	jmp b_vmm_EndManageMenus    
	
b_vmm_GoodConsoleInput
	jsr RestartMenutasticTimer ; A console key was pressed.  Restart the timer.

b_vmm_EndManageMenus
	rts



; ==========================================================================
;                                                     MAIN DO MENUTASTIC
; ==========================================================================
; Manage Option/Select/Start Menus.
;
; This is the part called by the main line code.
;
; If menu scroll is in progress, then skip this.  Nothing to do .
;
; If scroll just finished make then copy the right buffer to left buffer
; and reset LMS to point to left buffer.
;
; If the input timer expires (reaches 0) then erase the menu and 
; reset everything off.
;
; Collect console key input, and if any, then process key.
; --------------------------------------------------------------------------

Main_DoMenutastic

	lda gOSS_ScrollState
	beq b_mdm_ProcessOrNot     ; (0) No scrolling, so is there a menu for processing?
	bpl b_mdm_Exit             ; (>0) Scrolling in progress.   Nothing else to do.

	; (<0) process of elimination.  Last choice.  The scrolling just stopped now.
	jsr Gfx_ResetOSSText       ; Copy right buffer to left, reset the LMS, reset scroll state.
	beq b_mdm_Exit             ; Above code ends by setting scroll state to 0, so, BEQ.

b_mdm_ProcessOrNot
	lda gOSS_Timer             ; Has the timer reached 0?
	bne b_mdm_CheckInput       ; No.  Continue with input checking.
	jsr Gfx_ClearOSSText       ; Yes, erase menu.  Shut it all off.
	beq b_mdm_Exit             ; Above code ends by setting scroll state to 0, so, BEQ.

b_mdm_CheckInput
	lda gDEBOUNCE_OSS          ; If debounce >=0  ?
	bpl b_mdm_Exit             ; No debounce, no input, so skip to end.
;	bmi a key is pressed
	lda #1
	sta gDEBOUNCE_OSS          ; Put the VBI back into waiting for debounce.

	jsr RestartMenutasticTimer ; Since a key should be pressed now then reset the input timer.

	lda gOSS_KEYS
	ror                        ; Rotate and push out START bit
	bcc b_mdm_StartKey         ; 0 == START button pressed

	ror                        ; Rotate and push out SELECT bit
	bcc b_mdm_SelectKey        ; 0 == SELECT button pressed
	
	ror                        ; Rotate and push out OPTION bit
	bcs b_mdm_Exit             ; 1 == OPTION button NOT pressed.  Done testing keys.

b_mdm_OptionKey
	jsr GameOptionMenu         ; Process Option key input.
	rts

b_mdm_SelectKey
	jsr GameSelectMenu         ; Process Select key input.
	rts

b_mdm_StartKey
	jsr GameStartAction        ; Process Start key input.

b_mdm_Exit
	rts



; ==========================================================================
;                                               RESTART MENUTASTIC TIMER
; ==========================================================================
; Initialize timer waiting for reading comprehension and input.
;
; Two bytes are used, because 255 jiffies is not enough time to 
; read the menu text and respond sometimes.
; --------------------------------------------------------------------------

RestartMenutasticTimer

	lda #$ff                   ; A console key was pressed.  Main will take care 
	sta gOSS_Timer             ; of it.  Restart the timer in case.
	lda #OSS_TIMER_EXTEND      ; 255 jiffies is not enough time for reading comprehension.
	sta gOSS_TimeExt

	rts


; ==========================================================================
; OPTION MENU
; ==========================================================================
; Manage Option Menu.
;
; If menu is off or showing Select menu, then go to display the last 
; Option Menu and text.
;
; If already displaying an Option Menu then increment to the next Option
; Menu.
;
; If the next Option Menu is not a menu item, but points elsewhere, then
; follow the direction to jump to the given Option entry.
;
; Setup Option Menu to begin scrolling on the screen. (VBI does that work.)  
;
; Reset the current Select Menu entry to the first entry for the Option 
; Menu's list of Select Menu entries.
;
; --------------------------------------------------------------------------

GameOptionMenu

	ldx gCurrentOption              ; Prep current value as index into pointer table.

	lda gOSS_Mode                   ; What's the current condition of the menus?
	beq b_gom_ShowOption            ; Menu off. Go Show current/last option menu
	bpl b_gom_ShowOption            ; Select mode. Go show the current/last option menu.

	jsr GameNextMenuOrReset         ; Next Option menu or reset the Option menu.
	stx gCurrentOption              ; Save updated Option index.

b_gom_ShowOption
	lda TABLE_OPTIONS_SELECTMENUS,X ; Force Select menu back to the ...
	sta gCurrentSelect              ; ... first entry under this Option.

	jsr Gfx_CopyOptionToRightBuffer ; Using X as menu entry index, copy text via pointers to screen ram.

	lda #$ff 
	sta gOSS_Mode                   ; Let everyone know we're now in option menu mode

	rts



; ==========================================================================
; SELECT MENU
; ==========================================================================
; Manage Select Menu.
;
; If menu is off or showing Select menu, then go to display the last 
; Option Menu and text.
;
; If already displaying an Option Menu then increment to the next Option
; Menu.
;
; If the next Option Menu is not a menu item, but points elsewhere, then
; follow the direction to jump to the given Option entry.
;
; Setup Option Menu to begin scrolling on the screen. (VBI does that work.)  
;
; Reset the current Select Menu entry to the first entry for the Option 
; Menu's list of Select Menu entries.
;
; --------------------------------------------------------------------------

GameSelectMenu

	ldx gCurrentSelect              ; Prep current value as index into pointer table.

	lda gOSS_Mode                   ; What's the current condition of the menus?
	beq b_gsem_EndSelectMenu        ; Menu off. Must be in Option or Select modes to change Select Menu.
	bmi b_gsem_ShowSelect           ; In Option Mode. Switch to Select. Show the current (last) select menu.

	jsr GameNextMenuOrReset         ; Next Select menu or reset the Select menu.
	stx gCurrentSelect              ; Update current entry

b_gsem_ShowSelect
	jsr Gfx_CopyOptionToRightBuffer ; Using X as menu entry index, copy text via pointers to screen ram.
	jsr DisplayOnOffRightBuffer     ; Add ON or OFF indicator to the menu item to scroll

	lda #1
	sta gOSS_Mode                   ; Let everyone know we're now in select menu mode

b_gsem_EndSelectMenu
	rts



; ==========================================================================
; START ACTION
; ==========================================================================
; Manage turning on/off the current selected item
;
; The menu must be on a Selected menu item, not the top level Option.
;
; Mutually exclusive items -- if the option is off, then turn it on,
; making sure all other parallel options are off. 
;
; --------------------------------------------------------------------------

GameStartAction

	lda gOSS_Mode              ; What's the current condition of the menus?
	beq b_gsa_EndStartAction   ; Menu off. Must be Select modes to change Select Menu.
	bmi b_gsa_EndStartAction   ; In Option Mode. Must be in Select mode to change Select Menu.

;	ldx gCurrentSelect         ; Prep current value as index into pointer table.
	jsr GameSetConfigOption    ; Set config to current option.
	jsr DisplayOnOffLeftBuffer ; Add ON or OFF indicator to the menu item on screen

b_gsa_EndStartAction
	rts



; ==========================================================================
;                                                        NEXT MENU OR RESET
; ==========================================================================
; Manage Moving to next menu entry...
;
; Input is value in X register for the current menu index. 
;
; Increment the value and look at the next entry in the menu table. 
; If the menu table entry represents a forced reset, get the new value. 
;
; Return new menu index in X.
; --------------------------------------------------------------------------

GameNextMenuOrReset

	inx                    ; Go to next Menu entry
	
	lda TABLE_OPTIONS_HI,X ; Get hi byte from address of string
	bne b_gnmor_SkipReset  ; High byte <> 0.  So, use this entry.

	lda TABLE_OPTIONS_LO,X ; High Byte is 0.  Use low byte as new index.
	tax

b_gnmor_SkipReset
	rts




; ==========================================================================
;                                          MENUTASTIC STANDARD FUNCTIONS
; ==========================================================================
; A variable need not provide its own function for access and comparison
; if it follows a standard set of behaviors.  Rather than provide 
; addresses for the set, get/compare, and display values, the variable 
; can provide a handle ID.
;
; Real functions are assumed to have a non-zero high byte. 
;
; Library common functions enumerated here are small integers with a 
; zero byte for the high byte value.
;
; The library recognizes what choice is in use and calls the variable's
; function or the standard library call accordingly.
;
; MENU_DONOTHING  = 0 ; ID for generic library to do nothing, but will return Z flag (BEQ)
; MENU_DOONETHING = 1 ; ID for generic library to do nothing, but will return !Z flag (BNE)
; MENU_SETVALUE   = 2 ; ID for generic library function to set config value to current menu item
; MENU_SETTOGGLE  = 3 ; ID for generic library function to flip a value between 2 values
; MENU_GETITEM    = 4 ; ID for generic library function to report if config variable matches current menu item
; MENU_GETTOGGLE  = 5 ; ID for generic library function to report if toggle is set on or off. 
; MENU_ONDISPLAY  = 6 ; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.
; --------------------------------------------------------------------------

TABLE_MENUTASTIC_FUNCTIONS_LO
	.byte <[MENU_STD_DONOTHING-1]  ; MENU_DONOTHING  = 0 ; ID for generic library to do nothing, but will return Z flag (BEQ)
	.byte <[MENU_STD_DOONETHING-1] ; MENU_DOONETHING = 1 ; ID for generic library to do nothing, but will return !Z flag (BNE)
	.byte <[MENU_STD_SETVALUE-1]   ; MENU_SETVALUE   = 2 ; ID for generic library function to set config value to current menu item
	.byte <[MENU_STD_SETTOGGLE-1]  ; MENU_SETTOGGLE  = 3 ; ID for generic library function to flip a value between 2 values
	.byte <[MENU_STD_GETITEM-1]    ; MENU_GETITEM    = 4 ; ID for generic library function to report if config variable matches current menu item
	.byte <[MENU_STD_GETTOGGLE-1]  ; MENU_GETTOGGLE  = 5 ; ID for generic library function to report if toggle is set on or off. 
	.byte <[MENU_STD_ONDISPLAY-1]  ; MENU_ONDISPLAY  = 6 ; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.

TABLE_MENUTASTIC_FUNCTIONS_HI
	.byte >[MENU_STD_DONOTHING-1]  ; MENU_DONOTHING  = 0 ; ID for generic library to do nothing, but will return Z flag (BEQ)
	.byte >[MENU_STD_DOONETHING-1] ; MENU_DOONETHING = 1 ; ID for generic library to do nothing, but will return !Z flag (BNE)
	.byte >[MENU_STD_SETVALUE-1]   ; MENU_SETVALUE   = 2 ; ID for generic library function to set config value to current menu item
	.byte >[MENU_STD_SETTOGGLE-1]  ; MENU_SETTOGGLE  = 3 ; ID for generic library function to flip a value between 2 values
	.byte >[MENU_STD_GETITEM-1]    ; MENU_GETITEM    = 4 ; ID for generic library function to report if config variable matches current menu item
	.byte >[MENU_STD_GETTOGGLE-1]  ; MENU_GETTOGGLE  = 5 ; ID for generic library function to report if toggle is set on or off. 
	.byte >[MENU_STD_ONDISPLAY-1]  ; MENU_ONDISPLAY  = 6 ; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.



; ==========================================================================
;                                            DISPLAY ON OFF RIGHT BUFFER
; ==========================================================================
; Given the current Select menu determine if that option is 
; on or off.
;
; Write the ON/OFF status in the RIGHT buffer. (to be scrolled)
; --------------------------------------------------------------------------

DisplayOnOffRightBuffer

	ldx #OSS_ONOFF_RIGHT ; +17 for Left position. Then +20 more == Right Buffer. 
	bpl DisplayOnOff     ; We know offset must be positive (or less than 128), right?


; ==========================================================================
;                                            DISPLAY ON OFF LEFT BUFFER
; ==========================================================================
; Given the current Select menu determine if that option is 
; on or off.
;
; Write the ON/OFF status in the LEFT buffer. (currently displayed)
; --------------------------------------------------------------------------

DisplayOnOffLeftBuffer

	ldx #OSS_ONOFF_LEFT  ; +17 for Left position. Then +20 more == Right Buffer. 
	bpl DisplayOnOff     ; We know offset must be positive (or less than 128), right?


; ==========================================================================
;                                            DISPLAY ON OFF IN BUFFER
; ==========================================================================
; Given the current Select menu determine if that option is 
; on or off.
;
; X is the offset position into the GFX buffer (top line of menu display)
;
; Write the ON/OFF status in the buffer. 
;
; Result is comparison of the current select menu configuration value to 
; the actual configuration variable.
;
; Result:
; BEQ == Current Select item is the current config.
; BNE == Current Select item is not the current config value
; --------------------------------------------------------------------------


DisplayOnOff

	stx gOSSDisplayOffset          ; Save for use later.  +17 for Left position. Then +20 more == Right Buffer. 

	lda #CONFIG_VAR_CMPVALUE       ; Call Compare for current SELECT menu entry
	jsr MenutasticStandardDispatch ; Grand Unified Theorem
	
	lda #CONFIG_VAR_ONDISPLAY      ; Call Draw ON/OFF based on gOSSCompareResult
	jsr MenutasticStandardDispatch ; Call the display code.

;	ldx gOSSDisplayOffset       
;	jsr Gfx_Display_OnOff_Option ; Display if on or off.

	rts





;
;gOSS_ScrollState  .byte 0 ; Status of scrolling: 1=scrolling. 0=not scrolling. -1=scroll just stopped. 
;
;gOSS_Mode         .byte 0 ; 0=Off  -1=option menu  +1=is select menu.
;
;gOSS_Timer        .byte 0 ; Counts to wait for text.  When this reaches 0 without input, then erase menu.
;
;gCurrentOption    .byte 0 ; Remember the OPTION we looked at last.
;
;gCurrentSelect    .byte 0 ; Remember the SELECT entery we looked at last.
;
;gCurrentMenuEntry .byte 0 ; Menu entry number for Option and Select.
;
;gCurrentMenuText  .word 0 ; pointer to text for the menu 
;

; ==========================================================================
;                                           MENUTASTIC STANDARD DISPATCH
; ==========================================================================
; Given the current Select Menu Entry, and the offset to the action 
; function (set, get/cmp, or display) then:
; 1) Get Variable ID (offset in TABLE_CONFIG_VARIABLES)
; 2) Get function address.
; 3) if high byte is 0, push address of standard library routine.
; 4) if high byte is !0, push address of function.
; 5) call by RTS. 
;
; Note that 0 is valid for Variable ID, but this function should never 
; be reached when operating in Option mode menu display.
;
; A = offset to action.
; --------------------------------------------------------------------------

; e.g.   lda [TABLE_CONFIG_VARIABLE+CONFIG_VAR_VALUE],X  
; where  X  is the variable number * 8.  (See CONFIG_* below).

CONFIG_VAR_VALUE     = 0 ; Actual configuration variable byte value.
CONFIG_VAR_DEFAULT   = 1 ; Configuration default byte value.
CONFIG_VAR_SETVALUE  = 2 ; Word-1 address of Set Value function OR Menutastic function ID
CONFIG_VAR_CMPVALUE  = 4 ; Word-1 address of Set Value function OR Menutastic function ID
CONFIG_VAR_ONDISPLAY = 6 ; Word-1 address of Set Value function OR Menutastic function ID



MENU_DONOTHING  = 0 ; ID for generic library to do nothing, but will return Z flag (BEQ)
MENU_DOONETHING = 1 ; ID for generic library to do nothing, but will return !Z flag (BNE)
MENU_SETVALUE   = 2 ; ID for generic library function to set config value to current menu item
MENU_SETTOGGLE  = 3 ; ID for generic library function to flip a value between 2 values
MENU_GETITEM    = 4 ; ID for generic library function to report if config variable matches current menu item
MENU_GETTOGGLE  = 5 ; ID for generic library function to report if toggle is set on or off. 
MENU_ONDISPLAY  = 6 ; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.



; Declare all the User's variables....

TABLE_CONFIG_VARIABLES


; ==========================================================================
;                                           MENUTASTIC STANDARD DISPATCH
; ==========================================================================
; The General Function Caller.
;
; A = the action to perform in the variable.   It should be one of these:
; CONFIG_VAR_SETVALUE  = 2 ; Word-1 address of Set Value function OR Menutastic function ID
; CONFIG_VAR_CMPVALUE  = 4 ; Word-1 address of Set Value function OR Menutastic function ID
; CONFIG_VAR_ONDISPLAY = 6 ; Word-1 address of Set Value function OR Menutastic function ID
;
; The current variable is the index taken from the current SELECT item.
;
; Add A (Action) to the offset for the current variable to get the 
; offset/index to the function specified by Action.
;
; If the function high byte is 0, then the low byte is an ID value for a 
; standard library function.  Load the address for the standard function.
;
; If the function high byte is non-zero, then the variable has the 
; address of a custom function.  Load that instead.
;
; On exit (rts == function call) X will be the index of the current menu.
; --------------------------------------------------------------------------

MenutasticStandardDispatch

	ldx gCurrentSelect                  ; X = Current Select Menu being viewed
	clc
	adc TABLE_MENU_CONFIG_VARIABLES,X   ; A = [TABLE_MENU_CONFIG_VARIABLES OFFSET + ACTION OFFSET (in A)]
	tay                                 ; Y = Variable offset + Action  (Offset) 

	lda [TABLE_CONFIG_VARIABLES + 1],Y  ; Get pointer high byte
	beq b_msd_LoadStandardFunction      ; Given Y, Get function ID, and load pointer address

	pha                                 ; push to stack - custom function high byte
	lda TABLE_CONFIG_VARIABLES,Y        ; Get custom function pointer low byte
	pha                                 ; Push to stack

	jmp b_msd_InvokeFunction

b_msd_LoadStandardFunction
	ldx TABLE_CONFIG_VARIABLES,Y        ; get the function ID from low byte.

	lda TABLE_MENUTASTIC_FUNCTIONS_HI,x ; Get library function pointer high byte
	pha                                 ; Push to stack
	lda TABLE_MENUTASTIC_FUNCTIONS_LO,x ; Get library function pointer high byte
	pha                                 ; Push to stack

b_msd_InvokeFunction
	ldx gCurrentSelect                  ; X = Current Select Menu being viewed
	ldy TABLE_MENU_CONFIG_VARIABLES,X   ; Y = Variable ID (Offset)

	rts


; ==========================================================================
;                                                    MENU STD DO NOTHING
; ==========================================================================
; MENU_DONOTHING  = 0 
; ID for generic library to do nothing, but will return Z flag (BEQ)
;
; Technically, do nothing.
;
; Actually, force the compare status to Zero.
; This may be useful on a toggle-like variable and cheat the compare
; to force it to zero.  Did that make sense?  Maybe not.
; --------------------------------------------------------------------------

MENU_STD_DONOTHING 

	lda #0
	sta gOSSCompareResult

	rts


; ==========================================================================
;                                                  MENU STD DO ONE THING
; ==========================================================================
; MENU_DOONETHING = 1 
; ID for generic library to do nothing, but will return !Z flag (BNE)
;
; Technically, do nothing.
;
; Actually, force the compare status to One.
; This may be useful on a toggle-like variable and cheat the compare
; to force it to one.  Did that make sense?  Maybe not.
; --------------------------------------------------------------------------

MENU_STD_DOONETHING 

	lda #1
	sta gOSSCompareResult

	rts


; ==========================================================================
;                                                     MENU STD SET VALUE
; ==========================================================================
; MENU_SETVALUE   = 2 
; ID for generic library function to set config value to current menu item
;
; Given the current Select menu copy the menu value to 
; the associated variable.
;
; Given Select Menu X, get Variable number (offset) Y.
;
; Get value from Menu X, store in variable number (offset) Y.
; --------------------------------------------------------------------------

MENU_STD_SETVALUE   

;	ldx gCurrentSelect                                ; X = Current Select Menu being viewed
;	ldy TABLE_MENU_CONFIG_VARIABLES,X                 ; Y = Variable ID (Offset) 

	lda TABLE_OPTION_ARGUMENTS,X                      ; Get current SELECT menu item value.
	sta [TABLE_CONFIG_VARIABLES + CONFIG_VAR_VALUE],Y ; Set variable value. 

	rts


; ==========================================================================
;                                                    MENU STD SET TOGGLE
; ==========================================================================
; MENU_SETTOGGLE  = 3 
; ID for generic library function to flip a value between 2 values
;
; Given the current Select menu toggle the value of the associated variable.
;
; Given Select Menu X, get Variable number (offset) Y.
;
; Get value from Menu X, rewrite.  
; 0 become 1.   1 becomes 0.
; --------------------------------------------------------------------------

MENU_STD_SETTOGGLE

;	ldx gCurrentSelect                                ; X = Current Select Menu being viewed
;	ldy TABLE_MENU_CONFIG_VARIABLES,X                 ; Y = Variable ID (Offset) 

	lda [TABLE_CONFIG_VARIABLES + CONFIG_VAR_VALUE],Y ; Get variable value. 
	beq b_MSST_SetOne

	lda #0
	sta [TABLE_CONFIG_VARIABLES + CONFIG_VAR_VALUE],Y ; Set variable value. 
	rts

b_MSST_SetOne
	lda #1
	sta [TABLE_CONFIG_VARIABLES + CONFIG_VAR_VALUE],Y ; Set variable value. 

	rts


; ==========================================================================
;                                                 MENU STANDARD GET ITEM
; ==========================================================================
; MENU_GETITEM    = 4 
; ID for generic library function to report if config 
; variable matches current menu item
;
; Given the current Select menu determine if the associated 
; variable has the same value as the menu item.
;
; Result is comparison of the current select menu configuration value
; to the actual configuration variable.   
; Save in gOSSCompareResult. (and by extension, the CPU Z flag.)
;
; Given Select Menu X, get Variable number (offset) Y.
;
; Given Variable number (offset) Y, Get value from variable.
;
; Result:
; 0/BEQ == Current Select item is the current config.
; 1/BNE == Current Select item is not the current config value
; --------------------------------------------------------------------------

MENU_STD_GETITEM                                      

	lda #0                                            ; Clear the return value to 0, aka "equal match"
	sta gOSSCompareResult
	
;	ldx gCurrentSelect                                ; X = Current Select Menu being viewed
;	ldy TABLE_MENU_CONFIG_VARIABLES,X                 ; Y = Variable ID (Offset)

	lda [TABLE_CONFIG_VARIABLES + CONFIG_VAR_VALUE],Y ; Get variable value. 
	cmp TABLE_OPTION_ARGUMENTS,X                      ; compare to current SELECT menu item.

	beq b_MSGI_Exit                                   ; Equal.  Return Zero. (BEQ)

	inc gOSSCompareResult                             ; NOT Equal. Return One. (BNE)

b_MSGI_Exit
	rts



; ==========================================================================
;                                               MENU STANDARD GET TOGGLE
; ==========================================================================
; MENU_GETTOGGLE  = 5 
; ID for generic library function to report if toggle is set on or off. 
;
; Given the current Select menu determine if that option is 
; on or off.
;
; Result is just zero or nonzero state of the toggled variable.
; No actual comparison here.
; Save in gOSSCompareResult. (and by extension, the CPU Z flag.)
;
;
; Given Select Menu X, get Variable number (offset) Y.
;
; Given Variable number (offset) Y, Get value from variable.
;
; Result:
; BEQ == Current Select item is the current config.
; BNE == Current Select item is not the current config value
; --------------------------------------------------------------------------

MENU_STD_GETTOGGLE

	lda #0                                            ; Clear the return value to 0, aka "equal match"
	sta gOSSCompareResult
	
;	ldx gCurrentSelect                                ; X = Current Select Menu being viewed
;	ldy TABLE_MENU_CONFIG_VARIABLES,X                 ; Y = Variable ID (Offset)

	lda [TABLE_CONFIG_VARIABLES + CONFIG_VAR_VALUE],Y ; Get variable value. 
	beq b_MSGT_Exit                                   ; Equal.  Return Zero. (BEQ)

	inc gOSSCompareResult                             ; NOT Equal. Return One. (BNE)

b_MSGT_Exit
	rts


; ==========================================================================
;                                              CHECK CONFIG MATCHES MENU
; ==========================================================================
; MENU_ONDISPLAY  = 6 
; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.
; --------------------------------------------------------------------------

MENU_STD_ONDISPLAY  

	rts



; ==========================================================================
;                                              CHECK CONFIG MATCHES MENU
; ==========================================================================
; Given the current Select menu determine if that option is 
; on or off.
;
; Result is comparison of the current select menu configuration value to 
; the actual configuration variable.
;
; Given Select Menu X, get Variable number Y
;
; Result:
; BEQ == Current Select item is the current config.
; BNE == Current Select item is not the current config value
; --------------------------------------------------------------------------

CheckConfigMatchesMenu

	ldx gCurrentSelect                ; X = Current Select Menu being viewed
	ldy TABLE_MENU_CONFIG_VARIABLES,X ; Y = Variable ID (Offset) (0 is entirely valid, but we should never end up here from an Option menu.

	lda [TABLE_CONFIG_VARIABLES + CONFIG_VAR_CMPVALUE],Y      ; Get pointer low byte
	ora [TABLE_CONFIG_VARIABLES + CONFIG_VAR_CMPVALUE + 1],Y  ; OR with pointer high byte
	beq b_EndGetOnOrOffOption            ; 0 value is NULL pointer, so  nothing to do.

	lda [TABLE_CONFIG_VARIABLES + CONFIG_VAR_CMPVALUE + 1],Y  ; Get pointer high byte
	bne b_ccmm_CustomGetFunction                              ; High Byte <> 0, so it is a real function.
	; High Byte is 0, so low byte is the Get Function Pointer .

	jsr LoadGenericGetFunction  ; Given Y, Get function ID, and load pointer address
;	beq or something here to skip over th call for custom load.
	
b_ccmm_CustomGetFunction

	jsr MenuGenericConAddr1
	beq b_EndGetOnOrOffOption    ; 0 value is NULL pointer, so  nothing to do.

	jsr MenuGenericConAddr2

	pha                           ; push to stack for set()/get() function to use.
	lda TABLE_GET_FUNCTIONS_HI,x  ; Get pointer high byte 
	pha                          ; Push to stack
	lda TABLE_GET_FUNCTIONS_LO,x    ; Get pointer low byte
	pha                          ; Push to stack

b_EndGetOnOrOffOption
	rts
	; When the called routine ends with rts, it will return to the place 
	; that called this routine which is up in SELECT key handling.



; ==========================================================================
;                                                     SET CONFIG OPTION
; ==========================================================================
; Given the current Select menu item engage the function to set the
; config to the value associated to this Select menu item
; --------------------------------------------------------------------------

GameSetConfigOption

	ldx gCurrentSelect           ; X = Current Select Menu being viewed

	lda TABLE_SET_FUNCTIONS_LO,X ; Get pointer low byte
	ora TABLE_SET_FUNCTIONS_HI,X ; OR with pointer high byte
	beq b_EndSetConfigOption     ; 0 value is NULL pointer, so  nothing to do.

	jsr MenuGenericConAddr1      ; Common set for addr.
	beq b_EndSetConfigOption     ; 0 value is NULL pointer, so  nothing to do.

	jsr MenuGenericConAddr2      ; Finish Addr setup and get config value from array

	pha                          ; push to stack for set()/get() function to use.
	lda TABLE_SET_FUNCTIONS_HI,X ; Get pointer high byte 
	pha                          ; Push to stack
	lda TABLE_SET_FUNCTIONS_LO,X ; Get pointer low byte
	pha                          ; Push to stack

b_EndSetConfigOption
	rts
	; When the called routine ends with rts, it will return to the place 
	; that called this routine which is up in SELECT key handling.


; ==========================================================================
; Common setup for the low byte and null value test

MenuGenericConAddr1
	lda TABLE_CONFIG_ADDRESS_LO,X    ; Get variable pointer low byte
	sta zMenuConfigAddress
	ora TABLE_CONFIG_ADDRESS_HI,X  ; OR with pointer high byte
	rts

MenuGenericConAddr2
	lda TABLE_CONFIG_ADDRESS_HI,X  ; Get variable pointer high byte
	sta zMenuConfigAddress+1

	lda TABLE_OPTION_ARGUMENTS,X  ; get config value for this menu.
	rts


; ==========================================================================
;                                                     GET LASER RESTART
; ==========================================================================
; Get value of this menu entry and compare to 
; current laser restart configuration.
;
; Result of comparison determines whether or not to 
; display ON or OFF text.
; --------------------------------------------------------------------------

;getLaserRestart

;	pla                      ; Get the canned version of this menu's value from the stack.
;	cmp gConfigSomething  ; compare to the actual config value

;	rts

; ==========================================================================
;                                                     SET LASER RESTART
; ==========================================================================
; Set value of the laser restart configuration to the value associated 
; to the current Select menu entry.
; --------------------------------------------------------------------------

;setLaserRestart

;	pla                      ; Get the canned version of this menu's value from the stack.
;	sta gConfigSomething   ; save it as the new config value

;	rts

; ==========================================================================
;                                           GET GENERIC EXCLUSIVE CONFIG
; ==========================================================================
; Generic function to GET the value of a configure variable and compare 
; it to the canned value.
;
; The resulting comparison value (CPU flags) describes this as equal to 
; or not equal to the current menu entry.
;
; In most cases the comparison result is used to update the display 
; to present the ON or OFF indicator.
;
; This is generally the function to use for a config that is assigned
; one value from a mutually exclusive list of entries.  e.g. a set 
; of menu items that each assign a value from the list: 1,2,3,4,5...
; --------------------------------------------------------------------------

getGenericExclusiveConfig

	ldy #0
	pla                      ; Get the canned version of this menu's value from the stack.
	cmp (zMenuConfigAddress),Y  ; compare to the actual config value

	rts

; ==========================================================================
;                                           SET GENERIC EXCLUSIVE CONFIG
; ==========================================================================
; Generic function to SET the value of a configure variable.
;
; This is generally the function to use for a config that is assigned
; one value from a mutually exclusive list of entries.  e.g. a set 
; of menu items that each assign a value from the list: 1,2,3,4,5...
; --------------------------------------------------------------------------

setGenericExclusiveConfig

	ldy #0
	pla                      ; Get the canned version of this menu's value from the stack.
	sta (zMenuConfigAddress),Y   ; save it as the new config value

	rts





; ==========================================================================
; MENUS, SELECTIONS, OPTIONS
; ==========================================================================
; Press OPTION key to cycle through top level menu. 
; Press SELECT key to cycle through SELECT menu lists.
; Press START key to engage the choice on the SELECT Menu.
;
; OPTION entries point to first entry on SELECT menu.
; SELECT entries point to *function() to set/unset item.
;
; The options text will be scrolling on/off the screen so fast, that 
; fine scrolling is not needed.   Coarse scrolling is fine.  Therefore 
; no extra buffer characters are needed.  Just stock 20 characters plus
; 20 characters for Mode 6, and 40 + 40 for Mode 2.
;
; The Default position before doing a scroll is the Display List LMS
; pointed at the left side of the buffer.
;
; Erasing or Running Text:
; 0) DEFAULT: Set to Left Postion.
; 1) MAIN: Copy Text to Right Position. (Set the On or Off text as needed.)
; 2) VBI: Scroll ending at right position.
; 3) MAIN:Copy Text to Left position.
; 4) VBI: Set LMS to Left Position.
; 5) VBI: Set Debounce for button/key input to get/allow/process Input.
; 
;	.sb "  OPTION "     ; 10        ; White
;	.sb +$40,"TEXT "    ; 5         ; Green
;	.sb +$80,"HERE  "   ; 6 == 20   ; Red
; --------------------------------------------------------------------------

Gfx_RunMenu_VBI

	rts


; ==========================================================================
; CLEAR OPTION RIGHT BUFFER
; ==========================================================================
; Erase the right side of the scroll buffer (which by default is the 
; part off screen.).
;
; Set memset address
; Set Memset Length
; Call Memset.
; --------------------------------------------------------------------------

Gfx_ClearOptionsRightBuffer

	mMemset GFX_OPTION_RIGHT,20,INTERNAL_BLANKSPACE

	mMemset GFX_OPTION_TEXT_RIGHT,40,CHAR_MODE2_BLANK

	rts


; ==========================================================================
; CLEAR OPTION LEFT BUFFER
; ==========================================================================
; Erase the left side of the scroll buffer (which by default is the 
; part on screen  EXCEPT after a scroll has completed.) 
; This would be used to erase the left side of the buffer before 
; resetting the display to show the left (default) position.
;
; Set memset address
; Set Memset Length
; Call Memset.
; --------------------------------------------------------------------------

Gfx_ClearOptionsLeftBuffer

	mMemset GFX_OPTION_LEFT,20,INTERNAL_BLANKSPACE

	mMemset GFX_OPTION_TEXT_LEFT,40,CHAR_MODE2_BLANK

	rts

; ==========================================================================
; COPY OPTION RIGHT TO LEFT BUFFER
; ==========================================================================
; Set memcpy addresses
; Set Memcpy Length
; Call Memcpy.
; --------------------------------------------------------------------------

Gfx_CopyOptionRightToLeftBuffer

	mMemcpy GFX_OPTION_LEFT,GFX_OPTION_RIGHT,20

	mMemcpy GFX_OPTION_TEXT_LEFT,GFX_OPTION_TEXT_RIGHT,40

	rts


; ==========================================================================
; COPY OPTION TO RIGHT BUFFER
; ==========================================================================
; Used to load up graphics with the text for the new menu item 
; to begin scrolling.
;
; X is an index to a word (address) in the arrays of pointers 
; to the menu texts.
;
; Save X.
; Get Address for Mode 6 text.
; Copy text.
; Using X again, get address for mode 2 text.
; Copy text.
; 
; Turn on flag to tel VBI to run scrolling.
; --------------------------------------------------------------------------

g_cotrb_tempX .byte 0

Gfx_CopyOptionToRightBuffer

	stx g_cotrb_tempX

	lda TABLE_OPTIONS_LO,X
	sta gCurrentMenuText
	lda TABLE_OPTIONS_HI,X
	sta gCurrentMenuText+1

	mMemcpyM GFX_OPTION_RIGHT,gCurrentMenuText,20

	clc
	lda gCurrentMenuText
	adc #20
	sta gCurrentMenuText
	bcc b_gcotrb_SkipTextHighByte
	inc gCurrentMenuText+1
b_gcotrb_SkipTextHighByte

	ldx g_cotrb_tempX

;	lda TABLE_OPTIONS_TEXT_LO,X
;	sta gCurrentMenuText
;	lda TABLE_OPTIONS_TEXT_HI,X
;	sta gCurrentMenuText+1

	mMemcpyM GFX_OPTION_TEXT_RIGHT,gCurrentMenuText,40
	
	lda #1               ; We're here to setup text for scrolling,
	sta gOSS_ScrollState ;  so turn on scrolling.

	rts


; ==========================================================================
; DISPLAY ON/OFF TEXT
; ==========================================================================
; Display ON or Off indication for the current feature FROM A SELECT 
; MENU ENTRY.  (OPTION entries do not have an ON/OFF)
;
; Processor status indicates if the entry state is on or off.
; Z = ON, !Z = OFF
;
; X register provides offset for location into either the left side 
; or the right side of the scroll buffer. 
;
; The Left buffer is where updates appear when the START key is pressed.
; The Right buffer  is where the on/off state appears in the string 
; that is going to be scrolled on screen.
;
; This should be called directly after a "GET" operation to acquire
; the on/off state of the given option.
;
;	.sb "  OPTION "     ; 10        ; White
;	.sb +$40,"TEXT "    ; 5         ; Green
;	.sb +$80,"HERE  "   ; 6 == 20   ; Red
;
; X register is left or right offset position.
; A indicates ON (0)  or OFF (1).  (This should also be the Z flag.) 
; --------------------------------------------------------------------------

Gfx_Display_OnOff_Option

	bne b_gdooo_Do_Off ; Foolishly trust that lda occurred right before this.

	; Display the text for "ON" in green.
	
	lda #INTERNAL_BLANKSPACE
	sta GFX_OPTION_LEFT,X
	
	lda #[CSET_MODE67_COLPF1|INTERNAL_UPPER_O]
	sta GFX_OPTION_LEFT+1,X
	
	lda #[CSET_MODE67_COLPF1|INTERNAL_UPPER_N]
	sta GFX_OPTION_LEFT+2,X

	rts

b_gdooo_Do_Off
	lda #[CSET_MODE67_COLPF2|INTERNAL_UPPER_O]
	sta GFX_OPTION_LEFT,X

	lda #[CSET_MODE67_COLPF2|INTERNAL_UPPER_F]
	sta GFX_OPTION_LEFT+1,X

;	lda #[CSET_MODE67_COLPF2|INTERNAL_UPPER_F]
	sta GFX_OPTION_LEFT+2,X

	rts


; ==========================================================================
; SCROLL OSS TEXT
; ==========================================================================
; Called by the VBI after it tested the scrolling is active.
;
; Move the Option menu line (Mode 6) and the Option Description 
; line (Mode 2) by coarse scrolling the LMS in the display list.
;
; Since the Mode 2 line has more characters it continues to scroll 
; after the Mode 6 line is done.
;
; When BOTH lines are done, then the routine turns off the scrolling 
; indicator and starts the visual countdown timer.  
; The timer is restarted for any valid console key input.
; (When the timer does expire the menu option will be removed 
; from the screen.)
;
; When scrolling ends, Scroll flag is changed to -1 to signal to the 
; main code to copy the right buffer to the left and reset the 
; scroll lines back to the origins (the left side buffer.) 
;
; Exit conditions:
; Negative Flag On  (BMI) == scrolling stopped this frame
; Negative Flag Off (BPL) == scrolling still in progress. 
; --------------------------------------------------------------------------

Gfx_ScrollOSSText

	lda DL_LMS_OPTION           ; Get the LMS pointing to the Option text
	cmp #<GFX_OPTION_RIGHT      ; Has it reached the right side?
	beq b_gsot_CheckOptionText  ; Yes. No more motion for this line
	inc DL_LMS_OPTION           ; Nope.  Shift line one character.

	; Same scroll for Option Text which is 40 characters.
b_gsot_CheckOptionText
	lda DL_LMS_OPTION_TEXT      ; Text is 40 character so it could still be moving.
	cmp #<GFX_OPTION_TEXT_RIGHT ; Has it reached right side?
	beq b_gsot_SetOptionWait    ; Yes. Set flags for main code.  Turn on wait timer.
	inc DL_LMS_OPTION_TEXT      ; Nope.   Shift line one character.
	bne b_gsot_End              ; Always skip to end when still scrolling.

	; Scrolling has just ended.  Set some flags.
b_gsot_SetOptionWait
	lda #$FF
	sta gOSS_ScrollState        ; Turn off scrolling, flag that main should reset text.
	jsr RestartMenutasticTimer  ; Set jiffy wait timer for menu display.

b_gsot_End
	rts


; ==========================================================================
; RESET OSS TEXT
; ==========================================================================
; Called by the MAIN code after scrolling is finished.
;
; Copies the right buffers to the left buffers and resets the Display 
; List LMS to point to the left buffers.
;
; Also turns off the End Of Scrolling flag (gOSS_ScrollState == -1)
; and updates it to 0 indicating no scrolling motion. 
; --------------------------------------------------------------------------

Gfx_ResetOSSText

	jsr Gfx_CopyOptionRightToLeftBuffer 

	jsr Gfx_SetLeftOSSText      ; Force LMS to point to left buffer.

	lda #$00
	sta gOSS_ScrollState        ; Officially scrolling is now off.

	rts


; ==========================================================================
; SET LEFT OSS TEXT
; ==========================================================================
; Forced LMS to point to the left buffers.
;
; Made into a routine, because it is needed at different times.
; --------------------------------------------------------------------------

Gfx_SetLeftOSSText

	lda #<GFX_OPTION_LEFT       ; Set the LMS pointing to the Option text
	sta DL_LMS_OPTION           

	lda  #<GFX_OPTION_TEXT_LEFT ; Set the LMS pointing to the Option description text
	sta DL_LMS_OPTION_TEXT 

	rts


; ==========================================================================
; CLEAR OSS TEXT
; ==========================================================================
; Called by the MAIN code to init scroll lines, and to clear lines 
; when the timer says the option menu has to go away.
;
; Zero the entire text buffer and description text lines. 
; Reset the LMS to the left buffers.
; Clear the scroll flags.
;
; Note the Title Screen Init must also set values for:
; gOSS_Mode         ; ; 0 is Off.  -1 option menu.  +1 is select menu.
; gOSS_Timer        ; Timer until removing text.
; gCurrentOption    ; Last Option Menu used. 
; gCurrentMenuEntry ; Menu entry number for Option and Select.
; --------------------------------------------------------------------------

Gfx_ClearOSSText

	lda #INTERNAL_BLANKSPACE        ; Clear the Option menu
	ldx #19
b_gcot_ClearOption_Loop
	sta GFX_OPTION_LEFT,X
	sta GFX_OPTION_RIGHT,X
	dex
	bpl b_gcot_ClearOption_Loop

;	lda #INTERNAL_AT                ; Clear the Option Description line.
	ldx #39
b_gcot_ClearOptionText_Loop
	sta GFX_OPTION_TEXT_LEFT,X
	sta GFX_OPTION_TEXT_RIGHT,X
	dex
	bpl b_gcot_ClearOptionText_Loop

	jsr Gfx_SetLeftOSSText          ; Force LMS to point to the left buffers.
    
	lda #$00
	sta gOSS_ScrollState            ; Officially scrolling is now off.
	sta gOSS_Mode                   ; And the mode says no men u is displayed
	
	rts



MENU_DONOTHING  = 0 ; ID for generic library to do nothing, but will return Z flag (BEQ)
MENU_DOONETHING = 1 ; ID for generic library to do nothing, but will return !Z flag (BNE)
MENU_SETVALUE   = 2 ; ID for generic library function to set config value to current menu item
MENU_SETTOGGLE  = 3 ; ID for generic library function to flip a value between 2 values
MENU_GETITEM    = 4 ; ID for generic library function to report if config variable matches current menu item
MENU_GETTOGGLE  = 5 ; ID for generic library function to report if toggle is set on or off. 
MENU_ONDISPLAY  = 6 ; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.




