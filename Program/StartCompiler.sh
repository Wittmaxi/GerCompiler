#!/bin/sh

echo "Installiere die neueste Assembler-Version"

sudo apt install nasm
sudo pacman -S nasm

echo "Starte den Compiler. Schliessen sie dieses Fenster nicht, da das fertige Programm hier ausgeführt werden wird."

./Compiler
