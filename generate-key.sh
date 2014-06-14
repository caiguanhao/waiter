#!/bin/bash

echo $(cat /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 64) > key
