DMD	:= dmd
RDMD	:= rdmd
DDOC	:= $(DMD) -w -c -o- -version=StdDoc

ASSETSDIR	:= assets
SASSDIR	:= $(ASSETSDIR)/sass
TMPLDIR	:= $(ASSETSDIR)/template

# Ignores _*.scss files
SASSSRC	:= $(filter-out $(SASSDIR)/_%.scss, $(wildcard $(SASSDIR)/*.scss))
TMPLSRC	:= $(wildcard $(TMPLDIR)/*.ddoc)

BUILDDIR	:= build
BUILDCSSDIR	:= $(BUILDDIR)/css
STYLES	:= $(patsubst $(SASSDIR)/%.scss, $(BUILDCSSDIR)/%.css, $(SASSSRC))

SRCDIR	:= ../source


PACKAGES	:= battery
PACKAGE_battery	:= d


################################################################################
# Functions
################################################################################

# Returns all modules in package
# Example:
#	PACKAGES = mypackage
#	PACKAGE_mypackage = yay boi
#	$(call P2MODULES,$(PACKAGES)) # mypackage/yay mypackage/boi
P2MODULES	= $(foreach P,$1, $(addprefix $P/,$(PACKAGE_$(subst /,_,$P))))
# Module to html file name
# Example:
#	mypackage/yay -> mypackage_yay.html
#	
D2HTML	= $(foreach p,$1,$(if $(subst package.d,,$(notdir $p)),$(subst /,_,$(subst .d,.html,$p)),$(subst /,_,$(subst /package.d,.html,$p))))

MODULES	= $(call P2MODULES,$(PACKAGES))
HTMLS	= $(addprefix $(BUILDDIR)/,$(call D2HTML,$(addsuffix .d,$(MODULES))))

define MAKEMODULE
$(BUILDDIR)/$(call D2HTML,$(addsuffix .d,$1))	:\
$(addprefix $(SRCDIR)/,$(addsuffix .d,$1)) $(BUILDDIR) $(TMPLSRC)
	@echo "Module $1 documentation:"
	@echo "	$$< -> $$@"
	@$(DDOC) $(TMPLSRC) -I$(SRCDIR) -Df$$@ $$<
endef

all	: css html

$(foreach k,$(MODULES),$(eval $(call MAKEMODULE,$(k))))

$(BUILDCSSDIR)/%.css	: $(SASSDIR)/%.scss $(BUILDCSSDIR)
	@echo "Compiling sass: $< -> $@"
	@sassc -I $(SASSDIR) $< $@

$(BUILDDIR)	:
	@mkdir -p $@

$(BUILDCSSDIR)	: $(BUILDDIR)
	@mkdir -p $@

#LATEST	:= $(git describe --abbrev=0 --tags | sed 's/v//')

.PHONY	: clean css html
clean	:
	rm -rf $(BUILDDIR)

css	: $(STYLES)
html	: $(HTMLS)
