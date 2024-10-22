SHELL := bash

# Generate/include/export common vars to make
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT_DIR)scripts
uninteresting_stdout := $(shell env -i $(SCRIPT_DIR)/mkenv)
$(info $(uninteresting_stdout))
include $(ROOT_DIR)make.env 

# Variables for fetching dependent files from kas upstream for 
# local test and integration of kas features in this project
KAS_UPSTREAM_BASE_URL := https://raw.githubusercontent.com/timblaktu/kas/refs/heads/kas-container-improvements
KAS_UPSTREAM_REL_FILE_PATHS := kas-container container-entrypoint tests/test_menu/Kconfig
KAS_UPSTREAM_FILE_URLS := $(addprefix $(KAS_UPSTREAM_BASE_URL)/, $(KAS_UPSTREAM_REL_FILE_PATHS))
KAS_UPSTREAM_LOCAL_BASE_PATH := $(BUILD_DIR)/kas-upstream
KAS_UPSTREAM_LOCAL_EXEC_PATHS := $(addprefix $(KAS_UPSTREAM_LOCAL_BASE_PATH)/, kas-container container-entrypoint)
KAS := $(KAS_UPSTREAM_LOCAL_BASE_PATH)/kas-container --log-level warning

.EXPORT_ALL_VARIABLES:

define recipehdr
@printf "\n$(BLUE)============================================================================\n==>$(RESET) Recipe $(YELLOW)$@$(RESET)  triggered by newer pre-reqs: $(GREEN)$?$(RESET)\n\n"
endef

.DEFAULT_GOAL := kasbuild
.PHONY: clean kasmenu kasupstreamfiles kascontainer kasconf kasdump kascheckout kasbuild kasshell

clean:  ## Delete all intermediate files and build output (does not affect bitbake dl/sstate caches)
	@rm ${ROOT_DIR}/.env ${ROOT_DIR}/make.env
	@rm -rf ${BUILD_DIR}
	@rm -rf ${SOURCE_DIR}

make.env:
	@$(call recipehdr $@)
	env -i $(SCRIPT_DIR)/mkenv

$(BUILD_DIR):
	@mkdir -p ${BUILD_DIR}

$(KAS_UPSTREAM_LOCAL_BASE_PATH):
	@$(call recipehdr $@)
	@mkdir -p $(KAS_UPSTREAM_LOCAL_BASE_PATH)
	@printf "Fetching files from kas repository %s into %s..\n" \
		"$(KAS_UPSTREAM_BASE_URL)" "$(KAS_UPSTREAM_LOCAL_BASE_PATH)"
	@wget -q -P $(KAS_UPSTREAM_LOCAL_BASE_PATH) $(KAS_UPSTREAM_FILE_URLS) 
	@chmod 755 $(KAS_UPSTREAM_LOCAL_EXEC_PATHS)
	@ls -l $(KAS_UPSTREAM_LOCAL_BASE_PATH) | sed 's/^/    /g'

kasmenu:
	@$(call recipehdr $@)
	$(KAS) menu	$(KAS_UPSTREAM_LOCAL_BASE_PATH)/Kconfig

kascontainer: make.env kas.Dockerfile scripts/mkascontainer $(KAS_UPSTREAM_LOCAL_BASE_PATH)  ## build the kas container defined in kas.Dockerfile
	@$(call recipehdr $@)
	./scripts/mkascontainer 2>&1 

kasconf: $(KAS_YML)  ## alias for generating the kas config yaml file by name

$(KAS_YML): $(BUILD_DIR) scripts/mkasconf kascontainer ## convert a super-repo URL (repo-tool manifest or git super-repo) 
$(KAS_YML): $(BUILD_DIR) scripts/mkasconf kascontainer ## to a kas configuration yaml file
	@$(call recipehdr $@)
	$(KAS) runcmd ./scripts/mkasconf $(REPO_MANIFEST_URL) $(REPO_MANIFEST_BRANCH) $(REPO_MANIFEST_FILENAME) $(SETUP_ENV) 2>&1

kasdump: $(KAS_YML)  ## print the flattened kas configuration, including imports
	@$(call recipehdr $@)
	$(KAS) dump $(KAS_YML) 2>&1 

kascheckout: $(KAS_YML)  ## checkout repositories and set up the build directory as specified in the chosen config file
kascheckout: $(KAS_YML)  ## https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.checkout
	@$(call recipehdr $@)
	$(KAS) checkout $(KAS_YML) 2>&1 

kasbuild: kasgenlayers  ## Do the build.
kasbuild: kasgenlayers  ## https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.build
	@$(call recipehdr $@)
	$(KAS) --runtime-args "-e TOPDIR=/build -e BB_VERBOSE_LOGS -e BBINCLUDELOGS" build $(KAS_YML) 2>&1  # BBINCLUDELOGS_LINES

kasshell:  ## Enter shell inside kas container environment.
kasshell:  ## https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.shell
	@$(call recipehdr $@)
	$(KAS) shell $(KAS_YML)

# Generate help output. awk splits lines into target name and comment, prints them,
# omitting any target names already printed on previous lines. column beautifies.
help:  ## Displays this auto-generated usage message
	@$(KAS) runcmd /work/scripts/mkhelp $(MAKEFILE_LIST) 2>&1 

listtargets:  ## Displays a list of target names
	@make -rpn | sed -ne '/^$$/ {n; /^[^ .#][^ ]*:/ {s/:.*$$//;p;}; }' | tr '\n' ' ' 

