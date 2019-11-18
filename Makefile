TARGET = x86_64-linux-musl

modules-y += busybox
modules-y += coreboot
modules-y += flashrom
modules-y += kexec-tools
modules-y += pciutils
modules-y += libaio
modules-y += libtirpc
modules-y += linux
modules-y += musl
modules-y += openssl
modules-y += util-linux
modules-y += xz
modules-y += zfs
modules-y += zlib

prebuilt-y += etc/secondstage
prebuilt-y += etc/initramfs.list
prebuilt-y += init
prebuilt-y := $(addprefix staging/,$(prebuilt-y))

all: initramfs.cpio.xz

busybox: musl
coreboot: musl
flashrom: pciutils musl
kexec-tools: musl xz zlib
pciutils: musl
libaio: musl
libtirpc: musl
linux: musl
openssl: zlib musl
util-linux: musl
xz: musl
zfs: libaio libtirpc musl openssl util-linux zlib
zlib: musl

clean: stageclean
	rm -fr *-build sysroot

distclean: clean
	rm -fr musl-cross-make sources

initramfs.cpio.xz: initramfs.list linux
	sysroot/bin/gen_init_cpio -t 0 $< | xz -9 --check=crc32 > $@.tmp && mv $@.tmp $@

initramfs.list: linux staging $(modules-y) $(prebuilt-y)
	sysroot/bin/gen_initramfs_list -u squash -g squash staging > $@.tmp && mv $@.tmp $@

musl-cross-make:
	git clone https://github.com/richfelker/musl-cross-make

sources:
	mkdir -p $@

stageclean:
	rm -fr *-build/.staged initramfs.cpio.xz initramfs.list staging

staging:
	mkdir -p $@ $@/bin $@/boot $@/dev $@/etc $@/lib $@/proc $@/sys
	ln -fs busybox staging/bin/mount
	ln -fs busybox staging/bin/sh

sysroot: musl-cross-make
	$(MAKE) -C musl-cross-make OUTPUT=$(CURDIR)/sysroot TARGET=$(TARGET) install
	ln -fs bin $(CURDIR)/sysroot/$(TARGET)/sbin

$(modules-y): | sources staging sysroot
	PATH=$(CURDIR)/sysroot/bin:$(PATH); $(MAKE) -f Makefile.build MODULE=$@ TARGET=$(TARGET) stage

$(prebuilt-y): staging/%: prebuilt/% | staging
	cp $< $@
