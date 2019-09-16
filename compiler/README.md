# Custom Compiler

VSH-Rewrite use methodmaps to call boss, ability and modifiers function. However with default SourcePawn all methodmaps is private, meaning plugin can't find functions and therefore can't be called.
With this custom compiler, all methodmaps will be compiled public, so plugin can find functions and call it.
Custom SourceMod build is not needed/required, SourcePawn custom compiler should work fine for base SourceMod.

All available custom compilers can be found [here](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting), 4 spcomp-custom for both windows and linux, SourcePawn 1.9 and 1.10.
Keep in mind though, compiled 1.10 plugins does not work on base SourceMod 1.9.

Very small changes has been done with source code to make this work, only sc1.cpp (1.9) and parser.cpp (1.10) has been changed.
- [1.9 Compiler (SourceMod 1.9.0.6281)](https://github.com/alliedmodders/sourcepawn/blob/c78349382d97d5a9f20b49975c47d9bb805c125d/compiler/sc1.cpp)
- [1.10 Compiler (SourceMod 1.10.0.6442)](https://github.com/alliedmodders/sourcepawn/blob/acdb46368908409ff94213afed2ce3549031d9e9/compiler/parser.cpp)