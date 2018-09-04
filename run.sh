#!/bin/bash

insert_debug_string()
{
    file=$1
    line=$2
    debug_string=$3
    debug=$4

    value=`sed -n ${line}p "$file"`

    if [ "$value" != "$debug_string" ] && [ "$debug" = debug ]
    then
    echo "++Insert $debug_string in line_${line}++"

    sed "${line}s/^/\n/" -i $file
    sed -i "${line}s:^:${debug_string}:" "$file"
    fi
}

delete_debug_string()
{
    file=$1
    line=$2
    debug_string=$3

    value=`sed -n ${line}p "$file"`
    if [ "$value" = "$debug_string" ]
    then
    echo "--Delete $debug_string in line_${line}--"
    sed "${line}d" -i "$file"
    fi
}

if [ "$1" = dependencies ]
then
    sudo apt-get install libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler
    sudo apt-get install --no-install-recommends libboost-all-dev
    sudo apt-get install libopenblas-dev

elif [ "$1" = build ]
then
#   ./run.sh build rebuild|runtest
    if [ "$2" = rebuild ]
    then
        make clean
    fi

#   python3.6
    source $HOME/anaconda3/bin/activate tf_1_6

#   cuda, cudnn
    cudnn_path=/usr/local/cudnn_v5.1_cuda8.0
    cuda_path=/usr/local/cuda-8.0
    export LD_LIBRARY_PATH="$cudnn_path"/lib64:"$cuda_path"/lib64:$LD_LIBRARY_PATH

    cudnn_include="INCLUDE_DIRS += ${cudnn_path}/include"
    cudnn_lib="LIBRARY_DIRS += ${cudnn_path}/lib64"

    insert_debug_string Makefile 176 "$cudnn_include" debug
    insert_debug_string Makefile 177 "$cudnn_lib" debug

#   opencv
    opencv_path="/home/shhs/env/opencv3_2"
    opencv_include="INCLUDE_DIRS += ${opencv_path}/include"
    opencv_lib="LIBRARY_DIRS += ${opencv_path}/lib"

    insert_debug_string Makefile 208 "$opencv_include" debug
    insert_debug_string Makefile 209 "$opencv_lib" debug

    make all -j8
    make pycaffe

    if [ "$2" = runtest ]
    then
        make test -j8
        make runtest
    fi

#   delete in reverse order
    delete_debug_string Makefile 209 "$opencv_lib"
    delete_debug_string Makefile 208 "$opencv_include"
    delete_debug_string Makefile 177 "$cudnn_lib"
    delete_debug_string Makefile 176 "$cudnn_include"


fi