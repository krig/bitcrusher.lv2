#!/bin/sh
mkdir -p $HOME/modduo
if [ "x$1" = "xcreate" ]; then
    docker pull moddevices/mod-plugin-builder
    docker run -ti --name mpb -p 9000:9000 -v $HOME/modduo:/tmp/local-mod-folder -v $HOME/projects/modduo:/tmp/projects moddevices/mod-plugin-builder
elif [ "x$1" = "xstart" ]; then
    docker start -i mpb
fi
