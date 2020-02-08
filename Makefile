DEPOT_TOOLS_PATH := $(shell realpath ./depot_tools)
export PATH := $(DEPOT_TOOLS_PATH):$(PATH)

.NOTPARALLEL:
.PHONY : build pull clean install_sys_pkg install_deps

.DEFAULT_GOAL := build

SHELL := /bin/bash

DIRS=depot_tools gyp Sandboxing_NaCl libjpeg-turbo NASM_NaCl mozilla-release mozilla_firefox_stock ProcessSandbox libpng_nacl zlib_nacl libtheora libvpx libvorbis rlbox-st-test rlbox_api web_resource_crawler node.bcrypt.js libmarkdown mod_markdown cgmemtime pnacl_llvm_modified pnacl_clang_modified

install_sys_pkg:
	sudo apt -y install curl python-setuptools autoconf libtool libseccomp-dev clang llvm cmake ninja-build libssl1.0-dev npm nodejs cloc flex bison git texinfo gcc-7-multilib g++-7-multilib build-essential libtool automake libmarkdown2-dev linux-libc-dev:i386 nasm cpufrequtils apache2 apache2-dev
	sudo npm install -g autocannon
	curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.37.0 -y
	source ~/.profile
	# Need for some of the nacl compile tools
	if [ ! -e "/usr/include/asm" ]; then \
		sudo ln -s /usr/include/asm-generic /usr/include/asm; \
	fi
	touch ./install_sys_pkg

install_deps: install_sys_pkg $(DIRS)
	# build cgmemtime to setup the permissions group
	$(MAKE) -C cgmemtime
	if  [ ! -e "/sys/fs/cgroup/memory/cgmemtime" ]; then \
		cd ./cgmemtime && sudo ./cgmemtime --setup -g $(USER) --perm 775; \
	fi
	# bootstrap firefox
	$(MAKE) -C mozilla-release/builds initbootstrap
	# skip rebootstrapping for firefox stock
	touch mozilla_firefox_stock/builds/initbootstrap
	# install markdown
	$(MAKE) -C libmarkdown all
	sudo $(MAKE) -C libmarkdown install
	$(MAKE) -C mod_markdown
	sudo $(MAKE) -C mod_markdown install
	sudo apache2ctl start
	touch ./install_deps

depot_tools :
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $@

gyp :
	git clone https://chromium.googlesource.com/external/gyp.git $@
	cd gyp && sudo python setup.py install

Sandboxing_NaCl :
	git clone git@github.com:shravanrn/Sandboxing_NaCl.git $@

libjpeg-turbo :
	git clone git@github.com:shravanrn/libjpeg-turbo_nacltests.git $@
	cd libjpeg-turbo && git checkout 1.4.x

libpng_nacl:
	git clone git@github.com:shravanrn/libpng_nacl.git $@
	cd $@ && git checkout 1.6.31

zlib_nacl:
	git clone git@github.com:shravanrn/zlib_nacl.git $@

libtheora:
	git clone git@github.com:shravanrn/libtheora.git $@

libvpx:
	git clone git@github.com:shravanrn/libvpx.git $@
	cd $@ && git checkout ff_custom

libvorbis:
	git clone git@github.com:shravanrn/libvorbis.git $@

NASM_NaCl :
	git clone git@github.com:shravanrn/NASM_NaCl.git $@
	cd $@ && ./configure

mozilla-release :
	git clone git@github.com:shravanrn/mozilla_firefox_nacl.git $@

mozilla_firefox_stock:
	git clone git@github.com:shravanrn/mozilla_firefox_nacl.git $@
	cd $@ && git checkout vanilla

ProcessSandbox :
	git clone https://bitbucket.org/cdisselkoen/sandbox-benchmarking $@

rlbox-st-test:
	git clone git@github.com:PLSysSec/rlbox-st-test.git

rlbox_api:
	git clone git@github.com:shravanrn/rlbox_api.git

web_resource_crawler:
	git clone git@github.com:shravanrn/web_resource_crawler.git

node.bcrypt.js:
	git clone git@github.com:PLSysSec/node.bcrypt.js.git

libmarkdown:
	git clone git@github.com:PLSysSec/libmarkdown.git
	cd $@ && ./configure.sh --shared

mod_markdown:
	git clone git@github.com:plsyssec/mod_markdown.git

cgmemtime:
	git clone git@github.com:shravanrn/cgmemtime.git

pnacl_llvm_modified:
	git clone git@github.com:shravanrn/nacl-llvm.git $@

pnacl_clang_modified:
	git clone git@github.com:shravanrn/nacl-clang.git $@

build: install_deps $(DIRS)
	$(MAKE) -C NASM_NaCl
	# Separate copy of pnacl_llvm_modified and pnacl_clang_modified built as part of Sandboxing_NaCl
	$(MAKE) -C Sandboxing_NaCl buildopt64
	$(MAKE) -C libjpeg-turbo/builds build64  # just the builds, not the examples
	$(MAKE) -C zlib_nacl/builds build64
	$(MAKE) -C libpng_nacl/builds build64
	$(MAKE) -C libtheora/builds build
	$(MAKE) -C libvpx/builds build
	$(MAKE) -C libvorbis/builds build
	$(MAKE) -C ProcessSandbox all64
	$(MAKE) -C libjpeg-turbo/builds all64  # now the examples as well
	$(MAKE) -C mozilla-release/builds minbuild64
	$(MAKE) -C mozilla_firefox_stock/builds build
	$(MAKE) -C node.bcrypt.js build

pull: $(DIRS)
	git pull
	cd cgmemtime && git pull
	cd pnacl_llvm_modified && git pull
	cd pnacl_clang_modified && git pull
	cd Sandboxing_NaCl && git pull
	cd libjpeg-turbo && git pull
	cd zlib_nacl && git pull
	cd libpng_nacl && git pull
	cd libtheora && git pull
	cd libvpx && git pull
	cd libvorbis && git pull
	cd mozilla-release && git pull
	cd ProcessSandbox && git pull
	cd NASM_NaCl && git pull && ./configure
	cd rlbox-st-test && git pull
	cd rlbox_api && git pull
	cd web_resource_crawler && git pull
	cd node.bcrypt.js && git pull
	cd libmarkdown && git pull && ./configure.sh
	cd mod_markdown && git pull

clean:
	-$(MAKE) -C cgmemtime clean
	-$(MAKE) -C Sandboxing_NaCl clean
	-$(MAKE) -C libjpeg-turbo/builds clean
	-$(MAKE) -C zlib_nacl/builds clean
	-$(MAKE) -C libpng_nacl/builds clean
	-$(MAKE) -C libtheora/builds clean
	-$(MAKE) -C libvpx/builds clean
	-$(MAKE) -C libvorbis/builds clean
	-$(MAKE) -C mozilla-release/builds clean
	-$(MAKE) -C mozilla_firefox_stock/builds clean
	-$(MAKE) -C ProcessSandbox clean
	-$(MAKE) -C NASM_NaCl clean
	-$(MAKE) -C node.bcrypt.js clean
	-$(MAKE) -C libmarkdown clean
	-$(MAKE) -C mod_markdown clean