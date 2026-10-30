# Docker build environment for Ubuntu kernel live-patch modules

This repository contains a collection of scripts to help system owners quickly
and easily produce [kpatch](https://github.com/dynup/kpatch) modules.

Note that **kpatch itself is deprecated** as of relatively recently, having
been superseded by the [klp-build script](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/scripts/livepatch/klp-build)
in mainline.

However, many systems are still running older kernels, which remain supported
as LTS versions.

This project is _highly_ specific to Ubuntu and its derivatives: it assumes
Ubuntu's repository structure, `.config` generation scripts, Git tag format,
etc.

# How to use

## Preparation

These steps can be performed at any time:

1. Create the repository seed archives with `./create-repo-seeds.sh`. This will
   clone Canonical's forks of the kernel and produce tar files containing bare
   Git repositories. Pre-seeding the repositories into the container this way
   _significantly_ reduces the time needed to prepare the build environment
   once the container is running.
    * **Note:** you can (and should) edit this script to add/remove any Ubuntu
	  release versions and kernel repositories you do/don't rely on.
2. Build the image: `docker build -t noble-livepatch .`

## Patch time!

Uh-oh, a zero-day dropped and you have to patch everything... and fast! We'll
use [torvalds/linux@e3f33b0a1d89](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/patch/?id=e3f33b0a1d89d738e2b913dab519226eaf76e15b)
(CVE-2026-98432) as the example here.

1. Obtain the raw patch;
   `https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/patch/?id=<COMMIT>`
   is the authoritative source.
2. Create a directory named `patches` and place the patch in there.
3. Create an empty directory named `kmods`.
4. Start the container:
   `docker run --rm -it -v ./patches:/build/patches -v ./kmods:/build/kmods noble-livepatch`
5. Inside the container, extract the repository pre-seed files: `init-repos`

Now it's time to build the actual patch modules.

1. Inspect the list of patches: `list-patches`; make sure at least one shows up
2. If necessary, set the kernel version: `kver 7.0.0`
3. Set the desired patch module name: `pname cve-20xx-xxxxx`
4. Build a patch: `build-patch NNN generic`
    * `NNN` is the Ubuntu kernel patch level
	* `generic` is the Ubuntu kernel flavor

If a patch fails to apply, edit/regenerate it as necessary. Multiple variations
of a patch for different kernels are supported by naming the patch file in the
form of "patch_kver.patch." If a given kernel version doesn't have a
version-specific patch, the base patch filename is used.

For example:

* Patch files `foo.patch` and `foo_5.15.0.patch` are present
* `list-patches` outputs `foo``
* Building for kernel `6.8.0` will use `foo.patch`
* Building for kernel `5.15.0` will use `foo_5.15.0.patch`.

## Outputs

Built patches will be in `/build/kmods/KVER-REV-FLAVOR/PATCH-NAME.ko`.

# Practical example

Let's patch CVE-2026-98432 for kernel `6.8.0-147-generic`.

1. Download patch: `curl -o patches/cve-2026-98432.patch https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/patch/?id=e3f33b0a1d89d738e2b913dab519226eaf76e15b`
2. Start container: `docker run --rm -it -v ./patches:/build/patches -v ./kmods:/build/kmods noble-livepatch`
3. Set the kernel version: `kver 6.8.0`
4. Init repos: `init-repos`
5. Build the patch: `build-patch 147 generic`
6. Observe output at `/build/kmods/6.8.0-147-generic/cve-2026-98432.patch`

# Author & License

Written by Dan Fuhry <dan@fuhry.com>

Licensed under the MIT License; see COPYING for details.

