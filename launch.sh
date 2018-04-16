#!/bin/sh

if [ -f /a.tar.xz ]; then
    echo "decompressing image..."
    cd /
    sudo tar -xpJf a.tar.xz 2> /dev/null
    sudo rm a.tar.xz
    sudo ln -snf dash /bin/sh
    cd -
fi

exec dumb-init etcd
