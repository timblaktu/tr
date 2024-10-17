# KAS-ify Upstream Yocto Projects

## Quickstart

Run `make` after cloning and installing [dependencies](#host-dependencies) on your host. See [Make Target Explanation](#make-target-explanation) for details.

## What?
This is a prototype implementation for the automatic conversion of an arbitrary yocto project into one that supports the [kas build and configuration system](https://github.com/siemens/kas). We use the Variscite var-som-imx8mp SoM as the prototype's target platform. Variscite provides a [reference BSP: variscite-bsp-platform](https://github.com/varigit/variscite-bsp-platform/tree/mickledore) (supporting mickledore release), and [instructions for building it](https://variwiki.com/index.php?title=Yocto_Build_Release&release=mx8mp-yocto-mickledore-6.1.36_2.1.0-v1.3#Download_Yocto_Mickledore_based_on_NXP_BSP_L6.1.36_2.1.0).

## Why?

Like most SoC/SoM vendors, the BSP is based on [the BSP provided by the manufacturer of its underlying microprocessor, the NXP i.mx8mp](https://github.com/nxp-imx/meta-imx). which uses the ubiquitous but cumbersome yocto design patterns for:

1. Managing sources with [Google `repo`](https://gerrit.googlesource.com/git-repo/) xml manifests.
2. Managing configuration with files of various formats scattered throughout the working tree.

**[Kas](https://github.com/siemens/kas) is a much-needed layer of abstraction on top of yocto's complexities**, providing _sane defaults_, _intuitive and consolidated configuration management_, and _container-based builds_. To get started using kas requires manual conversion of a yocto project into [the kas configuration format](https://kas.readthedocs.io/en/latest/userguide/project-configuration.html#). This project simply automates this conversion process, attempting to **allow any yocto project to be built by kas without any manual intervention**.

As with any task automation, the benefits are amplified when you consider the frequency of the task's repetition. In lieu of making upstream contributions, Yocto best practice and software engineering experience dictates that layers shall not be modified in favor of patching out of tree or creating new layers. A primary benefit of this is to **enable the downstream yocto project to accept future upstream revisions and releases**. Therefore, downstream yocto projects are beholden to the project structure and tooling decisions made by the upstream projects they reference and use. kas is still only used in a vast minority of yocto projects.

## How?

This project uses GNU make, bash, jq, and yq. It was thrown together to demonstrate a [feature request for the kas development team](https://groups.google.com/g/kas-devel/c/Dk2AKNx0PQA), by a full-stack developer passionate about modernizing the embedded linux development stack, starting with the kas-ification of "traditional" yocto projects.

### Manual Build

It's always good when automating something to do it manually first, so let's break down the process of building a yocto distribution for the var-som-imx8mp, starting with the SoM manufacturer's [instructions](https://variwiki.com/index.php?title=Yocto_Build_Release&release=mx8mp-yocto-mickledore-6.1.36_2.1.0-v1.3#Download_Yocto_Mickledore_based_on_NXP_BSP_L6.1.36_2.1.0):

#### 1. Fetch, init, and sync the [BSP repo manifest](https://github.com/varigit/variscite-bsp-platform/blob/mickledore/imx-6.1.36-2.1.0.xml) 

```
mkdir manual && cd manual
repo init -u https://github.com/varigit/variscite-bsp-platform.git -b mickledore -m imx-6.1.36-2.1.0.xml
repo sync -j$(nproc)
```

#### 2. Setup the Build Environment

```
# I had to enter bash subshell from zsh to run this successfully
bash 
MACHINE=imx8mp-var-dart DISTRO=fsl-imx-xwayland . var-setup-release.sh build_xwayland
```

##### What just happened?

TL;DR; **This setup script created the specified `build_xwayland/` dir and generated `conf/bblayers.conf` and `conf/local.conf`. 

Here is a more detailed breakdown:

1. We just ran `var-setup-release.sh`, which is a symlink to `sources/meta-variscite-sdk-imx/scripts/var-setup-release.sh`. 
1. `sources/meta-variscite-sdk-imx/` is the path where the repo tool cloned https://github.com/varigit/meta-variscite-sdk-imx. This mapping and the symlink creation was all dictated by these elements in the manifest xml:
    ```
    <project name="meta-variscite-sdk-imx"    path="sources/meta-variscite-sdk-imx"    remote="variscite"   revision="3d0c94f6b126c121921645eb0a4abba0151ccf43" upstream="mickledore-var02">
      <linkfile src="scripts/var-setup-release.sh" dest="var-setup-release.sh"/>
      <linkfile src="dynamic-layers/var-debian/scripts/var-setup-debian.sh" dest="var-setup-debian.sh"/>
    </project>
    <remote name="variscite"   fetch="https://github.com/varigit"/>
    ```

    1. `sources/meta-variscite-sdk-imx/scripts/var-setup-release.sh` does the following:
        1. calls the corresponding imx script provided by NXP (`imx-setup-release.sh`) which generates `conf/bblayers.conf` and `conf/local.conf`.
        1. Post-processes the generated configuration files by:
            1. Removing several layer lines from `conf/bblayers.conf`.
            1. Removing an apt package management line from `conf/local.conf`.

#### 3. Do the Build

This is typically done monolithically in one command:

```
bitbake fsl-image-gui
```

Although, I prefer to separate the Pre-Fetch and Build Stages:

```
bitbake --runall fetch fsl-image-gui
bitbake fsl-image-gui
```

##### What just happened?

**TL;DR;** All the standard well-documented yocto/bitbake stuff, i.e. sources fetched, unpacked, patch, configure, build, install, and package.


### KAS-ification

[`kas checkout`](https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.checkout) takes over the responsibilities we saw in [the setup scripts above](#2-Setup-the-Build-Environment), notably the creation of `conf/bblayers.conf` and `conf/local.conf`. **Considering that running shell scripts of unknown origin are the de facto standard for configuring the yocto build environment, it's not surprising that the hardest part of automatic "KAS-ification" is _gleaning what are the desired contents of `bblayers.conf` and `local.conf`_.** 

Analogous to the cyclical evolution of software coding trends from _there is only code --> low code --> no code --> "dude, where's my code?"_, "kasification" involves transforming a code-heavy process (writing and running procedural scripts to generate configuration) into a no-code one (only declarative yaml). Until the entire yocto project and all its users adopt kas's fully declarative style for configuration management, converting setup scripts and .conf files is required.*

* it might be easier to perform a one-time conversion requiring the user to complete a traditional build first, but I'm not considering that approach.

..and to do this conversion, some assumption must be made.

#### ASSumption #1: Upstream maintainers follow all Yocto repos and layer best practices

When this is the case, it is not too wrong of me to assume that I can generate a kas.yaml from a repo xml manifest, i.e. a simple list of repos:

1. Clone the repos.
1. Parse them for defined layers and indication of which layers are to be included. (THIS IS THE TRICKY/RISKY PART!)
1. Write the details into kas.yml.
1. Use kas and henceforth never run a setup script again.
1. Profits!


# Make Target Explanation

The default make target is `kasbuild`, which is at the top of the dependency graph, i.e. it is dependent on all the other targets:

`kasbuild` --> `kasgenlayers` --> `kascheckout` --> `kasyaml` aka `$(BSP_YML)` --> `kascontainer`

In other words, `make` or `make kasbuild` causes make to walk this graph and run everything in right to left sequence.

Use `make help` for more information about the make targets.

```
Usage:  make [OPTION] ... [TARGET] ...

                    TARGET  DESCRIPTION
                     clean  Delete all intermediate files and build output (does not affect bitbake dl/sstate caches)
              kascontainer  build the kas container defined in kas.Dockerfile
                   kasyaml  alias for generating the bsp-version-specific kas config yaml file
build/imx-6.1.36-2.1.0.yml  convert repo manifest (BSP_XML) to a kas configuration yaml file,
                            sans layers which are updated in kasgenlayers after kascheckout.
                   kasdump  print the flattened kas configuration, including imports
               kascheckout  checkout repositories and set up the build directory as specified in the chosen config file
                            https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.checkout
              kasgenlayers  Parse checkout and update repos.layers in kas configuration file
                  kasbuild  Do the build.
                            https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.build
                  kasshell  Enter shell inside kas container environment.
                            https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.shell
                      help  Displays this auto-generated usage message
               listtargets  Displays a list of target names
```


# Host Dependencies

The host needs these installed. All other dependencies are handled by container environments.

## bash
https://www.gnu.org/software/bash/manual/bash.html#Installing-Bash

## GNU make
https://www.gnu.org/software/make/manual/make.html#Overview

## docker or podman
Required to manage containers.
