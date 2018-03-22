#!/bin/bash
set -e
set -x
curl ${NAME} | grep 'black'
