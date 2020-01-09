#!/bin/sh
# set up links
mkdir -p ~/mod-plugin-builder/plugins/package/bitcrusher
ln -s \
    /tmp/projects/bitcrusher.lv2/modduo/bitcrusher.mk \
    ~/mod-plugin-builder/plugins/package/bitcrusher/bitcrusher.mk
ln -s \
    /tmp/projects/bitcrusher.lv2 \
    ~/mod-plugin-builder/plugins/package/bitcrusher/source

# run the build

# copy to the mod duo
#cd ~/mod-workdir/plugins/
#tar cz bitcrusher.lv2 | base64 | curl -F 'package=@-' http://192.168.51.1/sdk/install

