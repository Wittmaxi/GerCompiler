#!/bin/sh

echo "Installiere die neueste Assembler-Version"

sudo apt install nasm #for ubuntu-users
sudo Pacman -P nasm #Für Dich, R., der Das Testen wird, in der Hoffnung, dass ich mit Ubuntu aufhöre xD

clear

echo "Starte den Compiler. Schliessen sie dieses Fenster nicht, da das fertige Programm hier ausgeführt werden wird."

sudo ./Compiler
