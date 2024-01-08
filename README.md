# Nix shell environment for ZX80 / ZX Spectrum

You can do lots of different things with this environment. The main activities I
am concerned with are:

1. Running tapes (ROMS) for old games etc.
2. Writing and running programs in Z80 assembler.


## Running tapes


You can also download other tapes from https://worldofspectrum.org/

To run a tape, download it from the site above, unzip it in e.g. the tapes folder and then do:

```
zesarux tapes/Con-Quest.tap/CON-QUES.TAP
```

## Z80 Assembly Language Coding 

See  https://github.com/maziac/DeZog#dezog for how to work with Z80 assembler in vscode.

The hello example here is copied from that site and adapted to work out the box
with this setup.

There are basically 3 different ZXSpectrum emulators you can use:

* internal - which is bundled with DeZog but is not a fully compliant implementation
* zesarux - which is bundled in this nix shell environment
* cspect - I've never tried to use that -  and there is no nix package for it.

To run the hello example here do the following:

```
code .
```

This will open VSCode using the version installed in this nix shell, with 
this folder opened and ready to use.

In VSCode you need to install the extensions listed in the DeZog home page. These are the ones I finally ended up with:

* [ASM Code Lens](https://marketplace.visualstudio.com/items?itemName=maziac.asm-code-lens)
* [DeZog](https://marketplace.visualstudio.com/items?itemName=maziac.dezog)
* [Hex Hover Converter](https://marketplace.visualstudio.com/items?itemName=maziac.hex-hover-converter)
* [SNA File Viewer](https://marketplace.visualstudio.com/items?itemName=maziac.sna-fileviewer)
* [Z80 Assembly](https://marketplace.visualstudio.com/items?itemName=Imanolea.z80-asm)
* [Z80 Instruction Set](https://marketplace.visualstudio.com/items?itemName=maziac.z80-instruction-set)

📒 These are listed in .vscode/extensions.json so you should be prompted to install them when you open this project in VSCode.



Then do:

Terminal ➡️ Run Build Task (Crtl+Shift+B)

The program will be compiled and ``hello.sna`` will be generated.

Next do

Terminal ➡️ Run Task...

And choose the ``zesarux --noconfigfile ...`` task

![Run task](img/run-task.png)


That will open the emulator in debug mode:

![Run task](img/zesarux.png)




## Resources

* [Z80 Mnemonics](http://www.z80.info/z80syntx.htm) : A list of all instructions / mnemonics, with descriptions.
* [ZX Spectrum Character Set](https://worldofspectrum.net/ZXBasicManual/zxmanappa.html)
* [ZX Spectrum Manual](http://www.retro8bitcomputers.co.uk/Content/downloads/manuals/ZX-Spectrum-48K-Manual.pdf)
* [ZX Spectrum ROM Subroutines](https://skoolkid.github.io/rom/maps/routines.html)
* [ZX Spectrum Assembler Programming Tutorial Series](https://www.youtube.com/playlist?list=PLO_DS4Ra9jOooo0tFaLq-BXa24iPWkJJ7) : A really nice, slow paced and clear  step by step walk through of proamming the Spectrum Z80 in Assembly Language.
* [DeZog Detailed Reference](https://github.com/maziac/DeZog/blob/main/documentation/Usage.md) - really read this in detail!

## Credits

Example code copied from DeZog then modified by Tim.

This README and shell.nix by Tim.

Tim Sutton
Jan 2024
