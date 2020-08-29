# Linux payload initramfs for encrypted ZFS root

The goal of this project is to provide the simplest possible initramfs (both at
build time and run time) required to boot from an encrypted ZFS dataset. One
file provides the rules for building all included software, and the boot
sequence is driven by two short ash scripts.

This initramfs is designed to be part of a coreboot Linux payload. Since it
runs from the motherboard's SPI flash, it allows the disk/SSD to be 100%
encrypted, including the "real" kernel that this payload kexecs.

Having a 100% encrypted disk, especially when using authenticated encryption
(such as ZFS's native AES-GCM), provides some amount of "evil maid" protection.
However, this payload **does not** use a TPM to measure itself, and is
therefore vulnerable to reprogramming or physical replacement of the SPI flash
chip. If such protection is important to you, consider other projects, such as
Heads.

The original version of this project used dm-crypt and forwarded the master key
to the second stage initramfs.

The current version of this project uses ZFS native encryption and requires
unlocking the dataset twice.

With an appropriately configured kernel, the "minimal" branch of this payload
can fit on a 4MiB flash chip alongside a fallback SeaBIOS or TianoCore payload.
Otherwise, an 8MiB flash chip is required.
