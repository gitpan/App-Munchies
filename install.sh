#!/bin/sh

# Run this to install the application

perl Build.PL || exit

./Build || exit

./Build installdeps || exit

[ -n "${1}" -a "${1}" = "--notest" ] || ./Build test || exit

./Build install

