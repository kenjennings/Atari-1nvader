;*******************************************************************************
;*
;* C64 1NVADER - 2019 Darren Foulds
;*
;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2022 Ken Jennings                        
;*                                                                             
;*******************************************************************************

; ==========================================================================
; 1NVADER AUDIO
;
; All the routines to run "The world's cheapest sequencer." 
;
; It is a truly sad thing.
;
; Game sound allocation:
;             Title           Game                 Win/Dead/Over       Other
;----------   ------------    -----------------    -------------       -----------
; Channel 0 - slide, hum A    
; Channel 1 - downs ,hum B    engines
; Channel 2 - lefts           jump, 100pt ding     OdeToJoy            button tink
; Channel 3 - Rezz slide      water                OdeToJoy, Funeral
; --------------------------------------------------------------------------

SOUND_OFF     = 0
SOUND_TINK    = 1
SOUND_SLIDE   = 2
SOUND_HUM_A   = 3
SOUND_HUM_B   = 4
SOUND_DIRGE   = 5
SOUND_THUMP   = 6
SOUND_JOY     = 7
SOUND_WATER   = 8
SOUND_ENGINES = 9
SOUND_BLING   = 10 
SOUND_DOWNS   = 11
SOUND_LEFTS   = 12

SOUND_MAX     = 12

; ======== The world's most inept sound system. ========
;
; The world's cheapest sequencer. For each audio channel play one sound 
; value from a table at each call. Assuming this is done synchronized to 
; the frame it performs a sound change every 16.6ms (at NTSC 60fps)
;
; Sequencer control values for each voice are in Page 0.... (18 bytes total)
;
;; Pointer used by the VBI service routine for the current sequence under work:
; SOUND_POINTER .word $0000
;
;; Pointers to the sound entry in use for each voice.
; SOUND_FX_LO
; SOUND_FX_LO0 .byte 0
; SOUND_FX_LO1 .byte 0
; SOUND_FX_LO2 .byte 0
; SOUND_FX_LO3 .byte 0 

; SOUND_FX_HI
; SOUND_FX_HI0 .byte 0
; SOUND_FX_HI1 .byte 0
; SOUND_FX_HI2 .byte 0
; SOUND_FX_HI3 .byte 0 

; Sound Control values coordinate between the main process and the VBI 
; service routine to turn on/off/play sounds. Control Values:
; 0   = Set by Main to direct VBI to stop managing sound pending an 
;       update from MAIN. This does not stop the POKEY's currently 
;       playing sound.  It is set by the VBI when a sequence is complete 
;       to indicate the channel is idle/unmanaged. 
; 1   = MAIN sets to direct VBI to start playing a new sound FX.
; 2   = VBI sets when it is playing to inform MAIN that it has taken 
;       direction and is now busy.
; 255 = Direct VBI to silence the channel immediately.
;
; So, the procedure for playing sound.
; 1) MAIN sets the channel's SOUND_CONTROL to 0.
; 2) MAIN sets the channel's SOUND_FX_LO/HI pointer to the sound effects 
;    sequence to play.
; 3) MAIN sets the channel's SOUND_CONTROL to 1 to tell VBI to start.
; 4) VBI sets the channel's SOUND_CONTROL value to 2 when playing, then 
;    when the sequence is complete, back to value 0.

; SOUND_CONTROL
; SOUND_CONTROL0  .byte $00
; SOUND_CONTROL1  .byte $00
; SOUND_CONTROL2  .byte $00
; SOUND_CONTROL3  .byte $00

; When these are non-zero, the current settings continue for the next frame.
; SOUND_DURATION
; SOUND_DURATION0 .byte $00
; SOUND_DURATION1 .byte $00
; SOUND_DURATION2 .byte $00
; SOUND_DURATION3 .byte $00

; ======================================================


	.align 4


; A sound Entry is 4 bytes...
; byte 0, AUDC (distortion/volume) value
; byte 1, AUDF (frequency) value
; byte 2, Duration, number of frames to count. 0 counts as 1 frame.
; byte 3, 0 == End of sequence. Stop playing sound. (Set AUDF and AUDC to 0)
;         1 == Continue normal playing.
;       255 == End of sequence. Do not stop POKEY playing current sound.
;       Eventually some other magic to be determined goes here.
; Like this:
;	.byte Distortion/volume, Frequency, Frame/Duration, Control


SOUND_ENTRY_OFF   ; A formality, so that 0 has consistent meaning.
	.byte 0,0,0,0


SOUND_ENTRY_TINK ; Press A Button.
	.byte $A6,120,2,1
	.byte $A5,120,1,1
	.byte $A4,120,1,1
	.byte $A3,120,0,1
	.byte $A2,120,0,1
	.byte $A1,120,0,1

	.byte $A0,0,0,0


SOUND_ENTRY_BLING ; Press A Button.
	.byte $Aa,25,1,1
	.byte $A8,25,1,1
	.byte $A6,25,1,1
	.byte $A4,25,1,1
	.byte $A1,25,1,1
	.byte $A0,0,3,1

	.byte $A0,0,0,0


	; Maybe if I thought about it for a while I could do a 
	; ramp/counting feature in the sound entry control byte 
	; in less than 100-ish bytes of code which is about how 
	; much space this table occupies. 
SOUND_ENTRY_SLIDE    ; Title logo lines slide right to left
	.byte $02,50,1,1 ; 1 == 2 frames per wait.
	.byte $03,49,1,1
	.byte $03,48,1,1
	.byte $04,47,1,1
	.byte $04,46,1,1
	.byte $05,45,1,1
	.byte $05,44,1,1
	.byte $06,43,1,1
	.byte $06,42,1,1
	.byte $07,41,1,1
	.byte $07,40,1,1
	.byte $08,39,1,1
	.byte $08,38,1,1
	.byte $09,37,1,1
	.byte $09,36,1,1
	.byte $0a,35,1,1
	.byte $0a,34,1,1
	.byte $0b,33,1,1
	.byte $0b,32,1,1
	.byte $0c,31,1,1
	.byte $0c,30,1,1
	.byte $0d,29,1,1
	.byte $0d,28,1,1
	.byte $0d,27,1,1
	.byte $0d,26,1,1
	.byte $0d,25,1,1
	.byte $0e,24,1,1
	.byte $0e,23,1,1
	.byte $0e,22,1,1
	.byte $0e,21,1,1
	.byte $0e,20,1,1
	.byte $0e,19,1,1
	.byte $0e,18,1,1
	.byte $0e,17,1,1
	.byte $0e,16,1,1
	.byte $0e,15,1,1
	.byte $0e,14,1,1
	.byte $0e,13,1,1

	.byte $00,$00,0,0


SOUND_ENTRY_HUMMER_A ; one-half of Atari light saber
	.byte $A9,$FF,30,1
	.byte $A8,$FF,7,1
	.byte $A7,$FF,7,1
	.byte $A6,$FF,7,1
	.byte $A5,$FF,7,1
	.byte $A3,$FF,7,1
	.byte $A1,$FF,7,1

	.byte $A0,0,0,0


SOUND_ENTRY_HUMMER_B ; other-half of Atari light saber
	.byte $A8,$FE,30,1
	.byte $A8,$FE,7,1
	.byte $A7,$FE,7,1
	.byte $A6,$FE,7,1
	.byte $A5,$FE,7,1
	.byte $A3,$FE,7,1
	.byte $A1,$FE,7,1

	.byte $A0,0,0,0


SOUND_ENTRY_DIRGE     ; Chopin's Funeral for a frog (or a gunslinger in Outlaw) 
;	.byte $A4,182,0,1 ; F, 1/4, 16 steps
;	.byte $A6,182,13,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 
;	.byte $A4,182,0,1 ; F, 1/8 ., 12 steps
;	.byte $A6,182,9,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 
;	.byte $A4,182,0,1 ; F, 1/16,  4 steps
;	.byte $A6,182,0,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 
;	.byte $A4,182,0,1 ; F, 1/2, 32 steps
;	.byte $A6,182,29,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 

;	.byte $A4,182,0,1 ; F, 1/4, 16 steps
;	.byte $A6,182,13,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 
;	.byte $A4,182,0,1 ; F, 1/8 ., 12 steps
;	.byte $A6,182,9,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 
;	.byte $A4,182,0,1 ; F, 1/16,  4 steps
;	.byte $A6,182,0,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 
;	.byte $A4,182,0,1 ; F, 1/2, 32 steps
;	.byte $A6,182,29,1 
;	.byte $A4,182,0,1 
;	.byte $A2,182,0,1 

	.byte $A4,182,0,1 ; F, 1/4, 16 steps
	.byte $A6,182,13,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 
	.byte $A4,182,0,1 ; F, 1/8 ., 12 steps
	.byte $A6,182,9,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 
	.byte $A4,182,0,1 ; F, 1/16,  4 steps
	.byte $A6,182,0,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 
	.byte $A4,182,0,1 ; F, 1/4, 16 steps
	.byte $A6,182,13,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 
	.byte $A4,144,0,1 ; A, 1/8 ., 12 steps
	.byte $A6,144,9,1 
	.byte $A4,144,0,1 
	.byte $A2,144,0,1 
	.byte $A4,162,0,1 ; G, 1/16,  4 steps
	.byte $A6,162,0,1 
	.byte $A4,162,0,1 
	.byte $A2,162,0,1 

	.byte $A4,162,0,1 ; G, 1/8 ., 12 steps
	.byte $A6,162,9,1 
	.byte $A4,162,0,1 
	.byte $A2,162,0,1 
	.byte $A4,182,0,1 ; F, 1/16,  4 steps
	.byte $A6,182,0,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 
	.byte $A4,182,0,1 ; F, 1/8 ., 12 steps
	.byte $A6,182,9,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 
	.byte $A4,182,0,1 ; F, 1/16,  4 steps
	.byte $A6,182,0,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 
	.byte $A4,182,0,1 ; F, 1/2,  32 steps
	.byte $A6,182,29,1 
	.byte $A4,182,0,1 
	.byte $A2,182,0,1 

	.byte $A0,$00,0,0


SOUND_ENTRY_THUMP     ; When a frog moves
	.byte $A2,240,0,1 
	.byte $A5,240,0,1 
	.byte $A8,240,2,1 
	.byte $A4,240,0,1 
	.byte $A1,240,0,1 

	.byte $A0,$00,0,0


SOUND_ENTRY_ODE2JOY ; Beethoven's Ode To Joy when a frog is saved 
	.byte $Aa,121,0,1 ; C, 1/4, 10 steps
	.byte $A8,121,6,1 
	.byte $A5,121,0,1 
	.byte $A3,121,0,1 
	.byte $A1,121,0,1 
	.byte $Aa,121,0,1 ; C, 1/4, 10 steps
	.byte $A8,121,6,1 
	.byte $A5,121,0,1 
	.byte $A3,121,0,1 
	.byte $A1,121,0,1 
	.byte $Aa,108,0,1 ; D, 1/4, 10 steps
	.byte $A8,108,6,1 
	.byte $A5,108,0,1 
	.byte $A3,108,0,1 
	.byte $A2,108,0,1 
	.byte $Aa,96,0,1 ; E, 1/4, 10 steps
	.byte $A8,96,6,1 
	.byte $A5,96,0,1 
	.byte $A3,96,0,1 
	.byte $A1,96,0,1 

	.byte $Aa,96,0,1 ; E, 1/4, 10 steps
	.byte $A8,96,6,1 
	.byte $A5,96,0,1 
	.byte $A3,96,0,1 
	.byte $A1,96,0,1 
	.byte $Aa,108,0,1 ; D, 1/4, 10 steps
	.byte $A8,108,6,1 
	.byte $A5,108,0,1 
	.byte $A3,108,0,1 
	.byte $A1,108,0,1 
	.byte $Aa,121,0,1 ; C, 1/4, 10 steps
	.byte $A8,121,6,1 
	.byte $A5,121,0,1 
	.byte $A3,121,0,1 
	.byte $A1,121,0,1 
	.byte $Aa,128,0,1 ; B, 1/4, 10 steps
	.byte $A8,128,6,1 
	.byte $A5,128,0,1 
	.byte $A3,128,0,1 
	.byte $A1,128,0,1 

	.byte $Aa,144,0,1 ; A, 1/4, 10 steps
	.byte $A8,144,6,1 
	.byte $A5,144,0,1 
	.byte $A3,144,0,1 
	.byte $A1,144,0,1 
	.byte $Aa,144,0,1 ; A, 1/4, 10 steps
	.byte $A8,144,6,1 
	.byte $A5,144,0,1 
	.byte $A3,144,0,1 
	.byte $A1,144,0,1 
	.byte $Aa,128,0,1 ; B, 1/4, 10 steps
	.byte $A8,128,6,1 
	.byte $A5,128,0,1 
	.byte $A3,128,0,1 
	.byte $A1,128,0,1 
	.byte $Aa,121,0,1 ; C, 1/4, 10 steps
	.byte $A8,121,6,1 
	.byte $A5,121,0,1 
	.byte $A3,121,0,1 
	.byte $A1,121,0,1 

	.byte $Aa,121,0,1 ; C, 1/4 ., 15 steps
	.byte $A8,121,11,1 
	.byte $A5,121,0,1 
	.byte $A3,121,0,1 
	.byte $A1,121,0,1 
	.byte $Aa,128,0,1 ; B, 1/8, 5 steps
	.byte $A8,128,0,1 
	.byte $A5,128,0,1 
	.byte $A3,128,0,1 
	.byte $A1,128,0,1 
	.byte $Aa,128,0,1 ; B, 1/4, 20 steps
	.byte $A8,128,16,1 
	.byte $A5,128,0,1 
	.byte $A3,128,0,1 
	.byte $A1,128,0,1 

	.byte $A0,$00,0,0


SOUND_ENTRY_WATER    ; Water sloshing noises
	.byte $81,1,75,1 ; several full seconds 
	.byte $81,2,75,1 ; of different sounds 
	.byte $81,3,75,1 ; at different volumes.
	.byte $81,4,75,1
	.byte $81,5,75,1

	.byte $81,2,75,255 ; End.  Do not stop sound.


SOUND_ENTRY_ENGINES    ; Engine sounds noises
	.byte $C5,231,75,1 ; several full seconds 
	.byte $C4,220,75,1 ; of different sounds 
	.byte $C5,255,75,1 ; at different volumes.
	.byte $C4,243,75,1
	.byte $C5,198,75,1

	.byte $C4,211,75,255 ; End.  Do not stop sound.


SOUND_ENTRY_DOWNS   ; title graphics shift down.
	.byte $04,4,4,1 
	.byte $04,3,4,1 
	.byte $03,2,4,1 
	.byte $03,1,4,1 
	.byte $02,0,4,1 

	.byte $00,$00,0,0


SOUND_ENTRY_LEFTS
	.byte $a1,21,2,1 
	.byte $a1,20,2,1 
	.byte $a1,19,2,1 
	.byte $a1,18,2,1 
	.byte $a1,17,2,1 
	.byte $a1,16,2,1 
	.byte $a1,15,2,1 
	.byte $a1,14,2,1 
	.byte $a1,13,2,1 
	.byte $a1,12,2,1 
	.byte $a1,11,2,1 
	.byte $a1,10,2,1 
	.byte $a1,9,2,1 
	.byte $a1,8,2,1 
	.byte $a1,7,2,1 
	.byte $a1,6,2,1 
	.byte $a1,5,2,1 
	.byte $a1,4,2,1 
	.byte $a1,3,2,1 
	.byte $a1,2,2,1 
	.byte $a1,1,2,1 
	.byte $a1,0,2,1 

	.byte $00,$00,0,0


; Pointers to starting sound entry in a sequence.
SOUND_FX_LO_TABLE
	.byte <SOUND_ENTRY_OFF
	.byte <SOUND_ENTRY_TINK
	.byte <SOUND_ENTRY_SLIDE
	.byte <SOUND_ENTRY_HUMMER_A
	.byte <SOUND_ENTRY_HUMMER_B
	.byte <SOUND_ENTRY_DIRGE
	.byte <SOUND_ENTRY_THUMP
	.byte <SOUND_ENTRY_ODE2JOY
	.byte <SOUND_ENTRY_WATER
	.byte <SOUND_ENTRY_ENGINES
	.byte <SOUND_ENTRY_BLING
	.byte <SOUND_ENTRY_DOWNS
	.byte <SOUND_ENTRY_LEFTS


SOUND_FX_HI_TABLE
	.byte >SOUND_ENTRY_OFF
	.byte >SOUND_ENTRY_TINK
	.byte >SOUND_ENTRY_SLIDE
	.byte >SOUND_ENTRY_HUMMER_A
	.byte >SOUND_ENTRY_HUMMER_B
	.byte >SOUND_ENTRY_DIRGE
	.byte >SOUND_ENTRY_THUMP
	.byte >SOUND_ENTRY_ODE2JOY
	.byte >SOUND_ENTRY_WATER
	.byte >SOUND_ENTRY_ENGINES
	.byte >SOUND_ENTRY_BLING
	.byte >SOUND_ENTRY_DOWNS
	.byte >SOUND_ENTRY_LEFTS


; ==========================================================================
; ToPlayFXScrollOrNot                                             A  X  Y
; -------------------------------------------------------------------------- 
; Decide to start playing the slide sound or not.
; 
; The duration of the slide on screen should be the same(ish) as the 
; length of the sound playing.  Therefore the sound should run out at the
; same time the slide finishes (more or less)    
; 
; Uses all the registers. 
; X = sound channel to assign.
; Y = sound number to use. (values declared at beginning of Audio.asm.) 
; --------------------------------------------------------------------------

ToPlayFXScrollOrNot

	lda SOUND_CONTROL3      ; Is channel 3 busy?
	bne ExitToPlayFXScroll  ; Yes.  Don't do anything.

	ldx #3                  ; Setup channel 3 to play slide sound.
	ldy #SOUND_SLIDE
	jsr SetSound 

ExitToPlayFXScroll
	rts


; ==========================================================================
; ToReplayFXWaterOrNot                                             A  X  Y
; -------------------------------------------------------------------------- 
; To Replay water effects or not
; 
; Main routine to play the Water sounds during the game. 
; This checks the channel 3 control to see if it is idle.  
; If the channel is idle then the water effects sound sequence is restarted.
;
; Water is a series of long duration white noise/hissing sounds. 
; 
; Uses all the registers. 
; X = sound channel to assign.
; Y = sound number to use. (values declared at beginning of Audio.asm.) 
; --------------------------------------------------------------------------

ToReplayFXWaterOrNot

	lda SOUND_CONTROL3      ; Is channel 3 busy?
	bne ExitPlayWaterFX     ; Yes.  Don't do anything.

PlayWaterFX
	ldx #3                  ; Setup channel 3 to play water noises
	ldy #SOUND_WATER
	jsr SetSound

ExitPlayWaterFX
	rts


; ==========================================================================
; ToReplayFXEnginesOrNot                                           A  X  Y
; -------------------------------------------------------------------------- 
; To Replay engine noise effects or not
; 
; Main routine to play the Engine sounds during the game. 
; This checks the channel 1 control to see if it is idle.  
; If the channel is idle then the engines sound sequence is restarted.
;
; Engines are a series of long duration buzzing sounds. 
; 
; Uses all the registers. 
; X = sound channel to assign.
; Y = sound number to use. (values declared at beginning of Audio.asm.) 
; --------------------------------------------------------------------------

ToReplayFXEnginesOrNot

	lda SOUND_CONTROL1      ; Is channel 1 busy?
	bne ExitPlayEnginesFX   ; Yes.  Don't do anything.

PlayEnginesFX
	ldx #1                  ; Setup channel 1 to play water noises
	ldy #SOUND_ENGINES
	jsr SetSound

ExitPlayEnginesFX
	rts


; ==========================================================================
; PlayThump                                                      *  *  *
; -------------------------------------------------------------------------- 
; Play Thump for jumping frog
;
; Main routine uses this to play the frog movement sound. 
; This needs to be introduced where the main code is dependent on 
; the CPU flags for determining outcomes. Therefore, to prevent disrupting 
; the logic flow due to flag changes this routine is wrapped in the macros 
; to preserve/protect all registers to insure calling this routine has no 
; discernible effect on the Main code.
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlayThump

	mRegSave                   ; Macro: save CPU flags, and A, X, Y

	ldx #2                     ; Setup channel 2 to play frog bump.
	ldy #SOUND_THUMP
	jsr SetSound 

	mRegRestore                ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; PlayTink                                                       *  *  *
; -------------------------------------------------------------------------- 
; Play tink for button input
;
; Main routine uses this to play the feedback sound for button input.
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlayTink

	mRegSave                 ; Macro: save CPU flags, and A, X, Y

	ldx #2                   ; Button pressed. Set Pokey channel 2 to tink sound.
	ldy #SOUND_TINK
	jsr SetSound 

	mRegRestore              ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; PlayBling                                                      *  *  *
; -------------------------------------------------------------------------- 
; Play Bling for each 100 points awarded for saved frog
;
; Main routine uses this to play the bling sound for every 
; 100 points added to the score when a frog is saved. 
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlayBling

	mRegSave                   ; Macro: save CPU flags, and A, X, Y

	ldx #1                     ; Setup channel 1 to play ding a ling.
	ldy #SOUND_BLING
	jsr SetSound 

	mRegRestore                ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; PlayLefts                                                      *  *  *
; -------------------------------------------------------------------------- 
; Play Left movement sound for title graphics on OPTION and SELECT
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlayLefts

	mRegSave                   ; Macro: save CPU flags, and A, X, Y

	ldx #2                     ; Setup channel 2 to play.
	ldy #SOUND_LEFTS
	jsr SetSound 

	mRegRestore                ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; PlayDowns                                                      *  *  *
; -------------------------------------------------------------------------- 
; Play down movement sound for title graphics on OPTION and SELECT
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlayDowns

	mRegSave                   ; Macro: save CPU flags, and A, X, Y

	ldx #1                     ; Setup channel 2 to play.
	ldy #SOUND_DOWNS
	jsr SetSound 

	mRegRestore                ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; PlaySaberHum                                                    *  *  *
; -------------------------------------------------------------------------- 
; Play light saber hum using two channels.
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlaySaberHum

	mRegSave                   ; Macro: save CPU flags, and A, X, Y

	ldx #0                     ; Setup channel 0 to play light saber A sound.
	ldy #SOUND_HUM_A
	jsr SetSound

	ldx #1                     ; Setup channel 1 to play light saber B sound.
	ldy #SOUND_HUM_B
	jsr SetSound 

	mRegRestore                ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; PlayOdeToJoy                                                    *  *  *
; -------------------------------------------------------------------------- 
; Play Ode To Joy for saving the frog.  Uses two channels, 2 and 3.
; The playback is offset by a frame for each voice to produce a 
; slight ringing, electric echo effect.
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlayOdeToJoy

	mRegSave                   ; Macro: save CPU flags, and A, X, Y

	ldx #3                  ; Setup channel 3 to play Ode To Joy for saving the frog.
	ldy #SOUND_JOY
	jsr SetSound 

	jsr libScreenWaitFrame  ; Wait for a frame.

	ldx #2                  ; Setup channel 2 to play Ode To Joy for saving the frog.
	ldy #SOUND_JOY
	jsr SetSound 

	mRegRestore                ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; PlayFuneral                                                    *  *  *
; -------------------------------------------------------------------------- 
; Play Funeral dirge when a frog dies. 
; 
; Uses A, X, Y, but preserves all registers on entry/exit.
; --------------------------------------------------------------------------

PlayFuneral

	mRegSave                   ; Macro: save CPU flags, and A, X, Y

	ldx #3                     ; Setup channel 3 to play funeral dirge for the dead frog.
	ldy #SOUND_DIRGE
	jsr SetSound 

	mRegRestore                ; Macro: Restore Y, X, A, and CPU flags

	rts


; ==========================================================================
; StopAllSound                                                      A  X 
; -------------------------------------------------------------------------- 
; Stop All Sound
;
; Main routine to stop all playing for all channels.
;
; Set the control for each channel to 255 to stop everything now.
; 
; Uses A, X
; X = sound channel to assign.
; --------------------------------------------------------------------------

StopAllSound

	ldx #3               ; Channel 3, 2, 1, 0
	lda #255             ; Tell VBI to silence channel.

LoopStopSound
	sta SOUND_CONTROL,x  ; Set channel control to silence.
	dex
	bpl LoopStopSound    ; Channel 3, 2, 1, 0

	rts


; ==========================================================================
; SetSound                                                        A  X  Y
; -------------------------------------------------------------------------- 
; Set Sound
;
; Main routine to set sound playing for a channel.
;
; The procedure for playing sound.
; 1) MAIN sets the channel's SOUND_CONTROL to 0.
; 2) MAIN sets the channel's SOUND_FX_LO/HI pointer to the sound effects 
;    sequence to play.
; 3) MAIN sets the channel's SOUND_CONTROL to 1 to tell VBI to start.
; 4) VBI when playing sets the channel's SOUND_CONTROL value to 2, then 
;    to 0 when done.
;
; Uses A, X, Y
; X = sound channel to assign. (0 to 3, not 1 to 4)
; Y = sound number to use. (values declared at beginning of Audio.asm.) 
; --------------------------------------------------------------------------

SetSound

	lda #0
	sta SOUND_CONTROL,X     ; Tell VBI to stop working POKEY channel X

	lda SOUND_FX_LO_TABLE,Y ; Assign pointer of sound effect
	sta SOUND_FX_LO,X       ; to the channel controller.
	lda SOUND_FX_HI_TABLE,Y
	sta SOUND_FX_HI,X

	lda #1
	sta SOUND_CONTROL,X     ; Tell VBI it can start running POKEY channel X

	rts


; ==========================================================================
; SoundService                                                    A  X  Y
; --------------------------------------------------------------------------
; Sound service called by Deferred Vertical Blank Interrupt.
;
; The world's cheapest sequencer. Play one sound value from a table at each 
; call. Assuming this is done synchronized to the frame it performs a sound 
; change every 16.6ms (approximately)
; 
; Sound control between main process and VBI to turn on/off/play sounds.
; 0   = Set by Main to direct stop managing sound pending an update from 
;       MAIN. This does not stop the POKEY's currently playing sound. 
;       It is set by the VBI to indicate the channel is idle/unmanaged. 
; 1   = Main sets to direct VBI to start playing a new sound FX.
; 2   = VBI sets when it is playing to inform Main that it has taken 
;       direction and is now busy.
; 255 = Direct VBI to silence the channel.
;
; So, the procedure for playing sound.
; 1) MAIN sets the channel's SOUND_CONTROL to 0.
; 2) MAIN sets the channel's SOUND_FX_LO/HI pointer to the sound effects 
;    sequence to play.
; 3) MAIN sets the channel's SOUND_CONTROL to 1 to tell VBI to start.
; 4) VBI when playing sets the channel's SOUND_CONTROL value to 2, then 
;    to 0 when done.
;
; A sound Entry is 4 bytes...
; byte 0, AUDC (distortion/volume) value
; byte 1, AUDF (frequency) value
; byte 2, Duration, number of frames to count. 0 counts as 1 frame.
; byte 3, 0 == End of sequence. Stop playing sound. (Set AUDF and AUDC to 0)
;         1 == Continue normal playing.
;       255 == End of sequence. Do not stop playing sound.
;       Eventually some other magic to be determined goes here.
; --------------------------------------------------------------------------

SoundService

	ldx #3
LoopSoundServiceControl
	lda SOUND_CONTROL,x
	beq DoNextSoundChannel       ; SOUND_CONTROL == 0 means do nothing

	cmp #255                     ; Is it 255 (-1)?
	bne CheckMainSoundDirections ; No, then go follow channel FX directions.
	jsr EndFXAndStopSound        ; SOUND_CONTROL == 255 Direction from main to stop sound.
	jmp DoNextSoundChannel

CheckMainSoundDirections
	cmp #1                   ; SOUND_CONTROL == 1 New direction from main?
	bne DoNormalSoundService ; No, continue normally.

; SOUND_CONTROL == 1  is new direction from Main.  Setup new request.
	lda #2
	sta SOUND_CONTROL,x      ; Tell Main we're on the clock

	jsr LoadSoundPointerFromX ; Get the pointer to the current entry.

	; This is the first time in this Entry.  
	jsr EvaluateEntryControlToStop  ; test if this is the end now.
	beq DoNextSoundChannel          ; If so, then we're done.

	jsr LoadTheCurrentSoundEntry    ; If not, then load sound up the first time,
	jmp DoNextSoundChannel          ; and then we're done without evaluation duration.

DoNormalSoundService                ; SOUND_CONTROL == 2.  VBI is running normally.
	lda SOUND_DURATION,x            ; If sound currently running has a duration, then decrement and loop.
	beq ContinueNextSound           ; 0 means end of duration.  Load sound for the currently queued entry.
	dec SOUND_DURATION,x            ; Otherwise, Decrement duration.
	jmp DoNextSoundChannel          ; Maybe on the next frame there will be something to do.

ContinueNextSound
	jsr LoadSoundPointerFromX       ; Get the pointer to the current entry.
	jsr EvaluateEntryControlToStop 
	; If the Entry Control set CONTROL to stop the sound, then do no more work.
	beq DoNextSoundChannel          ; SOUND_CONTROL == 0 means do nothing

DoTheCurrentSound                   ; Duration is 0. Just do current parameters.
	jsr LoadTheCurrentSoundEntry

GoToNextSoundEntry                  ; Add 4 to the current pointer address to get the next entry.
	clc
	lda SOUND_FX_LO,X
	adc #4
	sta SOUND_FX_LO,X
	bcc DoNextSoundChannel
	inc SOUND_FX_HI,X

DoNextSoundChannel
	dex                            ; 3,2,1,0....
	bpl LoopSoundServiceControl

ExitSoundService
	rts


; Given X, load the current Entry pointer into SOUND_POINTER
LoadSoundPointerFromX
	lda SOUND_FX_LO,X       ; Get Pointer to specified sound effect.
	sta SOUND_POINTER
	lda SOUND_FX_HI,X
	sta SOUND_POINTER+1

	rts


; Given X and SOUND_POINTER pointing to the entry, then set
; audio controls.
LoadTheCurrentSoundEntry
	jsr SaveXTimes2          ;  X = X * 2  (but save original value)

	ldy #0                   ; Pull AUDC
	lda (SOUND_POINTER),y
	sta AUDC1,X
	iny
	lda (SOUND_POINTER),y    ; Pull AUDF
	sta AUDF1,X
	iny
	lda (SOUND_POINTER),y    ; Pull Duration
	ldx SAVEX                ; Get original X * 1 value.
	sta SOUND_DURATION,X

	rts


; Does the Entry control says to stop sound? 
EvaluateEntryControlToStop
	ldy #3
	lda (SOUND_POINTER),y    ; What does entry control say?
	beq EndFXAndStopSound    ; 0 means the end.
	bmi EndFX                ; 255 means end, without stopping sound.

	lda (SOUND_POINTER),y    ; What does entry control say? (return to caller)

	rts


; Entry control says the sound is over, and stop the sound...
EndFXAndStopSound
	jsr SaveXTimes2          ;  X = X * 2  (but save original value)

	lda #0                   
	sta AUDC1,X              ; Stop POKEY playing.
	sta AUDF1,X
	ldx SAVEX                ; Get original X * 1 value.

; Entry control says the sound is over. (but don't actually stop POKEY).
EndFX
	lda #0
	sta SOUND_DURATION,X     ; Make duration 0.
	sta SOUND_CONTROL,X      ; And inform MAIN and VBI this channel is unused.

	rts

; In order to index the reference to AUDC and AUDF we need the channel 
; number in X temporarily multiplied by 2.
SaveXTimes2
	stx SAVEX                ; Save the current X
	txa                      ; A = X
	asl                      ; A = A << 1  ; (or A = A *2)
	tax                      ; X = A  (0, 1, 2, 3 is now 0, 2, 4, 6).

	rts
