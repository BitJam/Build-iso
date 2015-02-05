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

The 8 stages of processing are:

  0: Gather inputs and set defaults
  1: Run debootstrap
  2: Prepare chroot
  3: Inside of chroot
  4: Prepare squashfs and iso directories
  5: Create squashfs file
  6: Create iso file
  7: Clean up and prepare to start over

The most complicated stage is "3: Inside the chroot".  This is
also the most time consuming stage because this is when *.deb
packages get installed.  So Stage 3 is broken up into 12 parts:

  0: Update repos and do apt-get update
  1: Search for complete kernel name
  2: Update locales
  3: Install basic applications
  4: Install pesky applications
  5: Install antiX applications
  6: Install kernel & headers
  7: Install latest antiX debs
  8: Update runlevels based on flavour
  9: Manual configuration
 10: Update Timezone, hostname, and user accounts
 11: Update SLiM defaults

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

Custom Flavours
---------------
You are allowed to create your own flavour names just by making
a subdirectory of Template/ and copying files into it.  Your
new flavour MUST be based on one of the existing flavours:

    core, or base, or full

The reason for this is these existing names are connected with
repos names and the names of certain antiX Debian packages.
