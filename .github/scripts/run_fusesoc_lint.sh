#!/bin/bash

export PATH=$(pwd)/verible/bin/:$PATH 

core_name=$(fusesoc --cores-root . list-cores | tail -1 | awk '{print$1}')

fusesoc --cores-root . run --target lint $core_name
