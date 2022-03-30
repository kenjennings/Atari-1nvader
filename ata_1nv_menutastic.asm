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
; MENUTASTIC - ENUMERATE STANDARD FUNCTIONS
; ==========================================================================

MENU_SETVALUE  = 0 ; ID for generic library function to set config value to current menu item
MENU_SETTOGGLE = 1 ; ID for generic library function to flip a value between 2 values
MENU_GETITEM   = 2 ; ID for generic library function to report if config variable matches current menu item
MENU_GETTOGGLE = 3 ; ID for generic library function to report if toggle is set on or off. 
MENU_ONDISPLAY = 4 ; ID for gfx function to display ON/OFF for value based on result of MENU_GET results.


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


; Declare all the variables....

TABLE_CONFIG_VARIABLES

CONFIG_LASERRESTART = 0  ; offset into this list of declared structures below.

gConfigLaserRestart
	.byte $00            ; Value
	.byte $00            ; Default
	.word MENU_SETVALUE  ; Set variable to menu item.
	.word MENU_GETITEM   ; Compare variable to current menu item.
	.word MENU_ONDISPLAY ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_LASERSPEED = 8    ; entry occurrence * sizeof structure

gConfigLaserSpeed        
	.byte $00            ; Value
	.byte $00            ; Default
	.word MENU_SETVALUE  ; Set variable to menu item.
	.word MENU_GETITEM   ; Compare variable to current menu item.
	.word MENU_ONDISPLAY ; Update graphics asset with ON/OFF based on GETITEM results.

CONFIG_1NVADERSTARTSPEED = 16 ; entry occurrence * sizeof structure

gConfig1nvaderStartSpeed 
	.byte $01            ; Value
	.byte $01            ; Default
	.word MENU_SETVALUE  ; Set variable to menu item.
	.word MENU_GETITEM   ; Compare variable to current menu item.
	.word MENU_ONDISPLAY ; Update graphics asset with ON/OFF based on GETITEM results.

gConfig1nvaderHitCounter .byte 10

gConfig1nvaderMaxSpeed   .byte 9

gConfigTwoPlayerMode     .byte $00

gConfigOnesieMode        .byte $00 ; Toggle on/off

gConfigSetAllDefaults    .byte $00 ; A variable still needed for the custom Set code.

gConfigCheatMode         .byte $00 

