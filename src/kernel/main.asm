org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
	jmp main

;	Prints a string to the screen.
;	Params:
; 		DS:SI - Pointer to string
puts:
	; Save the registers we will modify
	push si
	push ax
	push bx

.loop:
	lodsb 											; Load the next character in AL.
	or al, al 										; Verify if next character is null
	jz .done 										; If it is, we are done.

	mov ah, 0x0e									; Call BIOS Interrupt
	mov bh, 0	 									; Page number - set to 0
	int 0x10 										; Print the character in AL. Call BIOS Interrupt

	jmp .loop 										; Loop back to print the next character

.done:
	; Restore the registers we modified
	pop bx
	pop ax
	pop si
	ret 											 ; Return to the caller

main:

	; Setup (intermediary) data segments
	mov ax, 0 										; Can't write to ds/es directly
	mov ds, ax
	mov es, ax

	; Setup stack
	mov ss, ax
	mov sp, 0x7C00 							; Stack grows downwards from where we are loaded in memory

	; Print message
	mov si, msg_hello
	call puts

	hlt

.halt:
	jmp .halt


msg_hello: db 'SynthOS v0.0.1', ENDL, 0

times 510-($-$$) db 0

dw 0AA55h

