- [Description](#description)
- [Software being built by this repo](#software-being-built-by-this-repo)
- [Build Instructions](#build-instructions)
- [Test Instructions](#test-instructions)
  - [Basic sanity tests](#basic-sanity-tests)
  - [Macro benchmarks](#macro-benchmarks)
  - [Micro benchmarks](#micro-benchmarks)
- [Troubleshooting](#troubleshooting)

# Description
This is the top level repo for the paper "Retrofitting Fine Grain Isolation in the Firefox Renderer" submitted to USENIX 2020 in which we introduce the RLBox sandboxing framework. This repo will download and build all tools used in the paper, such as the multiple builds of firefox with sandboxed libraries, modified compilers, and the RLBox API.

**Note** - this repo contains code used in our research prototypes. This is **not production ready**. A production ready version of RLBox is available [here](https://github.com/PLSysSec/rlbox_sandboxing_api) with accompanying documentation [here](https://docs.rlbox.dev/). The production ready version is being used by the Firefox browser.

# Software being built by this repo

**Sandboxing_NaCl** - Contains the modified Native Client Runtime suitable for library sandboxing. It additionally, will automatically build the NaCl clang llvm compiler - again modified to make it suitable for Library Sandboxing as well as to add a flag that spits out relevant struct metadata

**Process Sandbox** - Like above but supports sandboxing using separate processes instead of native client.

**libjpeg-turbo, libpng_nacl, zlib_nacl, libtheora, libvpx, libvorbis** - Library source mostly unmodified (Some minor changes for native client compatibility in some cases). Modified build files to build with the Native Client compiler.

**NASM_NaCl** - Modified version of the nasm compiler to produce nacl compliant assembly. Required to compile the SIMD portion of libjpeg and libvpx.

**pnacl_llvm_modified pnacl_clang_modified** - Modified versions of the PNaCl Clang and LLVM toolchain to support library sandboxing. See paper for list of modifications.

**rlbox_api** - This RLBox API which helps with safe use and migration sandboxed libraries in applications.

**mozilla_firefox_stock** - Stock Firefox with some minor modifications to permit easy benchmarking.

**mozilla-release** - Modified version of firefox to use either the NaCl Sandbox or the Process Sandbox

**node.bcrypt.js** - Sandboxed use of bcrypt library in node module that provides crypto primitves.

**libmarkdown mod_markdown** - Sanboxed use of libmarkdown in the apache module for rendering markdown files as html.

**web_resource_crawler** - A firefox extension (needs Firefox 65+) that crawls the Alexa top 500, and collects information about the resources used on the web page.

**rlbox-st-test** - A webserver that is used to host image files for the sandboxing scaling test, and the webpage compression test in Firefox.

Some other repos are pulled in to assist with building or benchmarking namely "depot_tools" and "gyp" for building and "cgmemtime" for benchmarking.

# Build Instructions

**Requirements** - This repo has been tested on Ubuntu 18.04.4 LTS. Additionally, the process sandbox build of Firefox assumes you are on a machine with at least 4 cores.

**Note** - Do not use an existing machine; our setup installs/modifies packages on the machine and has been well tested on a fresh Ubuntu Install. Use a fresh VM or machine.

**Estimated build time**: Less than 24 hours

To build the repo, run

```bash
# This installs required packages on the system.
# Only need to run once per system.
make bootstrap
# load the changes
source ~/.profile
# Build the world
make
```

# Test Instructions

After building the repo, you can reproduce the tests we perform in the RLBox paper as follows.

## Basic sanity tests

We do multiple builds (around 10 different builds) of Firefox testing costs of different aspects of sandboxing. For a full list, see the Makefile and Readme of the mozilla-release repo. However, the 2 builds to focus on are  Firefox builds that use rlbox API + NaCl or Process sandboxing to sandbox libjpeg, libpng, zlib, libvorbix, libtheora, libvpx. To browse the web with these builds, run


```bash
# Run Firefox with RLBox API and NaCl sandboxing
make -C ./mozilla-release/builds run64_newnaclcpp
# Run Firefox with RLBox API and Process sandboxing
# Minimum 4 core system required
make -C ./mozilla-release/builds run64_newpscpp

```

## Macro benchmarks

1. We have a web crawler written as firefox extension that scrapes the Alexa top 500 websites and analyses the resources used by the webpage. This is written as a Firefox extension. Expected duration: 2 hours. To run

```bash
TODO
```

2. We have three builds of Firefox included --- Stock Firefox, SFI(Native Client) Firefox, Process Firefox. We have a macro benchmark that measure page load times and memory overheads on these three builds on 11 representative sites on different builds. Expected duration: 0.5 days. To run

```bash
cd ./mozilla-release
./newRunMacroPerfTest ~/Desktop/rlbox_macro_logs
```


## Micro benchmarks

**Caveats**

- Note that many of these benchmarks are run with a very large number of iterations, on a variety of different media so that we can report realistic numbers. Thus each one of these tasks below can take the better part of a day and upto a day and a half. I have indicated the expected time below. I will also provide instructions to reduce the number of iterations for the purpose of the artifact eval, but note that this may affect the numbers as benchmarks will be more prone to noise.

- Specific choices during machine setup were made to reduce noise during benchmarks, namely disabling hyper-threading, disabling dynamic frequency scaling and pinning the CPU to a low frequency which will not introduce thermal throttling, isolating the CPUs on which we run tests using the isolcpus boot kernel parameter and running Ubuntu without a GUI and running the benchmarks on headless Firefox. Part of this setup is automated in the file ``microBenchmarkTestSetup'' in this repo. If you decide not to do this setup, this will likely result in the reported numbers being more noisy than reported.
- If running on a VM, it is unlikely some of the benchmarking setup listed in the prior bullet will work particularly well. In particular, the video benchamark and measurements are quite unreliable in this setting.

1. We also have micro benchmarks on the same three builds performed on four classes of libraries ---- image libraries, audio libraries, video libraries, webpage decompression. Each of these have separate micro benchmarks that are included in the artifact. We start with images, for which we measure the decoding times for the three Firefox builds on a variety of jpegs and pngs in different formats.  Expected duration: 1.5 days. To run

```bash
cd ./mozilla-release
./newRunMicroImageTest ~/Desktop/rlbox_micro_image_logs
```

2. We continue the microbenchmark with evaluating webpage decompression with zlib. Expected duration: 1.5 days. To run

```bash
cd ./mozilla-release
./newRunMicroZlibTest ~/Desktop/rlbox_micro_compression_logs
```

3. We continue the microbenchmark with evaluating audio and video performance by measuring Vorbis audio bit rate and  throughput on a high quality audio file measuring VPX and Theora bit rate throughput on a high quality video file on the three Firefox builds. Expected duration: 1.5 hours.

```bash
cd ./mozilla-release
./newRunMicroAVTest ~/Desktop/rlbox_micro_audiovideo_logs
```

4. We also have scaling tests which separately test the total number of sandboxes that can reasonably be created and measure image decoding times for the same. Expected duration: 1.5 days.

In a separate terminal first run
```bash
cd ./rlbox-st-test/ && node server.js
```

then run,
```bash
cd ./mozilla-release
./newRunMicroImageScaleTest ~/Desktop/rlbox_micro_scaling_logs
```

5. We also evaluate use of our sandboxing techniques outside of firefox by measuring throughput of two other applications. We first evaluate the throughput of a crypto module in node.js. Expected duration: 0.5 days.

```bash
cd ./node.bcrypt.js
make bench
```

6. Continuing the prior evaluation, we also evaluate the throughput of apache web server's markdown to html conversion. Expected duration: 0.25 days

```bash
cd ./mod_markdown
make bench
```

7. We also provide a benchmark of a sandboxing the Graphite font library (using a WASM based SFI) which has been upstreamed and is currently in Firefox nightly. This is easiest to test directly with the nightly builds made available by Mozilla. Download the nightly build with the sandboxed font library [here](https://ftp.mozilla.org/pub/firefox/nightly/2020/01/2020-01-03-20-22-40-mozilla-central/firefox-73.0a1.en-US.linux-x86_64.tar.bz2) and a build from a nightly that does not have this, available [here](https://ftp.mozilla.org/pub/firefox/nightly/2020/01/2020-01-01-09-29-38-mozilla-central/firefox-73.0a1.en-US.linux-x86_64.tar.bz2). Visit the following [webpage](https://jfkthame.github.io/test/udhr_urd.html) which runs a micro benchmark on Graphite fonts on both builds. Expected duration: 15 mins.


# Troubleshooting

1. If you see the error "Could not create new sub-cgroup /sys/fs/cgroup/memory/cgmemtime/2179: No such file or directory", run the following

```bash
cd ./cgmemtime && sudo ./cgmemtime --setup -g $(USER) --perm 775
```

2. If you see the error "taskset: failed to set pid 2231's affinity: Invalid argument", you are running on a machine with less than 4 cores. A limitation of the code here is that we assume a minimum of 4 cores. If you are in a VM, assign more cores.

3. When running the apache benchmark, if you see the error "35 errors (0 timeouts)", apache configuration has messed up. A workaround here is to run the following in a new terminal.
```bash
sudo apache2ctl stop
sudo bash
/usr/sbin/apache2ctl -DFOREGROUND
# Leave this terminal running and re-attempt to run the apache benchmarks.
```
