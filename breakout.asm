org 7C00h
bits 16 ;;assuming the direc`tion flag is clear, bp = 0, sp = 6Ef0h

PADLE_COLOR1 equ 00Eh ;;yellow
PADLE_COLOR2 equ 2Ah ;;orange
BLOCK_COLOR1 equ 23h ;;dark purple
BLOCK_COLOR2 equ 50h ;;light purple
BALL_COLOR equ 0Fh ;;white
SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
VIDEO_MEMORY equ 0A000h
TIMER equ 046Ch
PADLE_Y equ 93
SPRITE_HEIGHT equ 4
SPRITE_WIDTH equ 8 ;;width in bits
SPRITE_WPX equ 16 ;;width in px
 

sprites equ 0FA00h ;;variables after VidMem Array
block equ 0FA00h
padle equ 0FA04h
block_arr equ 0FA08h ;;2 words = 32 bits/blocks
padle_x equ 0FA0Ch
num_block equ 0FA0Dh
ball_pos equ 0FA0Eh ;;2 bytes = 16 bits/ ball Y/X position
ball_y_velocity equ 0FA10h ;;2 bytes y, x
ball_x_velocity equ 0FA11h


mov ax, 0013h ;;color-sprite-mode color 320*200 256 color VGA mode 13
int 10h

push VIDEO_MEMORY ;;start of the video memory array for VGA mode 13
pop es


mov di, sprites ;;move initial sprite data into memory
mov si, sprite_bitmaps
mov cl, 9
rep movsw

;;set intial variables
;;mov cl, 2 ;;move block initial values and player x position
;;rep movsw

;;move number of blocks and y/x position of the ball
;;rep stosw

;;mov cl,2
;;rep stosw

push es
pop ds ;;ds = es

game_loop:
	xor ax, ax
	xor di, di
	mov al, 03h ;;cyan 
	mov cx, SCREEN_WIDTH*SCREEN_HEIGHT
	rep stosb ;;mov [es:di], al;; cx number of times
	
	;;drawing blocks
	mov si, block_arr
	mov ax, 230Ah ;;position of the top left (first block)
	mov cl, 4 ;;4 rows of blocks
	mov bl, BLOCK_COLOR2
	mov bh, BLOCK_COLOR1
	draw_next_block_row:
		pusha
		mov cl, 8 ;;number of blocks to check per row
		.check_next_block:	
			pusha
			dec cx
			bt [si], cx ;;bit test -> copies to carry flag
			jnc .next_block ;;skip if not set

			mov si, di ;;si = sprite to draw
			call draw_sprite
			
			.next_block
				popa
				add ah, SPRITE_WIDTH+4
		loop .check_next_block
		
		popa
		add al, SPRITE_HEIGHT+2
		inc si
	loop draw_next_block_row
	
	;;SI = padle X
	;;drawing padle
	lodsb
	mov si, padle
	mov ah, PADLE_Y
	xchg ah, al ;;swap x and y values
	mov bh, PADLE_COLOR2
	mov bl, PADLE_COLOR1
	call draw_sprite

	;;check if the ball hit anything
	lodsb ;; al = number of blocks remaining
	xor ah, ah
	push ax
	
	lodsw ;;ax = ball position al = y, ah = x
	lodsw
	lodsw
	call get_screen_position ;; ball posiiton is put in di
	;;mov al, [di]
	;;if hit padle
	;;cmp al, PADLE_COLOR1
	;; bounce
	;;cmp al, PADLE_COLOR2
	;; bounce
	
	;;if hit block
	;;mov bx, block_arr
	
	draw_ball:
		mov bh, BALL_COLOR
		mov ah, [si-3]
		mov al, [si-2]
		add ah, [si+2]
		add al, [si+1]
		cmp al, SCREEN_HEIGHT/2
		jge game_over
		.draw:
			mov [si-2], al
			mov [si-1], ah
			mov bl, bh
			xchg ax, bx
			mov [di+SCREEN_WIDTH], ax
			stosw
	;;get input
	get_input:
		mov si, padle_x
		mov ah, 02h
		int 16h
		test al, 1 ;;check if right shift key is pressed
		jz .check_left_shift
		add byte [si], ah ;;move to the right

		.check_left_shift:
			test al, 2 ;;check if left shift is pressed
			jz delay_timer
			sub byte [si], ah ;;move to the left
	

			
	
	delay_timer:
		mov ax, [CS:TIMER]
		inc ax
		.wait:
			cmp [CS:TIMER], ax
			jl .wait
jmp game_loop

game_over:
	cli
	hlt

;;draw the sprite on the screen
;;SI = address of the sprite
;;AL = y value, AH = x value
;;BH = color1, BL = color2
;;rewrites dx, di
draw_sprite:
	call get_screen_position
	mov cl, SPRITE_HEIGHT
	.next_line:
		push cx
		lodsb ;;al=next byte of sprite data
		xchg ax, dx ;;save sprite data into dx
		mov cl, SPRITE_WIDTH ;;number of pixels to draw
		.next_pixel
			dec cx
			push bx
			mov al, bh ;;bh=color1
			xor ah, ah	
			xor bh, bh
			bt dx, cx
			cmovc ax, bx ;;bl=color2
			mov ah, al
			mov [di + SCREEN_WIDTH], ax
			stosw
			inc cx
			pop bx
		loop .next_pixel
		add di, SCREEN_WIDTH*2-SPRITE_WPX
		pop cx
	loop .next_line		
		
	ret


;;get x/y positon in DI
;;AH = x position, AL = y postion
;;rewrites dx, di
get_screen_position:
	mov dx, ax ;;save x/y values
	cbw 
	imul di, ax, SCREEN_WIDTH*2 ;;di=y value
	mov al, dh ;;ax = x value
	shl ax, 1 ;;x*2
	add di, ax ;;di=y+x value
	ret

sprite_bitmaps:
	db 00000000b ;;block bitmap
	db 01111110b
	db 01111110b
	db 00000000b
	
	db 11111111b ;;padle bitmap
	db 11111111b
	db 00000000b
	db 00000000b
	
	dw 0FFFFh ;;block initial values
	dw 0FFFFh

	db 70 ;;padle X position
	
	db 20h ;;number of blocks
	
	dw 2020h ;;y,x position of the ball
	
	db 01h ;;y velocity(1,-1) x velocity
	db 00h 
times 510-($-$$) db 0
dw 0AA55h ;;magic number that shows this is a bootable drive
