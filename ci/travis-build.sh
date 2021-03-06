#!/bin/bash
set -eu

CI_TARGET_ARCH="${BUILD_ARCH:-$TRAVIS_CPU_ARCH}"
EXTRA_CFLAGS="-Werror"
export PYTHONUNBUFFERED=TRUE
CONFIGURE_FLAGS=()

case "$TRAVIS_OS_NAME" in
    "linux")
        [ "$TRAVIS_EVENT_TYPE" == "cron" ] && CONFIGURE_FLAGS+=(--enable-libiscsi)
        case "$CI_TARGET_ARCH" in
            "x86")
                EXTRA_CFLAGS="${EXTRA_CFLAGS} -m32"
                export LDFLAGS="-m32"
                ;;
            "amd64")
                [ "$TRAVIS_EVENT_TYPE" == "cron" ] && CONFIGURE_FLAGS+=(--enable-cuda)
                ;;
        esac
    ;;
esac
CONFIGURE_FLAGS+=(--extra-cflags="${EXTRA_CFLAGS}")

./configure "${CONFIGURE_FLAGS[@]}" &&
    make &&
    make test &&
    if [[ "$CI_TARGET_ARCH" == "arm64" ]]; then
        sudo python3 t/run-fio-tests.py --skip 6 1007 1008 --debug -p 1010:"--skip 15 16 17 18 19 20"
    elif [[ "$TRAVIS_EVENT_TYPE" == "cron" ]]; then
        sudo python3 t/run-fio-tests.py --skip 6 1007 1008 --debug
    else
        sudo python3 t/run-fio-tests.py --skip 2 6 1000 1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 --debug
    fi
