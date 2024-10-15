# tr
This is the project summary.

## Dependencies

### jq
https://github.com/jqlang/jq/releases/latest

### yq
https://github.com/mikefarah/yq/releases/latest

# Kas format

```
# Every file needs to contain a header, that provides kas with information
# about the context of this file.
header:
  # The `version` entry in the header describes for which configuration
  # format version this file was created for. It is used by kas to figure
  # out if it is compatible with this file. The version is an integer that
  # is increased on every format change.
  version: x
# The machine as it is written into the `local.conf` of bitbake.
machine: qemux86-64
# The distro name as it is written into the `local.conf` of bitbake.
distro: poky
repos:
  # This entry includes the repository where the config file is located
  # to the bblayers.conf:
  meta-custom:
  # Here we include a list of layers from the poky repository to the
  # bblayers.conf:
  poky:
    url: "https://git.yoctoproject.org/git/poky"
    commit: 89e6c98d92887913cadf06b2adb97f26cde4849b
    layers:
      meta:
      meta-poky:
      meta-yocto-bsp:
```
