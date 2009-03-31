#!/bin/sh

# Run this to install the application

perl Build.PL || exit

./Build installdeps || exit

./Build --ask || exit

./Build test || exit

./Build install

