#!/usr/bin/env bash
# Fine-tune only the fc layer on a particular dataset.
# Typically for computing the impact score later.

# Change to the project root directory. Assume this file is at scripts/.
cd $(dirname ${BASH_SOURCE[0]})/../

# Set relative paths.
CAFFE_DIR=external/caffe
MODELS_DIR=models/fc_only
LOGS_DIR=logs/fc_only
SNAPSHOTS_DIR=external/exp/snapshots/fc_only

# Parse arguments.
if [[ $# -ne 4 ]]; then
    echo "Usage: $(basename $0) dataset split model weights"
    echo "    dataset       Dataset name"
    echo "    split         Split index"
    echo "    model         Model name"
    echo "    weights       Pretrained caffe model weights"
    exit
fi
dataset=$1
printf -v split_index "%02d" $2
model=$3
weights=$4

# Make directories.
mkdir -p ${LOGS_DIR}
mkdir -p ${SNAPSHOTS_DIR}

# Replace the split_index with our specified one in the template solver and
# template trainval prototxt.
trainval=${MODELS_DIR}/${dataset}_split_${split_index}_${model}_trainval.prototxt
solver=${MODELS_DIR}/${dataset}_split_${split_index}_${model}_solver.prototxt
sed -e "s/\${split_index}/${split_index}/g" \
    ${MODELS_DIR}/${dataset}_${model}_trainval.prototxt > ${trainval}
sed -e "s/\${split_index}/${split_index}/g" \
    ${MODELS_DIR}/${dataset}_${model}_solver.prototxt > ${solver}

# Fine-tuning.
GLOG_logtostderr=1 mpirun -n 2 ${CAFFE_DIR}/build/tools/caffe train \
    -solver ${solver} -weights ${weights} -gpu 0,1 \
    2>&1 | tee ${LOGS_DIR}/${dataset}_split_${split_index}_${model}.log

# Cleanup.
rm ${trainval} ${solver}
