#!/bin/bash

until node waiter.js; do
  echo "Respawning waiter.js in 2 seconds..."
  sleep 2
done
