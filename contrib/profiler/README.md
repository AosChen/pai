# Overview
The profiler can collect the usage of the hardware while your model is
running, analyze the utilization of them, and give the pattern of these
information.
# Usage
Please use the shell file `run.sh` to start the Profiler.  
##### Estimate the blocked time.
Sometimes the deep-learing model will prepare the data when it starts
running. If the profiler is run with the model together, it may sample
the data that when the GPU is not training. So you can set the time to
make the profiler blocked until your deep-learning model training. But
different models have the different blocked time, you need to estimate
the blocked time of your model.
##### Insert the profiler in your command
When you submit a job, you insert the profiler command before your
command to use the profiler.  
```bash
apt update
apt install -y git
git clone https://github.com/AosChen/pai.git
bash pai/contrib/profiler/run.sh -w 3 -t 10
# your other command
``` 
The above command means that the profiler will sample for 10 minutes and
it will be executed after 3 minutes.  
Here is the explanation of the profiler command.

```bash
./run.sh
    [-c <container_id>]
    [-g <gpu index>]
    [-o <output dir>]
    [-s <sample period>]
    [-a <analyze period>]
    [-t <time to run>]
    [-w <waiting/blocked time>]
```
**run.sh** can receive 7commands.
1. `-c`: To assign the container that you want to analyze. The parameter
   is the SHA of the container. It is no need to input the complete SHA,
   the conflict prefix is enough. Such as `run.sh -c 234d`.  
   If not set, the default is the container that profiler in.  
   **Attention**: If you use the profiler by inserting the command,
   please not set the command.
2. `-g`:To assign the GPU that you want to analyze. The parameter is the
   GPU index(separated by , if there is multiple cards). Such as run.sh
   -g 0,1,2,3.   
   If not set, the default GPU index is the GPU 0.
3. `-o`:To assign the output directory of the analyze result. The
   parameter must be a **String**, such as `run.sh -o Output_Data`, it
   means the analyze result will be stored at ./Output_Data.  
   If not set, the default directory is ./Profiling_dir.
4. `-s`: To assign the peroid of each sample. The parameter must be a
   **number**, such as `run.sh -s 0.03`, it means the profiler will
   sample the data each 0.03s.  
   If not set, the default sampling peroid is 0.02s.
5. `-a`: To assign how often to analyze the sampling data. The parameter
   must be a **number**, such as `run.sh -a 5`, it means the profiler
   will analyze the data each 5s.  
   If not set, the default analyzing period is 10s.
6. `-t`: To assign how long the profiler will run. The parameter must be
   a **number**, such as `run.sh -t 30`, it means that the profiler will
   run for 30 minutes.  
   If not set, the default time is 10 minutes.
7. `-w`: To assign how long the profiler will be blocked. The parameter
   must be a **number**, such as `run.sh -w 20`, it means the profiler
   will run after 20 minutes.  
   If not set, the profiler will not be blocked.