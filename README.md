# SynthOS
An X86 lightweight OS I am building as a hobby project in `Nasm`, `C` and `C++`, more details about the OS to follow as we build.

## Running the code.
To run the code ensure you have `QEMU-KVM` installed and run on Linux: After that run:

```sh
make # Run make to build the proceed to the virtualization command

qemu-system-i386 -fda build/main_floppy.img
```

# Introduction:
## How does a computer startup?
The general agreeable process is:-
1. BIOS copied from ROM into RAM

2. BIOS executes code: (Involves initializing Hardware and running some tests such as Power-on self test (POST))

3. BIOS searches for an OS to start.

4. BIOS loads and starts the OS

5. OS boots up

## How the BIOS finds an OS?
1. Legacy Booting
- BIOS loads the first sector of each bootable device into memory (at location 0x7C00). We use the `ORG` command in Assembly to tell the Assembler where we expect our code to be loaded. The Assembler uses this info to calculate the label address. 
- BIOS checks for 0xAA55 signature.
- If found, the code execution begins.

2. [EFI - (Unified) Extensible Firmware Interface](https://en.wikipedia.org/wiki/UEFI#:~:text=UEFI%20Class%203.-,Operating%20systems,stored%20on%20any%20storage%20device.)
- BIOS looks into special EFI partitions
- OS must be compiled as an EFI program.

### Directives vs Instructions
|          Directives              |          Instructions          |
|----------------------------------|:------------------------------:|
| 1. Gives a clue to the assembler | 1. Translated to machine code, |
| that affects how the program     | instructions that CPU executes.|
| compiles.                        |                                |
| 2. Not translated to machine     |                                |
| code.                            |                                |
| 3. Assembler specific - different|                                |
| assemblers have different        |                                |
| directives.                      |                                |

> ## It is worth noting that any X86 CPU must be backwards compatible with the original 8086 CPU. This is why a CPU starts in a 16bit mode. `BITS` is an ASM `directive` that tells the assembler to emit 16/32/64-bit code.

- The BIOS expects the last two bytes of the first sector to be 8855. We will assume our program can be booted from a 1.44MB Floppy Disk where one sector is 512 bytes. Meaning the last bytes of the first sector need to be 8855. We can ask Nasm to emit the bytes directly by using `DB` directive, which stands for declare constant bytes, while the `TIMES` directive repeats an instruction a number of times.

- In NASM the `$` can be used to obtain an Assembly position of the beginning of the current line, while the `$$` gives us the beginning of the current section. Meaning `$-$$` gives the size of the program in bytes

- After that we declare our signature using the `DW` directive