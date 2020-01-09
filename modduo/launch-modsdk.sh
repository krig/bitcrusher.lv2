#!/bin/sh
mkdir -p $HOME/modduo
docker pull moddevices/modsdk
docker run -p 9000:9000 -v $HOME/modduo:/lv2 moddevices/modsdk

