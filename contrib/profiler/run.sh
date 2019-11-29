#! /bin/bash
# Copyright (c) Microsoft Corporation
# All rights reserved.
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
# to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

case $1 in
  -h|--help)
    echo "usage: run.sh [-c <container_id>]
    [-g <gpu index>]
    [-o <output dir>]
    [-s <sample period>]
    [-a <analyze period>]
    [-d <duration>]
    [-t <blocked time>]"
    exit 0
    ;;
esac
# update apt
apt update
# update pip
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install --upgrade pip
# install package
PYTHON_VERSION=`pip -V 2>&1 | awk '{print $6}' | awk -F '.' '{print $1}'`
if [ $PYTHON_VERSION -eq 3 ];then
    pip install nvidia-ml-py3
elif [ $PYTHON_VERSION -eq 2 ];then
    pip install nvidia-ml-py
fi
pip install enum34
pip install numpy
pip install matplotlib

OUTPUT_DIR=Profiling_dir
CONTAINER_ID="Self"
GPU_INDEX='0'
SAMPLE_PERIOD=0.02
ANALYZE_PERIOD=10
DURATION=10
BLOCKED=0
HOST_DOCKER=Host
CONTAINER_PID=-1
while getopts "c:g:o:s:a:t:w:" OPT;do
  case $OPT in
  c)
    # -c:The container id
    CONTAINER_ID=$OPTARG
    if test "$CONTAINER_ID" == "Self" || grep -q $CONTAINER_ID /proc/1/cgroup
    then
      HOST_DOCKER=Docker
    else
      CONTAINER_PID=`docker inspect -f {{.State.Pid}} $CONTAINER_ID`
    fi
    ;;
  g)
    # -g:The GPU index
    GPU_INDEX=$OPTARG
    ;;
  o)
    # -o:The output dir
    OUTPUT_DIR=./$OPTARG
    ;;
  s)
    # -s:The sample period
    SAMPLE_PERIOD=$OPTARG
    ;;
  a)
    # -a:The analyze period
    ANALYZE_PERIOD=$OPTARG
    ;;
  t)
    # -d:How long will the profile run
    DURATION=$OPTARG
    ;;
  w)
    # -t:How long will the profile waits for
    BLOCKED=$OPTARG
    ;;
  esac
done

if [ ! -d $OUTPUT_DIR ];then
  mkdir --parents $OUTPUT_DIR
fi

#if [ $IS_LOGGED -ge 1 ];then
echo 'container_id:' $CONTAINER_ID
echo 'container_pid:' $CONTAINER_PID
echo 'sample_period:' $SAMPLE_PERIOD's'
echo 'analyze_period:' $ANALYZE_PERIOD's'
echo 'platform:' $HOST_DOCKER
echo 'duration:' $DURATION'minute(s)'
echo 'output_dir:' $OUTPUT_DIR
echo 'gpu_index:' $GPU_INDEX
echo 'BLOCKED:' $BLOCKED'minute(s)'

if [ $PYTHON_VERSION -eq 3 ];then
  exec nohup python3 -u `dirname $0`/profiler.py --container_id $CONTAINER_ID --container_pid $CONTAINER_PID --sample_period $SAMPLE_PERIOD --analyze_period $ANALYZE_PERIOD --duration $DURATION --output_dir $OUTPUT_DIR --gpu_index $GPU_INDEX --blocked_time $BLOCKED >$OUTPUT_DIR/log.txt 2>&1 &
elif [ $PYTHON_VERSION -eq 2 ];then
  exec nohup python -u `dirname $0`/profiler.py --container_id $CONTAINER_ID --container_pid $CONTAINER_PID --sample_period $SAMPLE_PERIOD --analyze_period $ANALYZE_PERIOD --duration $DURATION --output_dir $OUTPUT_DIR --gpu_index $GPU_INDEX --blocked_time $BLOCKED >$OUTPUT_DIR/log.txt 2>&1 &
fi