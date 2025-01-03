export TARGET = x86_64-linux-musl

export CONFIG_NOMMU = n
export CONFIG_COREBOOT = y
export CONFIG_TESTS = n
export CONFIG_ZFS = y

modules-y += busybox
modules-$(CONFIG_COREBOOT) += coreboot
modules-$(CONFIG_TESTS) += coremark
modules-$(CONFIG_COREBOOT) += kexec-tools
modules-n += libaio
modules-n += libtirpc
modules-y += linux
modules-n += musl
modules-n += numactl
modules-n += openssl
modules-$(CONFIG_TESTS) += rt-tests
modules-$(CONFIG_TESTS) += stress-ng
modules-$(CONFIG_NOMMU) += toybox
modules-n += util-linux
modules-$(CONFIG_ZFS) += zfs
modules-n += zlib

prebuilt-$(CONFIG_COREBOOT) += etc/secondstage
prebuilt-$(CONFIG_COREBOOT) += etc/initramfs.list
prebuilt-y := $(addprefix staging/,$(prebuilt-y))

all: initramfs-$(TARGET).cpio.lz4

busybox: musl
coreboot: musl
eudev: musl
flashrom: musl pciutils
kexec-tools: musl
libaio: musl
libtirpc: musl
linux: musl
lvm2: musl
ncurses: musl
numactl: musl
openssl: musl
pciutils: musl
petitboot: eudev musl lvm2 ncurses openssl
rt-tests: musl numactl
toybox: musl
util-linux: musl
zfs: libaio libtirpc musl openssl util-linux zlib
zlib: musl

clean: stageclean
	rm -fr *-build sysroot

distclean: clean
	rm -fr sources

initramfs-$(TARGET).cpio.lz4: initramfs.list linux
	sysroot/bin/gen_init_cpio -t 0 $< | lz4 -l --best --favor-decSpeed > $@.tmp && mv $@.tmp $@

initramfs-$(TARGET).cpio.xz: initramfs.list linux
	sysroot/bin/gen_init_cpio -t 0 $< | xz -9 --check=crc32 > $@.tmp && mv $@.tmp $@

initramfs.list: tools/initramfs.list linux staging staging/init $(modules-y) $(prebuilt-y)
	sysroot/bin/gen_initramfs -u squash -g squash staging > $@.tmp && cat $< >> $@.tmp && mv $@.tmp $@

sources:
	mkdir -p $@

staging:
	mkdir -p $@/bin $@/lib

staging/init: prebuilt/init$(if $(filter y,$(CONFIG_COREBOOT)),-coreboot) | staging
	cp $< $@

stageclean:
	rm -fr *-build/.staged initramfs-$(TARGET).cpio.* initramfs.list staging

sysroot:
	mkdir -p $(CURDIR)/sysroot/bin $(CURDIR)/sysroot/$(TARGET)/bin
	ln -fs bin $(CURDIR)/sysroot/$(TARGET)/sbin

$(modules-y) $(modules-n): | sources staging sysroot
	$(MAKE) -f Makefile.build MODULE=$@ stage

$(prebuilt-y): staging/%: prebuilt/% | staging
	mkdir -p $(dir $@)
	cp $< $@
