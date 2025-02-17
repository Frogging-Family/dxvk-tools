#!/bin/bash

export WINEDEBUG=-all

dlls_dir=`dirname "$(readlink -f $0)"`
build_arch='x86_64'
winelib='False'

if [ $winelib == 'True' ]; then
    dll_ext='dll.so'
    dlls_dir="$dlls_dir"/../lib
else
    dll_ext='dll'
fi

if [ ! -f "$dlls_dir/d3d11.$dll_ext" ] || [ ! -f "$dlls_dir/dxgi.$dll_ext" ]; then
    echo "d3d11.$dll_ext or dxgi.$dll_ext not found in $dlls_dir" >&2
    exit 1
fi

if [ -z "$wine" ]; then
    if [ $build_arch == "x86_64" ]; then
        wine="wine64"
    else
        wine="wine"
    fi
fi

winever=`$wine --version | grep wine`
if [ -z "$winever" ]; then
    echo "$wine:"' Not a wine executable. Check your $wine.' >&2
    exit 1
fi

quiet=false
assume=

function ask {
    echo "$1"
    if [ -z "$assume" ]; then
        read continue
    else
        continue=$assume
        echo "$continue"
    fi
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do

    case $1 in
    -y)
        assume='y'
        shift
        ;;
    -n)
        assume='n'
        shift
        ;;
    -q|--quiet)
        quiet=true
        assume=${assume:-'y'}
        shift 
        ;;
    *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done
set -- "${POSITIONAL[@]}"

if [ "$quiet" = true ]; then
    exec >/dev/null
fi

if [ -z "$WINEPREFIX" ]; then
    ask "WINEPREFIX is not set, continue? (y/N)"
    if [ "$continue" != "y" ] && [ "$continue" != "Y" ]; then
    exit 1
    fi
else
    if ! [ -f "$WINEPREFIX/system.reg" ]; then
        ask "WINEPREFIX does not point to an existing wine installation. Proceeding will create a new one, continue? (y/N)"
        if [ "$continue" != "y" ] && [ "$continue" != "Y" ]; then
        exit 1
        fi
    fi
fi
unix_sys_path="$($wine winepath -u 'C:\windows\system32')"
unix_sys_path="${unix_sys_path/$'\r'/}"
if [ $? -ne 0 ]; then
    exit 1
fi


ret=0

function removeOverride {
    echo -n '    [1/2] Removing override... '
    local out
    out=$($wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v $1 /d builtin /f 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "\\e[1;31m$out\\e[0m"
        exit 1
    fi
    echo -e "$(sed -e 's|\r||g' <<< "\\e[1;32m$out\\e[0m.")"
    local dll="$unix_sys_path/$1.dll"
    echo -n '    [2/2] Removing link... '
    if [ -h "$dll" ]; then
        out=$(rm "$dll" 2>&1)
        if [ $? -eq 0 ]; then
            echo -e '\e[1;32mDone\e[0m.'
        else
            ret=2
            echo -e "\\e[1;31m$out\\e[0m"
        fi
    else
        echo -e "\\e[1;33m'$dll' is not a link or doesn't exist\\e[0m."
        ret=2
    fi
}

function checkOverride {
    echo -n '    [1/2] Checking override... '
    echo -en '\e[1;31m'
    local ovr
    ovr="$($wine reg query 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v $1)"
    if [ $? -ne 0 ]; then
        echo -en '\e[1;0m'
        exit 1
    fi
    echo -en '\e[1;0m'
    if [[ $ovr == *native* ]] && ! [[ $ovr == *builtin,native* ]]; then
        echo -e '\e[1;32mOK\e[0m.'
    else
        echo -e '\e[1;31mnot set\e[0m.'
        ret=2
    fi
    echo -n "    [2/2] Checking link to $1.$dll_ext... "
    if [ "$(readlink -f "$unix_sys_path/$1.dll")" == "$(readlink -f "$dlls_dir/$1.$dll_ext")" ]; then
        echo -e '\e[1;32mOK\e[0m.'
    else
        echo -e '\e[1;31mnot set\e[0m.'
        ret=2
    fi
}

function createOverride {
    echo -n '    [1/2] Creating override... '
    local out
    out=$($wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v $1 /d native /f 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "\\e[1;31m$out\\e[0m"
        exit 1
    fi
    echo -e "$(sed -e 's|\r||g' <<< "\\e[1;32m$out\\e[0m.")"
    echo -n "    [2/2] Creating link to $1.$dll_ext... "
    ln -sf "$dlls_dir/$1.$dll_ext" "$unix_sys_path/$1.dll"
    if [ $? -eq 0 ]; then
        echo -e '\e[1;32mDone\e[0m.'
    else
        ret=2
        echo -e "\\e[1;31m$out\\e[0m"
    fi
}

case "$1" in
reset)
    fun=removeOverride
    ;;
check)
    fun=checkOverride
    ;;
'')
    fun=createOverride
    ;;
*)
    echo "Unrecognized option: $1"
    echo "Usage: $0 [reset|check] [-q|--quiet] [-y|-n]"
    exit 1
    ;;
esac

echo '[1/4] dxgi:'
$fun dxgi
echo '[2/4] d3d10core:'
$fun d3d10core
echo '[3/4] d3d11:'
$fun d3d11
echo '[4/4] d3d9:'
$fun d3d9
exit $ret
