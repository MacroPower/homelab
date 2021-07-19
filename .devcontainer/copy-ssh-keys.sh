#!/bin/sh

cp /tmp/.ssh/id_rsa /home/vscode/.ssh/id_rsa
cp /tmp/.ssh/id_rsa.pub /home/vscode/.ssh/id_rsa.pub
chmod 700 /home/vscode/.ssh/
chmod 644 /home/vscode/.ssh/id_rsa.pub
chmod 600 /home/vscode/.ssh/id_rsa
