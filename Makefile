TARGET = x86_64-linux-musl

CONFIG_COREBOOT = y
CONFIG_ZFS = y

modules-y += busybox
modules-$(CONFIG_COREBOOT) += coreboot
modules-$(CONFIG_COREBOOT) += kexec-tools
modules-n += libaio
modules-n += libtirpc
modules-y += linux
modules-n += musl
modules-n += openssl
modules-n += util-linux
modules-$(CONFIG_ZFS) += zfs
modules-n += zlib

prebuilt-$(CONFIG_COREBOOT) += etc/secondstage
prebuilt-$(CONFIG_COREBOOT) += etc/initramfs.list
prebuilt-y += init
prebuilt-y := $(addprefix staging/,$(prebuilt-y))

all: initramfs.cpio.lz4

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
openssl: musl
pciutils: musl
petitboot: eudev musl lvm2 ncurses openssl
util-linux: musl
zfs: libaio libtirpc musl openssl util-linux zlib
zlib: musl

clean: stageclean
	rm -fr *-build sysroot

distclean: clean
	rm -fr sources

initramfs.cpio.lz4: initramfs.list linux
	sysroot/bin/gen_init_cpio -t 0 $< | lz4 -l --best --favor-decSpeed > $@.tmp && mv $@.tmp $@

initramfs.cpio.xz: initramfs.list linux
	sysroot/bin/gen_init_cpio -t 0 $< | xz -9 --check=crc32 > $@.tmp && mv $@.tmp $@

initramfs.list: tools/initramfs.list linux staging $(modules-y) $(prebuilt-y)
	sysroot/bin/gen_initramfs -u squash -g squash staging > $@.tmp && cat $< >> $@.tmp && mv $@.tmp $@

sources staging:
	mkdir -p $@

stageclean:
	rm -fr *-build/.staged initramfs.cpio.* initramfs.list staging

sysroot:
	mkdir -p $(CURDIR)/sysroot/bin
	mkdir -p $(CURDIR)/sysroot/$(TARGET)/bin
	ln -fs bin $(CURDIR)/sysroot/$(TARGET)/sbin

$(modules-y) $(modules-n): | sources staging sysroot
	$(MAKE) -f Makefile.build MODULE=$@ TARGET=$(TARGET) stage

$(prebuilt-y): staging/%: prebuilt/% | staging
	mkdir -p $(dir $@)
	cp $< $@
