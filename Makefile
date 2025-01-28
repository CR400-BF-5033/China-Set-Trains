# general
-include Makefile.config
# tools, sprites, lang, code entries need to be specified in Makefile.config
# though the Makefile itself provides default values that can be used if
# following the build instructions in README.md (using scoop to install the tools)
#
# You can override the default values by specifying them in Makefile.config
# this would be useful if e.g. you manually compiled gorender and it's not in your PATH

# tools
PYTHON ?= python3

# sprites

# this default value assumes you have renderobject in your PATH
GORENDER  ?= renderobject --palette "ttd_palette.json" -overwrite
VOX_DIR   ?= gfx/*
PALETTE   ?= ttd_palette.json
MANIFEST  ?= manifest.json

# lang
LANG_SCRIPT ?= ./str-csv.py
LANG_SRC    ?= docs/str.csv

# code
NMLC ?= nmlc -c
GCC  ?= gcc
INDEX_FILE ?= chinasettrains.pnml
OUTPUT_NML ?= chinasettrains.nml
OUTPUT_GRF ?= chinasettrains.grf
CUSTOM_TAG_FILE ?= custom_tags.txt

# version
-include Makefile.dist
REPO_REVISION       ?= 1       # specify in Makefile.dist
REPO_VERSION_STRING ?= 0.0.1.1 # specify in Makefile.dist

.PHONY: all sprites custom_tags code clean clean_grf clean_png

# default rule
all: sprites lang code

# voxel paths
VOX_FILES = $(wildcard $(VOX_DIR)/*.vox wildcard $(VOX_DIR)/*/*.vox)

VOX_8BPP_FILES = $(addsuffix _8bpp.png, $(basename $(VOX_FILES)))
VOX_32BPP_FILES = $(addsuffix _32bpp.png, $(basename $(VOX_FILES)))
VOX_MASK_FILES = $(addsuffix _mask.png, $(basename $(VOX_FILES)))

VOX_GENREATED_FILES = $(VOX_8BPP_FILES) $(VOX_32BPP_FILES) $(VOX_MASK_FILES)

%_8bpp.png %_32bpp.png %_mask.png: %.vox
	@echo "Rendering, manifest = $(dir $<)/$(MANIFEST), palette = $(dir $<)/$(PALETTE), $<"
	@$(GORENDER) -m $(dir $<)/$(MANIFEST) --palette $(dir $<)/$(PALETTE) $<

# sprites
sprites: $(VOX_GENREATED_FILES)

# lang
lang:
	@echo "Generating lang files"
	@$(PYTHON) $(LANG_SCRIPT) $(LANG_SRC)

# code
custom_tags:
	@echo "Generating custom tags"
	@echo "VERSION_STRING :$(REPO_VERSION_STRING)" > $(CUSTOM_TAG_FILE)

code: custom_tags
	@echo "Preprocessing"
	@$(GCC) -E -x c -D REPO_REVISION=$(REPO_REVISION) -D VERSION_STRING=$(REPO_VERSION_STRING) $(INDEX_FILE) > $(OUTPUT_NML)
	@echo "Compiling"
	@$(NMLC) $(OUTPUT_NML) -o $(OUTPUT_GRF)

# clean
clean: clean_grf clean_png

clean_grf:
	@echo "Cleaning GRF and NML files"
	@echo "Warning: clean grf won't work when using powershell, please use bash instead."
	@rm -f *.grf
	@rm -f *.nml
	@rm -f $(CUSTOM_TAG_FILE)

clean_png:
	@echo "Cleaning PNG files"
	@echo "Warning: clean png won't work when using powershell, please use bash instead."
	@find $(VOX_DIR)/ -name '*.png' -type f -delete
