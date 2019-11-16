# Go to build dir
cd build

# Create package dir
mkdir -p package/addons/sourcemod/plugins
mkdir -p package/addons/sourcemod/configs
mkdir -p package/addons/sourcemod/gamedata

# Copy all required stuffs to package
cp -r addons/sourcemod/plugins/saxtonhale.smx package/addons/sourcemod/plugins
cp -r ../addons/sourcemod/configs/vsh package/addons/sourcemod/configs
cp -r ../addons/sourcemod/gamedata/vsh.txt package/addons/sourcemod/gamedata
cp -r ../materials package
cp -r ../models package
cp -r ../sound package
cp -r ../LICENSE package