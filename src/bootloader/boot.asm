org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; FAT12 Boot Sector (Header)
;
jmp short start
nop

; OEM Name
bdb_oem:                             db 'MSWIN4.1'              ; 8 bytes
bdb_bytes_per_sector:                dw 512                     ; 2 bytes
bdb_sectors_per_cluster:             db 1                       ; 1 byte
bdb_reserved_sectors:                dw 1                       ; 2 bytes
bdb_fat_count:                       db 2                       ; 1 byte
bdb_dir_entries_count:               dw 0E0h                    ; 2 bytes
bdb_total_sectors:                   dw 2880                    ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:           db 0F0h                    ; F0 = 3.5" 1.44MB floppy
bdb_sectors_per_fat:                 dw 9                       ; 9 sectors per FAT
bdb_sectors_per_track:               dw 18                      ; 18 sectors per track
bdb_heads:                           dw 2                       ; 2 heads per cylinder
bdb_hidden_sectors:                  dd 0                       ; 0 hidden sectors      
bdb_large_sector_count:              dd 0                       ; 0 for FAT12

; Extended Boot Record
ebr_drive_number:                    db 0                       ; 0x00 for floppy, 0x80 for hard disk
                                     db 0                       ; Reserved
ebr_signature:                       db 29h                     ; 29h for FAT12, 0Fh for FAT16 & FAT32
ebr_volume_id:                       db 12h, 34h, 56h, 78h      ; Serial Number, Volume ID, Value doesn't matter
ebr_volume_label:                    db 'SYNTH OS   '           ; 11 bytes Volume Label, padded with spaces
ebr_system_id:                       db 'FAT12   '              ; 8 bytes System ID, padded with spaces



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

	mov ah, 0x0E									; Page number
	mov bh, 0 										; Set page number to 0	
	int 0x10 										; Print the character in AL. Call BIOS Interrupt

	jmp .loop 										; Loop back to print the next character

.done:
	; Restore the registers we modified
	pop bx
	pop ax
	pop si
	ret 											; Return to the caller

main:
	; Setup (intermediary) data segments
	mov ax, 0 										; Can't write to ds/es directly
	mov ds, ax
	mov es, ax

	; Setup stack
	mov ss, ax
	mov sp, 0x7C00 									; Stack grows downwards from where we are loaded in memory

	; Read something from Floppy Disk
	; BIOS should set DL to drive number
	mov [ebr_drive_number], dl						; Store drive number in EBR
	
	mov ax, 1 										; LBA=1, second sector from disk
	mov cl, 1										; 1 sector to read
	mov bx, 0x7E00									; Data should be after bootloader
	call disk_read
	
	; Print OS Name to screen
	mov si, msg_hello
	call puts

	cli												; Disable interrupts, this way CPU can't get out of halt state
	hlt

;
; Error Handlers
;
floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0										; BIOS keyboard interrupt
	int 16h											; Wait for key press
	jmp 0FFFFh										; Reboot - Jump to beginning of BIOS

.halt:
	cli												; Disable interrupts, this way CPU can't get out of halt state
	hlt

;
; Disk routines
;

;
; Converts an LBA address to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head
;
lba_to_chs:

    push ax
    push dx

    xor dx, dx                          			; dx = 0
    div word [bdb_sectors_per_track]    			; ax = LBA / SectorsPerTrack
                                        			; dx = LBA % SectorsPerTrack

    inc dx                              			; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                          			; cx = sector

    xor dx, dx                          			; dx = 0
    div word [bdb_heads]                			; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        			; dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl                          			; dh = head
    mov ch, al                          			; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           			; Put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                          			; Restore DL
    pop ax
    ret

;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:

    push ax                             			; Save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             			; Temporarily save CL (number of sectors to read)
    call lba_to_chs                     			; Compute CHS
    pop ax                              			; AL = number of sectors to read
    
    mov ah, 02h
    mov di, 3                           			; Retry count

.retry:
    pusha                               			; Save all registers, we don't know what bios modifies
    stc                                 			; Set carry flag, some BIOS'es don't set it
    int 13h                             			; Carry flag cleared = success
    jnc .done                           			; Jump if carry not set

    ; Read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; All attempts failed
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             				; Restore registers modified
    ret

;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_hello: db 'SynthOS v0.0.1', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0

dw 0AA55h

