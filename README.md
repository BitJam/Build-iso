# Build-iso
   
RUN:

    $ ./build-iso

See the README.Template file in the Template directory for more
information about files in the Template directory.


General Operation
-----------------
The work of build-iso is split up into 8 different stages.
When each stages is successfully completed, a stage-N.out file is
created in the Output/ directory.  Each time build-iso is
run, it will start working on the first stage that lacks an
output file.  These files also let the program pass information
for one stage to the next across restarts.  Therefore there is
almost no penalty for stopping the program after each stage.  If
there is an error condition then the penalty for stopping the
program, fixing the error, and then restarting the program is
minimized.

The 10 stages of processing are:
  0. Gather inputs and set defaults
  1. Make directories and symlinks
  2. Run debootstrap
  3. Prepare chroot
  4. Inside of chroot
  5. Finalize and clean the chroot
  6. Prepare iso directory
  7. Create squashfs file
  8. Create iso file
  9. Clean up and prepare to start over

The most complicated stage is "4: Inside the chroot".  This is
also the most time consuming stage because this is when *.deb
packages get installed.  So Stage 4 is broken up into parts:

 0. Read PARTIAL file to skip parts done
 1. Update repos and do apt-get update
 2. Search for complete kernel name
 3. Define locales
 4. Install basic packages
 5. Install kernel & headers
 6. Update locales
 7. Install pesky packages
 8. Install antiX packages
 9. Run first apt-get -f install
 10. Install latest antiX debs
 11. Remove some packages
 12. Add some packages
 13. Reinstall some packages
 14. Update runlevels based on flavour
 15. Get Latest Flash
 16. Manual configuration
 17. Update Timezone, hostname, and user accounts
 18. Run second apt-get -f install
 19. Update SLiM defaults
 20. Apply Theme
 21. Check kernel's GCC version

These parts are not automatically skipped if they have already
been performed but the most time consuming parts (installing
packages) go by very quickly if the packages have already been
installed.  You can use environment variables to manually skip
parts.  See "Debugging Options" for details.


Environment Variables
---------------------
The architecture (386 or x64) and the flavour (core-libre, base,
or file) can be set via the ARCH and ISO_FLAV environment
variables.  If they are not set via these environment variables
then the user is prompt form them in Stage 0.  These two
variables let the build-iso-all script build isos
for all architectures and flavours without minimal user
intervention or no user intervention at all.

Debugging Options
-----------------


Directories
-----------
Unlike most programs that live in a directory that is on the
PATH, the directory this program is in has special significance.
It is called the script directory and that is where it expects
to find the Template/ directory and where it creates creates
other directories, symlinks and files.

Variables in the DEFAULTS file
------------------------------
If needed information is missing from the DEFAULTS file then
the user will be prompted for it in Stage 0.

```
  ADD_BORDER_OPTS  Use these options when adding border to live image
     APT_GET_OPTS  Options sent to apt-get.  Don't change.
            CACHE  Enable caches by name.  Only "debootstrap" available ATM.
     CACHE_EXPIRE  Expire cache entries after this many days
        CODE_NAME  The name of this version of the distro
   DEBIAN_RELEASE  stable|testing|unstable
      DISTRO_NAME  "antiX" or your choice
   DISTRO_VERSION  A version number with numerals and dots
   ENABLE_LOCALES  All|Default|Single
         HOSTNAME  "antiX1" or your choice
      ISO_SYMLINK  If this is a symlink, update it to point to iso file
       K_REVISION  "*" or your choice of a number
       K_TEMPLATE  Template for creating kernel names.  Change with care.
        K_VERSION  Version number of the kernel to use or "*" for latest
        LIVE_USER  Default username on the iso
           LOCALE  Default locale iso the iso
     LOCAL_MIRROR  Mirror closest to you
           MIRROR  Mirror on the iso
     RELEASE_DATE  Leave blank for today or your choice
      RESPIN_FLAV  See Custom Flavours below
        TIME_ZONE  Timezone for the iso
  X_TERM_EMULATOR  Default X teminal emulator.
```

Custom Flavours
---------------
You are allowed to create your own flavour names just by making
a subdirectory of Template/ and copying files into it.  Your
new flavour MUST be based on one of the existing flavours:

```
    core, or base, or full
```

The reason for this is these existing names are connected with
repos names and the names of certain antiX Debian packages.
