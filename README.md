## IO500 Singularity Storage Benchmark

This task involves benchmarking the performance of four storage systems: CephFS (Manila), CephRBD (Cinder), Local Disk (SSD), and S3 (s3fs) in a reproducible environment provided by Singularity using IO500.

## How to run the task

Prerequisite:
- S3 storage/bucket created (this is required for s3 storage io500 test). Detail of how to create an S3 bucket can be found [here](https://confluence.skatelescope.org/pages/viewpage.action?spaceKey=SRCSC&title=Integrating+FUSE+Mount+on+S3+Buckets+with+CEPH+Storage%3A+Enabling+POSIX+Permissions+for+CARTA+and+CASA+Applications)
- Install Singularity

### Hardware requirement:

The performance of each benchmark is partly dependent on CPU speed and memory bandwidth. In general, the faster these components, the better you'll be able to evaluate the underlying storage.
A minimum of 380GB for the root disk is required for benchmarking the local root disk.


There are two options for running this task. The first option is to create the Singularity container manually. You can clone the Singularity definition file from this repository and then follow the procedure below to create the Singularity container. The second option is to run it automatically by pulling the Singularity container from the registry.

### Option 1:

Create the Singularity container manually

```bash
sudo singularity build io500-singularity.sif io500-singularity.def
```

Create directory

Choose or create a directory corresponding to the file system you intend to access. In this example, we use `/data` for CephRBD (Cinder storage), `/project` for CephFS (Manila share), `/home/azimuth/benchmark_local` for the local disk (SSD), and `/mnt/s3bucket` for S3 storage.

```bash
# for s3 storage
sudo mkdir -p /mnt/your/mount/point  # replace /your/mount/point with the folder path to mount the s3 storge
sudo chown <user>:<user> /mnt/your/mount/point  # replace user with the login user
sudo chmod 755 /your/mount/point

# for other storage, check that the storage e.g. /data, /project is mounted

```

Create a directory on the host system to store the configuration file

```bash
mkdir -p ~/io500_config
```

Create a file to store S3 access key and secret key - (This is required for S3 storage test)

Note: `s3fs` is not required to be installed on the host machine. It is already part of the software on the singularity definition file. More info on [s3fs](https://github.com/s3fs-fuse/s3fs-fuse) and how to create and mount s3 storage can be found [here](https://confluence.skatelescope.org/pages/viewpage.action?spaceKey=SRCSC&title=Integrating+FUSE+Mount+on+S3+Buckets+with+CEPH+Storage%3A+Enabling+POSIX+Permissions+for+CARTA+and+CASA+Applications).

```bash
# this is only required when testing s3 storage
echo "<access key>:<secret key>" > ~/.passwd-s3fs # replace <access key>:<secret key> with your access key and screte key
chmod 600 ~/.passwd-s3fs
```


Bind the writable directory when starting the Singularity container, where "/data" is the file system to be accessed. Binding the directory is only required if the directory to be accessed e.g. "/data" or "/mnt" is not visible within the singularity container.

```bash
sudo singularity exec --bind ~/io500_config:/opt/io500/config --bind  /data:/data io500-singularity.sif bash # replace /data with the directory corresponding to file system to be accessed
```

Inside the singularity container create a new copy of the config file

```bash
cp /opt/io500/config-minimal.ini /opt/io500/config/config.ini
```

```bash
vi /opt/io500/config/config.ini

# Add below to the `config.ini`
[global]
datadir = /data/manila_benchmark_result  # replace manila_benchmark_result with your folder name
```

Mount the s3 bucket using s3fs (This step is only required for s3 storage)

```bash
# replace /home/azimuth/.passwd-s3fs to the path on your machine
# replace "https://object.arcus.openstack.hpc.cam.ac.uk" and "arcus.openstack.hpc.cam.ac.uk" with path to your s3 storage
 s3fs <s3 bucket name> /mnt/<your-mount-point> -o passwd_file=/home/azimuth/.passwd-s3fs -o use_cache=/tmp -o url=https://object.arcus.openstack.hpc.cam.ac.uk -o endpoint=arcus.openstack.hpc.cam.ac.uk -o use_path_request_style -o nonempty
 ```

Still inside the Singularity container change directory to the file system to be accessed.
 ```bash
 cd /data/manila_benchmark_result

 # for s3 storage check if the s3 bucket has been mounted
 df -h # should return /mnt/<your-mount-point>

 cd /mnt/<your-mount-point>
```

 Run the io500 on the singularity container

 ```bash
 /opt/io500/io500 /opt/io500/config/config.ini
 ```

### Option 2:
  Run it automatically by pulling the singualarity container from the registry (This option does not work for S3 storage).

 This method runs the io500 benchmark task automatically by pulling the singularity container from the registry.

Create a directory on the host system to store the configuration file

```bash
mkdir -p ~/io500_config
```
Place the `Makefile` in working directory and run the make command, which pulls the image and runs the command

```bash
make
```


 #### Sample result

```bash

IO500 version io500-isc24_v3 (standard)
[RESULT]       ior-easy-write        0.146316 GiB/s : time 300.331 seconds
[RESULT]    mdtest-easy-write        9.456456 kIOPS : time 106.825 seconds 
[      ]            timestamp        0.000000 kIOPS : time 0.000 seconds
[RESULT]       ior-hard-write        0.180060 GiB/s : time 300.312 seconds
[RESULT]    mdtest-hard-write        8.872480 kIOPS : time 113.772 seconds 
[RESULT]                 find       22.930156 kIOPS : time 87.249 seconds
[RESULT]        ior-easy-read        0.030113 GiB/s : time 1459.005 seconds
[RESULT]     mdtest-easy-stat       48.373593 kIOPS : time 21.755 seconds
[RESULT]        ior-hard-read        0.033889 GiB/s : time 1595.174 seconds
[RESULT]     mdtest-hard-stat       38.426501 kIOPS : time 27.129 seconds
[RESULT]   mdtest-easy-delete        4.816575 kIOPS : time 208.966 seconds
[RESULT]     mdtest-hard-read        0.883227 kIOPS : time 1133.320 seconds
[RESULT]   mdtest-hard-delete       32.387150 kIOPS : time 32.189 seconds
[SCORE ] Bandwidth 0.072008 GiB/s : IOPS 12.206056 kiops : TOTAL 0.937512 
```

