TARGET = x86_64-linux-musl

modules-y += busybox
modules-y += coreboot
modules-y += kexec-tools
modules-y += libaio
modules-y += libtirpc
modules-y += linux
modules-y += musl
modules-y += openssl
modules-y += util-linux
modules-y += zfs
modules-y += zlib

prebuilt-y += etc/secondstage
prebuilt-y += etc/initramfs.list
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

initramfs.list: linux staging $(modules-y) $(prebuilt-y)
	sysroot/bin/gen_initramfs -u squash -g squash staging > $@.tmp && mv $@.tmp $@

sources:
	mkdir -p $@

stageclean:
	rm -fr *-build/.staged initramfs.cpio.* initramfs.list staging

staging:
	mkdir -p $@ $@/bin $@/boot $@/dev $@/etc $@/lib $@/proc $@/run $@/sys $@/tmp
	for sym in mount sh umount; do \
	  ln -fs busybox staging/bin/$$sym; \
	done

sysroot:
	mkdir -p $(CURDIR)/sysroot/bin
	mkdir -p $(CURDIR)/sysroot/$(TARGET)/bin
	ln -fs bin $(CURDIR)/sysroot/$(TARGET)/sbin

$(modules-y): | sources staging sysroot
	$(MAKE) -f Makefile.build MODULE=$@ TARGET=$(TARGET) stage

$(prebuilt-y): staging/%: prebuilt/% | staging
	cp $< $@
