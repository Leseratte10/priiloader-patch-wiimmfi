# Priiloader Patch for Wiimmfi

[Priiloader](https://github.com/DacoTaco/priiloader) is a piece of software by DacoTaco that can be used, among other things, to apply custom code patches to the Wii system menu. 

This repository contains the source code for one of these patches - a system menu patch that will automatically make any Wii Disc connect to [Wiimmfi](https://wiimmfi.de/) instead of the defunct Nintendo Wi-Fi Connection. Currently this only works for disc games, not for installed channels since I didn't find a proper hook to patch these. 

This hack requires Priiloader 0.9 or newer.

## Compiling

To compile the hack, execute the `compile-wiimmfi-all.sh` script (Linux). This has only been tested with devkitPPC r33 which can be downloaded [from my archive](https://wii.leseratte10.de/devkitPro/devkitPPC/r33%20%282018%29/). 

If you don't want to install any dependencies or mess with devkitPPC, there's a dockerfile included that will compile the hack when built. Just execute `DOCKER_BUILDKIT=1 docker build -o output .` and the hacks_hash.ini with the hack will be created in the `output` folder. 

## Code

- The `compile-wiimmfi-all.sh` is the "makefile" for the project. It sets up all the variables and version-dependant offsets, compiles the main binary, and sets up all the hooks for the different system menu versions.
- The `patch_wiimmfi.S` file is the main Wiimmfi patch. It's executed within the system menu right before a game is booted, and it applies all the Wiimmfi patches in memory. 
- The `patch_exploit-fix.S` is a small patch that makes Mario Kart Wii execute under IOS58 (instead of IOS36) if installed. This is for security reasons since old IOSes have a bunch of exploits like [bluebomb](https://github.com/Fullmetal5/bluebomb) and probably others.
- The `RCE` folder is the dedicated security fix for the STATUS exploit that [we fixed in 2021](https://wiimmfi.de/update). This is written in C not in Assembly as it's a bit more complex. The assembly code in the Wiimmfi patcher will call one of the C functions from that folder. 

