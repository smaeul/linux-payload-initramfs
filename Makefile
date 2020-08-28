TARGET = x86_64-linux-musl

modules-y += busybox
modules-y += coreboot
modules-y += eudev
modules-y += flashrom
modules-y += kexec-tools
modules-y += libaio
modules-y += libtirpc
modules-y += linux
modules-y += lvm2
modules-y += musl
modules-y += ncurses
modules-y += openssl
modules-y += pciutils
modules-y += petitboot
modules-y += util-linux
modules-y += zfs
modules-y += zlib

prebuilt-y += etc/secondstage
prebuilt-y += etc/initramfs.list
prebuilt-y += init
prebuilt-y := $(addprefix staging/,$(prebuilt-y))

all: initramfs.cpio.xz

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
	rm -fr musl-cross-make sources

initramfs.cpio.xz: initramfs.list linux
	sysroot/bin/gen_init_cpio -t 0 $< | xz -9 --check=crc32 > $@.tmp && mv $@.tmp $@

initramfs.list: linux staging $(modules-y) $(prebuilt-y)
	sysroot/bin/gen_initramfs -u squash -g squash staging > $@.tmp && mv $@.tmp $@

musl-cross-make:
	git clone https://github.com/richfelker/musl-cross-make

sources:
	mkdir -p $@

stageclean:
	rm -fr *-build/.staged initramfs.cpio.xz initramfs.list staging

staging:
	mkdir -p $@ $@/bin $@/boot $@/dev $@/etc $@/lib $@/proc $@/run $@/sys $@/tmp
	for sym in cp ip mount sh tftp udhcpc udhcpc6 umount wget; do \
	  ln -fs busybox staging/bin/$$sym; \
	done

sysroot: musl-cross-make
	$(MAKE) -C musl-cross-make OUTPUT=$(CURDIR)/sysroot TARGET=$(TARGET) install
	ln -fs bin $(CURDIR)/sysroot/$(TARGET)/sbin

$(modules-y): | sources staging sysroot
	$(MAKE) -f Makefile.build MODULE=$@ TARGET=$(TARGET) stage

$(prebuilt-y): staging/%: prebuilt/% | staging
	cp $< $@
