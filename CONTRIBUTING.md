# Contributing

Creating new issue or pull request is very welcomed. However, whenever if it just a small bug report/fix or any major changes, there may be some stuffs you want to think about inorder to make a very smooth issue/PR, depending on what changes you want to do with it.

## Weapon balances

[vsh.cfg](https://github.com/redsunservers/VSH-Rewrite/blob/master/addons/sourcemod/configs/vsh/vsh.cfg) is used to balance every weapons player can use. Config allows you to add/remove/modify:
- `attrib` to give/set weapon any one of the attributes.
- `minicrit` and `crit` to permanently give weapon minicrit/crit while weapon is active.
- `tags` to give weapon "custom attributes" from VSH code to do any wacky stuffs normal attribute can't do.
When using `tags`, it very much preferred to use any existing tags without modifying VSH code. Adding new tags is still allowed, but should be allowed for other weapons to use in the future if possible.
All reskin weapons should be using same stats as orginal weapon, by using `prefab` key.
Adding new convars should really only be needed if it general stuff, while not limited to specific weapons or slot.

## Gameplay changes

When you code for any balance ideas/changes, you want to think in a way of what happens when randomizer is loaded. You want to enure code still works with all different weird possibilities, while keeping code sane and in same format.

## Bosses

Everyone wants new bosses, however VSH-Rewrite bosses is quite strict into adding new bosses. 3 main rules into adding new boss:
- Must be anywhere related to Team Fortress 2 theme and/or lore.
- Atleast 1 big, or 2 small uniqute abilites that is noticeable difference between other existing bosses.
- Materials, models and sounds available to be used or modified (license!!!), along with reasonable download file-size, but not absolute needed.

Once you have the idea for a new boss, its wise to create an issue first to discuss idea and any needed change before working into coding and pull request. It would be a shame if someone did all of the work into creating a new boss only to find out it does not fit into one of the rules.

You can see some code examples for [bosses](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting/vsh/bosses) and [abilities](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting/vsh/abilities) on how to create new boss, along with [including a file](https://github.com/redsunservers/VSH-Rewrite/blob/4c02a703c2969d944fcf423b8361e9ae205a949e/addons/sourcemod/scripting/saxtonhale.sp#L330-L364) and [registering boss/abilites](https://github.com/redsunservers/VSH-Rewrite/blob/4c02a703c2969d944fcf423b8361e9ae205a949e/addons/sourcemod/scripting/saxtonhale.sp#L481-L522), code fortmatting should be kept identical to other bosses code.

## Modifiers

Much simpler to create compared to bosses, main changes should be kept to a maximum of 2 upsides and 2 downsides, while also support every bosses. Creating an issue for it is not needed as it should be easy to make, but you can still create one if wanted.
You can find some code examples for [modifiers](https://github.com/redsunservers/VSH-Rewrite/tree/master/addons/sourcemod/scripting/vsh/modifiers) here.

## Useful links
- [VSH-Rewrite megathread discussion in redsun.tf forum](https://forum.redsun.tf/threads/2864/)
- [List of all TF2 weapon indexs in alliedmods wiki](https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes#Weapons)
- [List of all TF2 attributes in tf2b.com](https://tf2b.com/attriblist.php)
- [List of all TF2 conditions in teamfortress wiki](https://wiki.teamfortress.com/wiki/Cheats#addcond)
