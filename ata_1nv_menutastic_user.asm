;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2022 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; MENUTASTIC USER
; ==========================================================================
; 
; User data for operating Menus used for choosing configuration.
;
; --------------------------------------------------------------------------


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

; ==========================================================================
; Declare all the User's variables....
;
; MENU_* values are enumerated IDs for standard library functions.
; --------------------------------------------------------------------------
;
; MENU_DONOTHING  = 0 ; ID for generic library to do nothing, but 
;                       will return Z flag (BEQ)
; MENU_DOONETHING = 1 ; ID for generic library to do nothing, but 
;                       will return !Z flag (BNE)
; MENU_SETVALUE   = 2 ; ID for generic library function to set config 
;                       value to current menu item
; MENU_SETTOGGLE  = 3 ; ID for generic library function to flip a value 
;                       between 0 and 1
; MENU_GETITEM    = 4 ; ID for generic library function to report if 
;                       config variable matches current menu item
; MENU_GETTOGGLE  = 5 ; ID for generic library function to report if 
;                       toggle is set on or off. 
; MENU_ONDISPLAY  = 6 ; ID for gfx function to display ON/OFF for value 
;                       based on result of MENU_GET results.
; --------------------------------------------------------------------------


; ==========================================================================
TABLE_CONFIG_VARIABLES  ; see menutastic.asm for structure description.
; ==========================================================================

CONFIG_VARIABLE_VALUE     = [TABLE_CONFIG_VARIABLES+CONFIG_VAR_VALUE]
CONFIG_VARIABLE_DEFAULT   = [TABLE_CONFIG_VARIABLES+CONFIG_VAR_DEFAULT]
CONFIG_VARIABLE_SETVALUE  = [TABLE_CONFIG_VARIABLES+CONFIG_VAR_SETVALUE]
CONFIG_VARIABLE_CMPVALUE  = [TABLE_CONFIG_VARIABLES+CONFIG_VAR_CMPVALUE]
CONFIG_VARIABLE_ONDISPLAY = [TABLE_CONFIG_VARIABLES+CONFIG_VAR_ONDISPLAY]

CONFIG_VARIABLE_FUNC_HI   = [TABLE_CONFIG_VARIABLES+1] ; goofiness for function retrieval

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
	.byte 12                  ; Value
	.byte 12                  ; Default (12 * speed option) -- 0, 12, 24
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
	.word MENU_SETTOGGLE      ; Set variable to menu item.
	.word MENU_GETTOGGLE      ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.

CONFG_SETALLDEFAULTS = 56     ; entry occurrence * sizeof structure

gConfigSetAllDefaults         ; A variable is still needed for the custom Set code.
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word CustomSetDefaults-1 ; Set variable to menu item. 
	.word MENU_DONOTHING      ; Compare variable to current menu item.
	.word MENU_DONOTHING      ; Update graphics asset with ON/OFF based on GETITEM results. 

CONFG_CHEATMODE = 64          ; entry occurrence * sizeof structure

gConfigCheatMode         
	.byte $00                 ; Value
	.byte $00                 ; Default
	.word MENU_SETTOGGLE      ; Set variable to menu item.  
	.word MENU_GETTOGGLE      ; Compare variable to current menu item.
	.word MENU_ONDISPLAY      ; Update graphics asset with ON/OFF based on GETITEM results.



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
	.sb "SLOW LASERS         "
GFX_MENU_2_1_TEXT
	.sb +$40,"PAINFULLY@SLOW@LASERS@@@@@@@@@@@@@@@@@@@"
	
GFX_MENU_2_2                 
	.sb "REGULAR LASERS      "
GFX_MENU_2_2_TEXT
	.sb +$40,"THE@NORMAL@DEFAULT@SPEED@FOR@LASERS@@@@@"

GFX_MENU_2_3 
	.sb "FAST LASERS         "
GFX_MENU_2_3_TEXT
	.sb +$40,"FASTER@LASERS@MAY@NOT@HELP@SO@MUCH@@@@@@"




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

; Here list the Variable that each SELECT menu item uses.  The variable
; is specified by it's ID defined with TABLE_CONFIG_VARIABLES.
; 
; Note that the OPTION entries do have to be represented to maintain 
; consistent SELECT item arrays.

; ==========================================================================
TABLE_MENU_CONFIG_VARIABLES
; ==========================================================================
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
	.byte CONFIG_LASERRESTART      ; 12  Short Laser Manual Restart
	.byte CONFIG_LASERRESTART      ; 13  Long Laser Manual Restart
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



; ==========================================================================
; 
; Here list the actual value that would be assigned to the Variable
; when the START button is pressed for the SELECT menu item.
;
; Note that the OPTION entries do have to be represented to maintain 
; consistent SELECT item arrays.
;
; Data/Value/Flag passed to routines to set the value or match the current value.

; ==========================================================================
TABLE_OPTION_ARGUMENTS
; ==========================================================================
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
	.byte 0   ; gConfigLaserSpeed        ; 15  Slow laser speed (-2) 
	.byte 12  ; gConfigLaserSpeed        ; 16  Regular laser speed (Default) 
	.byte 24  ; gConfigLaserSpeed        ; 17  Fast laser speed (+2)
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


; ==========================================================================
; Control path -- Where to go from OPTION menu when SELECT is pressed...
; 
; Indexed by current OPTION counter.

; ==========================================================================
TABLE_OPTIONS_SELECTMENUS
; ==========================================================================
	.byte 8  ; 8  SELECT Laser Restart Menu
	.byte 15 ; 15 SELECT Laser Speed Menu
	.byte 19 ; 19 SELECT 1NVADER Startup Menu
	.byte 25 ; 25 SELECT 1NVADER Speedup Menu
	.byte 32 ; 32 SELECT 1NVADER Max Speed Menu
	.byte 37 ; 37 SELECT Two Player Modes Menu
	.byte 42 ; 42 SELECT Other things Menu
	.byte 0  ; Go back to first menu.



; ==========================================================================
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

; ==========================================================================
TABLE_OPTIONS_LO
; ==========================================================================
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
	.byte <GFX_MENU_1_5 ; 12  Short Laser Manual Restart
	.byte <GFX_MENU_1_6 ; 13  Long Laser Manual Restart
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


; ==========================================================================
TABLE_OPTIONS_HI
; ==========================================================================
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
	.byte >GFX_MENU_1_5 ; 12  Short Laser Manual Restart
	.byte >GFX_MENU_1_6 ; 13  Long Laser Manual Restart
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
;                                                    CUSTOM SET DEFAULTS
; ==========================================================================
; Set all variables to their default values.
;
; Loop through array entries and copy the default value to the 
; variable value.
;
; Also, Strobe background color to 
; --------------------------------------------------------------------------

CustomSetDefaults

	lda #[COLOR_GREEN|$E]         ; Flash background this frame
	sta COLBK

	ldy #CONFIG_LASERRESTART      ; Index to first variable.

b_csd_CopyDefaultToVariable
	lda CONFIG_VARIABLE_DEFAULT,y ; Copy default value
	sta CONFIG_VARIABLE_VALUE,y   ; to variable.

	cpy #CONFG_CHEATMODE          ; Last variable.
	beq b_csd_Exit

	tya                           ; A = Y (index to config variable)
	clc
	adc #SIZEOF_CONFIG_VARIABLE   ; Add size of config variable structure
	tay                           ; Y = A (indes to next config variable structure)
	bne b_csd_CopyDefaultToVariable

b_csd_Exit

	rts

