# Build an Incompatible Upstream Yocto Project with KAS

This is a prototype implementation for the automatic conversion of an arbitrary yocto project into one that supports the [kas build and configuration system](https://github.com/siemens/kas).

The target platform is the Variscite var-som-imx8mp SoM. The manufacturer provides a reference BSP [variscite-bsp-platform](https://github.com/varigit/variscite-bsp-platform/tree/mickledore) (supporting mickledore release). 

The SoM BSP is largely based on [the BSP provided by the manufacturer of its underlying microprocessor, the NXP i.mx8mp](https://github.com/nxp-imx/meta-imx), which uses the ubiquitous but cumbersome yocto design patterns for:

1. Managing sources with [Google `repo`](https://gerrit.googlesource.com/git-repo/) xml manifests.
2. Managing configuration with files of various formats scattered throughout the working tree.

**[Kas](https://github.com/siemens/kas) is a much-needed layer of abstraction on top of yocto's complexities**, providing _sane defaults_, _intuitive and consolidated configuration management_, and _container-based builds_. To get started using kas requires manual conversion of a yocto project into [the kas configuration format](https://kas.readthedocs.io/en/latest/userguide/project-configuration.html#). This project simply automates this conversion process, attempting to **allow any yocto project to be built by kas without any manual intervention**.

As with any task automation, the benefits are amplified when you consider the frequency of the task's repetition. In lieu of making upstream contributions, Yocto best practice and software engineering experience dictates that layers shall not be modified in favor of patching out of tree or creating new layers. A primary benefit of this is to **enable the downstream yocto project to accept future upstream revisions and releases**. Therefore, downstream yocto projects are beholden to the project structure and tooling decisions made by the upstream projects they reference and use. kas is still only used in a vast minority of yocto projects.

This build system prototype is based on GNU make, bash, jq, and yq. It was thrown together to demonstrate a [feature request for the kas development team](https://groups.google.com/g/kas-devel/c/Dk2AKNx0PQA), by a full-stack developer passionate about modernizing the embedded linux development stack, starting with the kas-ification of yocto.

# Quickstart

Run `make` after cloning and installing [dependencies](#Dependencies) on your host. This will:

1. 


## Dependencies

The host needs these installed.

### bash
https://www.gnu.org/software/bash/manual/bash.html#Installing-Bash

### GNU make
https://www.gnu.org/software/make/manual/make.html#Overview

### column (util-linux) <= v2.39
Currently only needed for [the `-C` option](https://github.com/util-linux/util-linux/blob/stable/v2.39/text-utils/column.1.adoc) used by `make help`.

### jq
https://github.com/jqlang/jq/releases/latest

### yq
https://github.com/mikefarah/yq/releases/latest

