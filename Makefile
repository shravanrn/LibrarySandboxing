export PATH := ./depot_tools:$(PATH)

.PHONY : build32 build64 pull clean

.DEFAULT_GOAL : build64

DIRS=depot_tools gyp Sandboxing_NaCl libjpeg-turbo nasm-2.13 mozilla-release ProcessSandbox

depot_tools :
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

gyp :
	sudo apt install python-setuptools
	git clone https://chromium.googlesource.com/external/gyp.git
	cd gyp && sudo python setup.py install

Sandboxing_NaCl :
	git clone https://github.com/shravanrn/Sandboxing_NaCl.git

libjpeg-turbo :
	git clone https://github.com/shravanrn/libjpeg-turbo_nacltests.git libjpeg-turbo

nasm-2.13 :
	git clone https://github.com/shravanrn/NASM_NaCl.git nasm-2.13
	cd nasm-2.13 && ./configure
	$(MAKE) -C nasm-2.13

mozilla-release :
	git clone https://github.com/shravanrn/mozilla_firefox_nacl.git mozilla-release

ProcessSandbox :
	git clone https://bitbucket.com/cdisselkoen/sandbox_benchmarking.git ProcessSandbox

build32: $(DIRS)
	$(MAKE) -C Sandboxing_NaCl buildopt32
	$(MAKE) -C libjpeg-turbo/builds all32
	$(MAKE) -C mozilla-release build32
	$(MAKE) -C ProcessSandbox all32

build64: $(DIRS)
	$(MAKE) -C Sandboxing_NaCl buildopt64
	$(MAKE) -C libjpeg-turbo/builds all64
	$(MAKE) -C mozilla-release build64
	$(MAKE) -C ProcessSandbox all64

pull: $(DIRS)
	cd Sandboxing_NaCl && git pull
	cd libjpeg-turbo && git pull
	cd mozilla-release && git pull
	cd ProcessSandbox && git pull
	cd nasm-2.13 && git pull

clean:
	-$(MAKE) -C Sandboxing_NaCl clean
	-$(MAKE) -C libjpeg-turbo/builds clean
	-$(MAKE) -C mozilla-release clean
	-$(MAKE) -C ProcessSandbox clean
	-$(MAKE) -C nasm-2.13 clean
