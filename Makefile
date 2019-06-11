DEPOT_TOOLS_PATH := $(shell realpath ./depot_tools)
export PATH := $(DEPOT_TOOLS_PATH):$(PATH)

.NOTPARALLEL:
.PHONY : build_deps build32 build64 pull clean

.DEFAULT_GOAL := build64

DIRS=build_deps depot_tools gyp Sandboxing_NaCl libjpeg-turbo NASM_NaCl mozilla-release ProcessSandbox libpng_nacl zlib_nacl rlbox-st-test rlbox_api wasm-sandboxing emsdk wasm_llvm


builds_deps:
	sudo apt -y install python-setuptools autoconf libtool libc6-dev-i386 libseccomp-dev libseccomp-dev:i386 clang llvm cmake ninja-build

depot_tools :
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $@

gyp :
	git clone https://chromium.googlesource.com/external/gyp.git $@
	cd gyp && sudo python setup.py install

Sandboxing_NaCl :
	git clone https://github.com/shravanrn/Sandboxing_NaCl.git $@

libjpeg-turbo :
	git clone https://github.com/shravanrn/libjpeg-turbo_nacltests.git $@
	cd libjpeg-turbo && git checkout 1.4.x

libpng_nacl:
	git clone https://github.com/shravanrn/libpng_nacl.git $@
	cd libpng_nacl && git checkout 1.6.31

zlib_nacl:
	git clone https://github.com/shravanrn/zlib_nacl.git $@

NASM_NaCl :
	git clone https://github.com/shravanrn/NASM_NaCl.git $@

mozilla-release :
	git clone https://github.com/shravanrn/mozilla_firefox_nacl.git $@

ProcessSandbox :
	git clone https://bitbucket.org/cdisselkoen/sandbox-benchmarking $@

rlbox-st-test:
	git clone https://github.com/PLSysSec/rlbox-st-test.git

rlbox_api:
	git clone https://github.com/shravanrn/rlbox_api.git

wasm-sandboxing:
	git clone --recursive https://github.com/shravanrn/wasm-sandboxing.git

wasi-sysroot:
	git clone --recursive https://github.com/CraneStation/wasi-sysroot wasi-sysroot-src
	cd wasi-sysroot-src && make WASM_CC=clang WASM_NM=llvm-nm WASM_AR=llvm-ar INSTALL_DIR=../wasi-sysroot install
	rm -rf wasi-sysroot-src

CLANG_ROOT ?= /usr/lib/clang/8.0.0

lucet: wasi-sysroot
	git clone --recursive https://github.com/fastly/lucet.git
	cd lucet && git submodule update --init
	export WASI_SYSROOT=$(realpath wasi-sysroot) CLANG_ROOT=$(CLANG_ROOT) && cd lucet && cargo build --release


emsdk:
	git clone https://github.com/juj/emsdk.git
	#Build emscripten
	cd emsdk && ./emsdk install --enable-wasm --build=Debug latest emscripten-incoming-64bit && ./emsdk activate --enable-wasm --build=Debug latest emscripten-incoming-64bit
	cd ./emsdk/emscripten/incoming && git remote add myremote https://github.com/shravanrn/emscripten_lp64 && git fetch myremote && git checkout -b myremote --track myremote/incoming
	cd emsdk && ./emsdk activate --enable-wasm --build=Debug latest emscripten-incoming-64bit
	#Use custom clang-llvm for emscripten
	echo "LLVM_ROOT='$(realpath ./wasm_llvm/build/bin/)'" >> ~/.emscripten

wasm_llvm:
	git clone https://github.com/shravanrn-dupforks/wasm_llvm.git wasm_llvm
	cd ./wasm_llvm/tools && git clone https://github.com/shravanrn-dupforks/wasm_clang.git clang
	cd ./wasm_llvm/tools && git clone https://github.com/llvm-mirror/lld.git lld
	cd ./wasm_llvm/tools/clang/tools && git clone https://github.com/shravanrn/rlbox_structdump/ structdump
	echo "add_clang_subdirectory(structdump)" >> ./wasm_llvm/tools/clang/tools/CMakeLists.txt
	mkdir -p ./wasm_llvm/build && cd ./wasm_llvm/build && cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug -DLLVM_TARGETS_TO_BUILD= -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly ../

build32: $(DIRS)
	$(MAKE) -C mozilla-release/builds inithasrun
	cd NASM_NaCl && ./configure
	$(MAKE) -C NASM_NaCl
	$(MAKE) -C Sandboxing_NaCl buildopt32 buildopt64
	$(MAKE) -C libjpeg-turbo/builds build32  # just the builds, not the examples
	$(MAKE) -C ProcessSandbox all32
	$(MAKE) -C zlib_nacl/builds build
	$(MAKE) -C libpng_nacl/builds build
	$(MAKE) -C libjpeg-turbo/builds all32  # now the examples as well
	$(MAKE) -C mozilla-release/builds build32

build64: $(DIRS)
	$(MAKE) -C mozilla-release/builds inithasrun
	cd NASM_NaCl && ./configure
	$(MAKE) -C NASM_NaCl
	$(MAKE) -C Sandboxing_NaCl buildopt32 buildopt64
	$(MAKE) -C wasm_llvm/build
	$(MAKE) -C wasm-sandboxing/builds build64
	$(MAKE) -C libjpeg-turbo/builds build64  # just the builds, not the examples
	$(MAKE) -C zlib_nacl/builds build
	$(MAKE) -C libpng_nacl/builds build
	$(MAKE) -C ProcessSandbox all64
	$(MAKE) -C libjpeg-turbo/builds all64  # now the examples as well
	$(MAKE) -C mozilla-release/builds minbuild64

pull: $(DIRS)
	git pull
	cd Sandboxing_NaCl && git pull
	cd libjpeg-turbo && git pull
	cd zlib_nacl && git pull
	cd libpng_nacl && git pull
	cd mozilla-release && git pull
	cd ProcessSandbox && git pull
	cd NASM_NaCl && git pull
	cd rlbox-st-test && git pull
	cd rlbox_api && git pull
	cd wasm-sandboxing && git pull
	cd emsdk && git pull
	cd wasm_llvm && git pull
	cd wasm_llvm/tools/clang && git pull

clean:
	-$(MAKE) -C Sandboxing_NaCl clean
	-$(MAKE) -C libjpeg-turbo/builds clean
	-$(MAKE) -C zlib_nacl/builds clean
	-$(MAKE) -C libpng_nacl/builds clean
	-$(MAKE) -C mozilla-release/builds clean
	-$(MAKE) -C ProcessSandbox clean
	-$(MAKE) -C NASM_NaCl clean
	-$(MAKE) -C wasm-sandboxing/builds clean
	-$(MAKE) -C wasm_llvm/build clean
