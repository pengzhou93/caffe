#!/bin/bash

debug_str="import pydevd;pydevd.settrace('localhost', port=8081, stdoutToServer=True, stderrToServer=True)"
# pydevd module path
export PYTHONPATH=/home/shhs/Desktop/user/soft/pycharm-2018.1.4/debug-eggs/pycharm-debug-py3k.egg_FILES

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

build_caffe()
{
    rebuild=$1
    runtest=$2

    if [ "$rebuild" = rebuild ]
    then
        make clean
    fi

#   python3.6
    source $HOME/anaconda3/bin/activate python3.5

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

    if [ "$runtest" = runtest ]
    then
        make test -j8
        make runtest
    fi

#   delete in reverse order
    delete_debug_string Makefile 209 "$opencv_lib"
    delete_debug_string Makefile 208 "$opencv_include"
    delete_debug_string Makefile 177 "$cudnn_lib"
    delete_debug_string Makefile 176 "$cudnn_include"

}

if [ "$1" = dependencies ]
then
    sudo apt-get install libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler
    sudo apt-get install --no-install-recommends libboost-all-dev
    sudo apt-get install libopenblas-dev

elif [ "$1" = build ]
then
#   ./run.sh build norebuild runtest
#   python: python3.5
#   The version of python must be compatible with boost.
    rebuild=$2
    runtest=$3
    build_caffe "$rebuild" "$runtest"


elif [ "$1" = "examples/tile_segmentation/bnn" ]
then
#   ./run.sh "examples/tile_segmentation/bnn" norebuild debug
#   ./run.sh "examples/tile_segmentation/bnn" norebuild debug-cpp
    rebuild=$2
    runtest=noruntest
    build_caffe "$rebuild" "$runtest"

    root_dir="examples/tile_segmentation"
    cd $root_dir
    file="train.py"

    debug=$3
    if [ $debug = debug ]
    then
        line=1
        insert_debug_string $file $line "$debug_str" $debug
        python $file 1.0 bnn_train.prototxt snapshot_models/bnn_train
        delete_debug_string $file $line "$debug_str"

    elif [ $debug = debug-cpp ]
    then
        gdbserver localhost:8080 python $file 1.0 bnn_train.prototxt snapshot_models/bnn_train

    else
        python train.py 1 bnn_train.prototxt snapshot_models/bnn_train #snapshot_models/bnn_train_iter_5000.caffemodel
    fi

elif [ "$1" = "examples/tile_segmentation/cnn" ]
then
#   ./run.sh "examples/tile_segmentation/cnn" norebuild debug
    rebuild=$2
    runtest=noruntest
    build_caffe "$rebuild" "$runtest"

    root_dir="examples/tile_segmentation"
    cd $root_dir
    file="train.py"

    debug=$3
    if [ $debug = debug ]
    then
        line=1
        insert_debug_string $file $line "$debug_str" $debug
        python $file 0.01 cnn_train.prototxt snapshot_models/cnn_train
        delete_debug_string $file $line "$debug_str"
    else
        python train.py 0.01 cnn_train.prototxt snapshot_models/cnn_train
    fi

elif [ "$1" = "examples/tile_segmentation/test_and_plot.py" ]
then
#   ./run.sh "examples/tile_segmentation/test_and_plot.py" norebuild debug
    rebuild=$2
    runtest=noruntest
    build_caffe "$rebuild" "$runtest"

    root_dir="examples/tile_segmentation"
    cd $root_dir
    file="test_and_plot.py"

    debug=$3
    if [ $debug = debug ]
    then
        line=1
        insert_debug_string $file $line "$debug_str" $debug
        python $file
        delete_debug_string $file $line "$debug_str"
    else
        python $file
    fi

fi