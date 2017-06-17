TARGET = x86_64-linux-musl

modules-y = attr busybox coreboot cryptsetup flashrom kexec-tools pciutils libtirpc linux lvm2 musl outils popt util-linux xz zfs zlib
prebuilt-y = init etc/initramfs.list

all: initramfs.cpio.xz

attr: musl
busybox: musl
coreboot: musl
cryptsetup: lvm2 musl popt util-linux
flashrom: pciutils musl
kexec-tools: musl xz zlib
pciutils: musl
libtirpc: musl
linux: musl
lvm2: musl
outils: musl
popt: musl
util-linux: musl
xz: musl
zfs: attr libtirpc musl util-linux zlib
zlib: musl

clean: stageclean
	rm -fr *-build sysroot

distclean: clean
	rm -fr musl-cross-make sources

initramfs.cpio.xz: initramfs.list linux
	sysroot/$(TARGET)/bin/gen_init_cpio -t 0 $< | xz --check=crc32 --lzma2=dict=1MiB > $@.tmp && mv $@.tmp $@

initramfs.list: linux staging $(modules-y) $(prebuilt-y)
	sysroot/$(TARGET)/bin/gen_initramfs_list -u squash -g squash staging > $@.tmp && mv $@.tmp $@

musl-cross-make:
	git clone https://github.com/richfelker/musl-cross-make

sources:
	mkdir -p $@

stageclean:
	rm -fr *-build/.staged initramfs.cpio.xz initramfs.list staging

staging:
	mkdir -p $@ $@/bin $@/dev $@/etc $@/lib $@/proc $@/sys
	ln -fs busybox staging/bin/mount
	ln -fs busybox staging/bin/sh
	ln -fs busybox staging/bin/umount

sysroot: musl-cross-make
	$(MAKE) -C musl-cross-make OUTPUT=$(CURDIR)/sysroot TARGET=$(TARGET) install
	ln -fs bin $(CURDIR)/sysroot/$(TARGET)/sbin

$(modules-y): | sources staging sysroot
	$(MAKE) -f Makefile.build MODULE=$@ TARGET=$(TARGET) stage

$(prebuilt-y): %: prebuilt/% | staging
	cp $< staging/$@
