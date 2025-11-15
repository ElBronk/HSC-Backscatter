#!/bin/bash

sudo airmon-ng check kill
sudo airmon-ng start wlxc025e92d5b09 3

cd wifi-injection

sudo bash << 'EOF'
source venv/bin/activate
./test-injection.py wlxc025e92d5b09 --channel 3
./test-injection.py wlxc025e92d5b09 --channel 3
./test-injection.py wlxc025e92d5b09 --channel 3
./test-injection.py wlxc025e92d5b09 --channel 3
./test-injection.py wlxc025e92d5b09 --channel 3
./test-injection.py wlxc025e92d5b09 --channel 3
./test-injection.py wlxc025e92d5b09 --channel 3
echo "done"
EOF
