;*******************************************************************************
;*
;* C64 1NVADER - 2019 Darren Foulds
;*
;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2023 Ken Jennings
;*                                                                             
;*******************************************************************************

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

	icl "ata_1nv_lib.asm"   ; Very Common Reusable Code
; --------------------------------------------------------------------------

; ==========================================================================
; Include all the code and graphics data parts . . .

	icl "ata_1nv_gfx.asm"             ; Data for Display Lists and Screen Memory (2K)

	icl "ata_1nv_gfx_color.asm"       ; Data for NTSC/PAL color values

	icl "ata_1nv_cset.asm"            ; Data for custom character set (1K space)

	icl "ata_1nv_pmg.asm"             ; Data for Player/Missile graphics (and reserve the 2K bitmap).


	icl "ata_1nv_gfx_code.asm"        ; Routines for manipulating screen graphics.

	icl "ata_1nv_pmg_code.asm"        ; Routines for Player/Missile graphics animation.


	icl "ata_1nv_int.asm"             ; Code for I/O, Display List Interrupts, and Vertical Blank Interrupt.

	icl "ata_1nv_audio.asm"           ; The world's lamest sound sequencer.

	icl "ata_1nv_support.asm"         ; The bulk of the game logic code.

	icl "ata_1nv_menutastic_user.asm" ; The user's data (and code) 

	icl "ata_1nv_menutastic.asm"      ; The library code for the menus.



	icl "ata_1nv_game.asm"            ; Code for game event loop.

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

