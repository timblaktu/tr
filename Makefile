SHELL := bash

# generate/include/export common vars to make
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT_DIR)scripts
uninteresting_stdout := $(shell env -i $(SCRIPT_DIR)/mkenv)
$(info $(uninteresting_stdout))
# $(info Env File:)
# $(shell $(cat $(ROOT_DIR)make.env))
include $(ROOT_DIR)make.env 
# $(foreach v, $(filter-out $(VARS_OLD) VARS_OLD,$(.VARIABLES)), $(info $(v) = $($(v))))
.EXPORT_ALL_VARIABLES:

define recipehdr
    @printf "\n$(BLUE)============================================================================\n==>$(RESET) Running Make Recipe $(YELLOW)$@$(RESET)\n\n"
endef

.DEFAULT_GOAL := kasbuild
.PHONY: clean kascontainer kasyaml kasdump kascheckout kasgenlayers kasbuild kasshell

clean:  ## Delete all intermediate files and build output (does not affect bitbake dl/sstate caches)
	rm ${ROOT_DIR}/.env ${ROOT_DIR}/make.env
	rm -rf ${BUILD_DIR}
	rm -rf ${SOURCE_DIR}

kascontainer: kas.Dockerfile scripts/mkascontainer  ## build the kas container defined in kas.Dockerfile
	@$(call recipehdr $@)
	./scripts/mkascontainer 2>&1 

$(BUILD_DIR):
	mkdir -p ${BUILD_DIR}

kasyaml: $(BSP_YML)  ## alias for generating the bsp-version-specific kas config yaml file

$(BSP_YML): $(BSP_XML) $(BUILD_DIR) scripts/mkasyml kascontainer  ## convert repo manifest (BSP_XML) to a kas configuration yaml file,
$(BSP_YML): $(BSP_XML) $(BUILD_DIR) scripts/mkasyml kascontainer  ## sans layers which are updated in kasgenlayers after kascheckout.
	@$(call recipehdr $@)
	./scripts/mkasyml 2>&1 

kasdump: $(BSP_YML)  ## print the flattened kas configuration, including imports
	@$(call recipehdr $@)
	$(KAS) dump $(BSP_YML) 2>&1 

kascheckout: $(BSP_YML)  ## checkout repositories and set up the build directory as specified in the chosen config file
kascheckout: $(BSP_YML)  ## https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.checkout
	@$(call recipehdr $@)
	$(KAS) checkout $(BSP_YML) 2>&1 

kasgenlayers: kascheckout  ## Parse checkout and update repos.layers in kas configuration file
	@$(call recipehdr $@)
	$(KAS) shell $(BSP_YML) -c "bash --login /work/scripts/updatelayers" 2>&1 

kasbuild: kasgenlayers  ## Do the build.
kasbuild: kasgenlayers  ## https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.build
	@$(call recipehdr $@)
	$(KAS) --runtime-args "-e TOPDIR=/build -e BB_VERBOSE_LOGS -e BBINCLUDELOGS" build $(BSP_YML) 2>&1  # BBINCLUDELOGS_LINES

kasshell:  ## Enter shell inside kas container environment.
kasshell:  ## https://kas.readthedocs.io/en/latest/userguide/plugins.html#module-kas.plugins.shell
	@$(call recipehdr $@)
	$(KAS) shell $(BSP_YML)

# Generate help output. awk splits lines into target name and comment, prints them,
# omitting any target names already printed on previous lines. column beautifies.
help:  ## Displays this auto-generated usage message
	@printf "\nUsage:  make [OPTION] ... [$${GREEN}TARGET$${RESET}] ...\n\n" \
		&& grep -Eh '^[^#]*\s##\s' $(MAKEFILE_LIST) \
		| awk -v GREEN="$${GREEN}" -v RESET="$${RESET}" -F ":.*?## " ' \
		{ \
			if (!target_name_already_printed) { target_name_already_printed=foo; } \
			if (target_name_already_printed == $$1) { target=" "; } else { target=$$1; } \
			printf "%s%s%s@%s\n", GREEN, target, RESET, $$2; \
			target_name_already_printed = $$1; \
		}' \
		| sed 's/\$$(\([a-zA-Z_][a-zA-Z_0-9]*\))/$${\1}/g' \
		| envsubst \
		| column -t -s@ -o'  ' --keep-empty-lines \
			--table-columns TARGET,DESCRIPTION \
			--table-right 1 \
			--table-wrap 2

listtargets:  ## Displays a list of target names
	@make -rpn | sed -ne '/^$$/ {n; /^[^ .#][^ ]*:/ {s/:.*$$//;p;}; }' | tr '\n' ' ' 

