SHELL := bash

# generate/include/export common vars to make
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT_DIR)scripts
uninteresting_stdout := $(shell env -i $(SCRIPT_DIR)/mkenv)
# $(info $(uninteresting_stdout))
# $(info Env File:)
# $(shell $(cat $(ROOT_DIR)make.env))
include $(ROOT_DIR)make.env 
# $(foreach v, $(filter-out $(VARS_OLD) VARS_OLD,$(.VARIABLES)), $(info $(v) = $($(v))))
.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := kasbuild
.PHONY: clean kascontainer kasyaml kasdump kascheckout kasgenlayers kasbuild kasshell

clean:
	rm ${ROOT_DIR}/.env ${ROOT_DIR}/make.env
	rm -rf ${BUILD_DIR}
	rm -rf ${SOURCE_DIR}

kascontainer: kas.Dockerfile scripts/mkascontainer
	./scripts/mkascontainer

$(BUILD_DIR):
	mkdir -p ${BUILD_DIR}

# alias for generating the bsp-version-specific kas config yaml file
kasyaml: $(BSP_YML) 

$(BSP_YML): $(BSP_XML) $(BUILD_DIR) scripts/mkasyml kascontainer
	./scripts/mkasyml

kasdump: $(BSP_YML)
	$(KAS) dump $(BSP_YML)

kascheckout: $(BSP_YML)
	$(KAS) checkout $(BSP_YML)

kasgenlayers: kascheckout
	$(KAS) shell $(BSP_YML) -c "bash --login /work/scripts/updatelayers"

kasbuild: kasgenlayers
	$(KAS) --runtime-args "-e TOPDIR=/build" build $(BSP_YML)

kasshell: 
	$(KAS) shell $(BSP_YML)

# # Generate help output. awk splits lines into target name and comment, prints them,
# # omitting any target names already printed on previous lines. column beautifies.
# help:  ## Displays this auto-generated usage message
# 	@printf "\nUsage:  make [OPTION] ... [$${GREEN}TARGET$${RESET}] ...\n\n" \
# 		&& grep -Eh '^[^#]*\s##\s' $(MAKEFILE_LIST) \
# 		| awk -v GREEN="$${GREEN}" -v RESET="$${RESET}" -F ":.*?## " ' \
# 		{ \
# 			if (!target_name_already_printed) { target_name_already_printed=foo; } \
# 			if (target_name_already_printed == $$1) { target=" "; } else { target=$$1; } \
# 			printf "%s%s%s@%s\n", GREEN, target, RESET, $$2; \
# 			target_name_already_printed = $$1; \
# 		}' \
# 		| sed 's/\$$(\([a-zA-Z_][a-zA-Z_0-9]*\))/$${\1}/g' \
# 		| envsubst \
# 		| column -t -s@ -o'  ' \
# 			-C name="$${UNDER}TARGET$${RESET}",right \
# 			-C name="$${UNDER}DESCRIPTION$${RESET}",left,wrap
# 
# listtargets:  ## Displays a list of target names
# 	@make -rpn | sed -ne '/^$$/ {n; /^[^ .#][^ ]*:/ {s/:.*$$//;p;}; }' | tr '\n' ' ' 
# 
