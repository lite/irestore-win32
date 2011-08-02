#!/usr/bin/env bash

irecovery -c "setenv auto-boot true"
irecovery -c "saveenv"
irecovery -c "reboot"