# Where the installed tree lives.  Override on the command line:
#   make install prefix=$HOME/.local
prefix ?= /usr/local
bindir ?= $(prefix)/bin
datarootdir ?= $(prefix)/share
datadir ?= $(datarootdir)
vmcreatedir ?= $(datadir)/vmc
DESTDIR ?=

# Template location used by the build targets.  Empty means "the generated
# generator already finds its own tree", i.e. this source directory.
VMCREATE_SHARE ?=

GENERATOR = bash ./vmc-generate-boot
ifneq ($(strip $(VMCREATE_SHARE)),)
GENERATOR += --share $(VMCREATE_SHARE)
endif

EXAMPLES = ubuntu windows freedos server

.PHONY: all check examples install install-templates uninstall clean

all: examples

check:
	mkdir -p build/test-results
	cd build/test-results && DEJAGNU="$(CURDIR)/testsuite/site.exp" runtest --tool vmcreate --srcdir ../..

examples:
	@for name in $(EXAMPLES); do \
	    $(GENERATOR) examples/$$name.m4 build/$$name/boot.sh || exit 1; \
	done

# The installed generator reads templates from $(vmcreatedir), so installing
# only the script would leave it without m4/ and boot.sh.in.
install: install-templates
	install -d "$(DESTDIR)$(bindir)"
	install -m 0755 vmc-generate-boot vmc-wizard "$(DESTDIR)$(bindir)"
	install -d "$(DESTDIR)$(vmcreatedir)/examples"
	install -m 0644 LICENSE MACROS.md TEMPLATE.md README.md "$(DESTDIR)$(vmcreatedir)"
	install -m 0644 examples/*.m4 "$(DESTDIR)$(vmcreatedir)/examples"
	sed -i 's|root=$${VMCREATE_SHARE:-$$script_dir}|root=$${VMCREATE_SHARE:-$(vmcreatedir)}|' \
	    "$(DESTDIR)$(bindir)/vmc-generate-boot"

install-templates:
	install -d "$(DESTDIR)$(vmcreatedir)/m4"
	install -m 0644 m4/vm.m4 m4/hardware.m4 m4/network.m4 m4/control.m4 \
	    "$(DESTDIR)$(vmcreatedir)/m4"
	install -m 0644 boot.sh.in "$(DESTDIR)$(vmcreatedir)"

uninstall:
	rm -f "$(DESTDIR)$(bindir)/vmc-generate-boot" "$(DESTDIR)$(bindir)/vmc-wizard"
	rm -rf "$(DESTDIR)$(vmcreatedir)"

clean:
	rm -rf build
