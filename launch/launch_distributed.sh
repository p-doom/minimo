#!/bin/bash

# Function to count available GPUs using nvidia-smi
count_gpus() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=gpu_name --format=csv,noheader | wc -l
    else
        echo 0
    fi
}

# Function to cleanup processes on exit
cleanup() {
    echo "Cleaning up..."
    pkill -f "redis-server"
    pkill -f "celery"
    rm -f redis_hostname_port.txt
    exit
}

# Set up trap
trap cleanup SIGINT SIGTERM

# Start Redis in background
sh launch/start_redis.sh &

# Get number of GPUs
NUM_GPUS=$(count_gpus)
if [ $NUM_GPUS -eq 0 ]; then
    NUM_GPUS=1  # Default to 1 worker if no GPUs found
fi

# Start workers (one per GPU)
for ((i=0; i<$NUM_GPUS; i++)); do
    sh launch/start_worker.sh &
done

# Start bootstrap distributed (in foreground)
sh launch/run_bootstrap_distributed.sh