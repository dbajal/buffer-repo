#!/bin/bash
set -e
set -x
yum install -y python-pip
pip install flask
cp files/entrypoint.sh /entrypoint.sh
chmod 755 /entrypoint.sh
cp files/run.py /run.py
