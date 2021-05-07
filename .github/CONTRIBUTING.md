# Contributing

Creating a new issue or pull request is welcomed. However, if it's just a small bug report/fix or if you want to propose any major changes, there may be some things you want to think about in order to create a good issue/PR, depending on what changes you make.

## Weapon balancing

[vsh.cfg](https://github.com/redsunservers/VSH-Rewrite/blob/master/addons/sourcemod/configs/vsh/vsh.cfg) is used to balance every weapon players can use. The config allows you to add/remove/modify:
- `attrib` to give/set weapon any one of the attributes.
- `minicrit` and `crit` to permanently give weapon minicrit/crit while weapon is active.
- `tags` to give weapon "custom attributes" from VSH code to do any wacky stuffs normal attribute can't do.
When using `tags`, it's very much preferred to use any existing tags without modifying VSH code. Adding new tags is still allowed, but should be allowed for other weapons to use in the future if possible.
All reskin weapons should be using the same stats as the orginal weapon, by using the `prefab` key.
Adding new convars should really only be needed if it's for general stuff, while not limited to specific weapons or slot.

## Gameplay changes

When you code for any balance ideas/changes, you want to think in a way of what happens when randomizer is loaded. You want to enure code still works with all sorts of weird possibilities, while keeping code sane and in the same format.

## Bosses

Everyone wants new bosses, however VSH-Rewrite bosses is quite strict into adding new bosses. 3 main rules into adding new boss:
- Must be related to Team Fortress 2 theme and/or lore.
- At least 1 big, or 2 small unique abilites that are noticably different compared to existing bosses.
- Materials, models and sounds available to be used or modified (license!!!), along with reasonable download filesize, but this is not a must.

Once you have the idea for a new boss, its wise to create an issue first to discuss idea and any needed change before working into coding and pull request. It would be a shame if someone did all of the work into creating a new boss only to find out it does not fit into one of the rules.

You can see some code examples for [bosses](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting/vsh/bosses) and [abilities](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting/vsh/abilities) on how to create new boss, along with [including a file](https://github.com/redsunservers/VSH-Rewrite/blob/4c02a703c2969d944fcf423b8361e9ae205a949e/addons/sourcemod/scripting/saxtonhale.sp#L330-L364) and [registering boss/abilites](https://github.com/redsunservers/VSH-Rewrite/blob/4c02a703c2969d944fcf423b8361e9ae205a949e/addons/sourcemod/scripting/saxtonhale.sp#L481-L522), code fortmatting should be kept identical to other bosses code.

## Modifiers

Much simpler to create compared to bosses, main changes should be kept to a maximum of 2 upsides and 2 downsides, while also supporting all bosses. Creating an issue for modifiers is not needed as it should be easier to make, but you can still create one if you want.
You can find some code examples for [modifiers](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting/vsh/modifiers) here.

## Useful links
- [VSH-Rewrite megathread discussion on the redsun.tf forums](https://forum.redsun.tf/threads/2864/)
- [TF2 weapon indexes on AlliedMods wiki](https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes#Weapons)
- [TF2 attributes on tf2b.com](https://tf2b.com/attriblist.php)
- [TF2 conditions on teamfortress wiki](https://wiki.teamfortress.com/wiki/Cheats#addcond)
- [TF2 netprops on tf2-data](https://raw.githubusercontent.com/powerlord/tf2-data/master/netprops.txt)