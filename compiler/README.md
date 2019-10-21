# SourcePawn Public Methodmap Compiler

VSH-Rewrite use methodmaps to call boss, ability and modifiers function. However with default SourcePawn all methodmaps is private, meaning plugin can't find functions and therefore can't be called.
With this custom compiler, all methodmaps will be compiled public, so plugin can find functions and call it.
Custom SourceMod build is not needed/required, SourcePawn custom compiler should work fine for base SourceMod.
Very small changes has been done with source code to make this work, only [parser.cpp](https://github.com/alliedmodders/sourcepawn/blob/7ba3e384e29ccdb5dbd3ac4a0fda16fd0a0144a8/compiler/parser.cpp) has been modified.

Available custom compilers can be found [here](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting), 2 spcomp-custom for both windows and linux, built with SourceMod 1.10.6453