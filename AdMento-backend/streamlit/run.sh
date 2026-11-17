#!/bin/bash
echo "Starting AdMento Streamlit  -\-/- ..."

export CONFIG_TYPE=dev

streamlit run main.py --server.port=60001 --server.address=0.0.0.0 
while true; do sleep 1000; done