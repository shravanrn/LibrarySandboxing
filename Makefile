DEPOT_TOOLS_PATH := $(shell realpath ./depot_tools)
export PATH := $(DEPOT_TOOLS_PATH):$(PATH)

.NOTPARALLEL:
.PHONY : build_deps build pull clean

.DEFAULT_GOAL := build64

DIRS=build_deps depot_tools gyp Sandboxing_NaCl libjpeg-turbo NASM_NaCl mozilla-release ProcessSandbox libpng_nacl zlib_nacl libtheora libvpx rlbox-st-test rlbox_api web_resource_crawler node.bcrypt.js

builds_deps:
	sudo apt -y install python-setuptools autoconf libtool libseccomp-dev clang llvm cmake ninja-build npm nodejs cloc

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
	cd $@ && git checkout 1.6.31

zlib_nacl:
	git clone https://github.com/shravanrn/zlib_nacl.git $@

libtheora:
	git clone https://github.com/shravanrn/libtheora.git $@

libvpx:
	git clone https://github.com/shravanrn/libvpx.git $@
	cd $@ && git checkout ff_custom

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

web_resource_crawler:
	git clone https://github.com/shravanrn/web_resource_crawler.git

node.bcrypt.js:
	git clone https://github.com/PLSysSec/node.bcrypt.js

build: $(DIRS)
	$(MAKE) -C mozilla-release/builds inithasrun
	cd NASM_NaCl && ./configure
	$(MAKE) -C NASM_NaCl
	$(MAKE) -C Sandboxing_NaCl buildopt64
	$(MAKE) -C libjpeg-turbo/builds build64  # just the builds, not the examples
	$(MAKE) -C zlib_nacl/builds build
	$(MAKE) -C libpng_nacl/builds build
	$(MAKE) -C libtheora/builds build
	$(MAKE) -C libvpx/builds build
	$(MAKE) -C ProcessSandbox all64
	$(MAKE) -C libjpeg-turbo/builds all64  # now the examples as well
	$(MAKE) -C mozilla-release/builds minbuild64
	$(MAKE) -C node.bcrypt.js build

pull: $(DIRS)
	git pull
	cd Sandboxing_NaCl && git pull
	cd libjpeg-turbo && git pull
	cd zlib_nacl && git pull
	cd libpng_nacl && git pull
	cd libtheora && git pull
	cd libvpx && git pull
	cd mozilla-release && git pull
	cd ProcessSandbox && git pull
	cd NASM_NaCl && git pull
	cd rlbox-st-test && git pull
	cd rlbox_api && git pull
	cd web_resource_crawler && git pull
	cd node.bcrypt.js && git pull

clean:
	-$(MAKE) -C Sandboxing_NaCl clean
	-$(MAKE) -C libjpeg-turbo/builds clean
	-$(MAKE) -C zlib_nacl/builds clean
	-$(MAKE) -C libpng_nacl/builds clean
	-$(MAKE) -C libtheora/builds clean
	-$(MAKE) -C libvpx/builds clean
	-$(MAKE) -C mozilla-release/builds clean
	-$(MAKE) -C ProcessSandbox clean
	-$(MAKE) -C NASM_NaCl clean
	-$(MAKE) -C node.bcrypt.js clean
