# DO NOT EDIT.
#
# This Makefile came from Zilla::Dist. To upgrade it, run:
#
#   > make upgrade
#

.PHONY: cpan test

PERL_S := $(shell which perl) -S
ZILD := $(PERL_S) zild

ifneq (,$(shell which zild))
    NAME := $(shell $(ZILD) meta name)
    VERSION := $(shell $(ZILD) meta version)
    RELEASE_BRANCH := $(shell $(ZILD) meta branch)
else
    NAME := No-Name
    VERSION := 0
    RELEASE_BRANCH := master
endif

DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz
NAMEPATH := $(subst -,/,$(NAME))
SUCCESS := "$(DIST) Released!!!"

default: help

help:
	@echo ''
	@echo 'Makefile targets:'
	@echo ''
	@echo '    make test      - Run the repo tests'
	@echo '    make install   - Install the repo'
	@echo '    make update    - Update generated files'
	@echo '    make release   - Release the dist to CPAN'
	@echo ''
	@echo '    make cpan      - Make cpan/ dir with dist.ini'
	@echo '    make cpanshell - Open new shell into new cpan/'
	@echo '    make cpantest  - Make cpan/ dir and run tests in it'
	@echo ''
	@echo '    make dist      - Make CPAN distribution tarball'
	@echo '    make distdir   - Make CPAN distribution directory'
	@echo '    make distshell - Open new shell into new distdir'
	@echo '    make disttest  - Run the dist tests'
	@echo ''
	@echo '    make upgrade   - Upgrade the build system (Makefile)'
	@echo '    make readme    - Make the ReadMe.pod file'
	@echo '    make travis    - Make a travis.yml file'
	@echo ''
	@echo '    make clean     - Clean up build files'
	@echo '    make help      - Show this help'
	@echo ''

test:
ifeq ($(wildcard pkg/no-test),)
	prove -lv test
else
	@echo "Testing not available. Use 'disttest' instead."
endif

install: distdir
	(cd $(DISTDIR); perl Makefile.PL; make install)
	make clean

update: makefile
	make readme contrib travis version

release: clean update check-release test disttest
	make dist
	[ -n "$$(git status -s)" ] && git commit -am '$(VERSION)'
	cpan-upload $(DIST)
	git push
	git tag $(VERSION)
	git push --tag
	make clean
	git status
	@echo
	@[ -n "$$(which cowsay)" ] && cowsay "$(SUCCESS)" || echo "$(SUCCESS)"
	@echo

cpan:
	zild-make-cpan

cpanshell: cpan
	(cd cpan; $$SHELL)
	make clean

cpantest: cpan
ifeq ($(wildcard pkg/no-test),)
	(cd cpan; prove -lv t) && make clean
else
	@echo "Testing not available. Use 'disttest' instead."
endif

dist: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	rm -fr cpan

distdir: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	tar xzf $(DIST)
	rm -fr cpan $(DIST)

distshell: distdir
	(cd $(DISTDIR); $$SHELL)
	make clean

disttest: cpan
	(cd cpan; dzil test) && make clean

upgrade:
	cp `$(ZILD) sharedir`/Makefile ./

readme:
	swim --pod-cpan doc/$(NAMEPATH).swim > ReadMe.pod

contrib:
	$(PERL_S) zild-render-template Contributing

travis:
	$(PERL_S) zild-render-template travis.yml .travis.yml

clean purge:
	rm -fr cpan .build $(DIST) $(DISTDIR)

#------------------------------------------------------------------------------
# Non-pulic-facing targets:
#------------------------------------------------------------------------------
check-release:
	RELEASE_BRANCH=$(RELEASE_BRANCH) zild-check-release

# We don't want to update the Makefile in Zilla::Dist since it is the real
# source, and would be reverting to whatever was installed.
ifeq (Zilla-Dist,$(NAME))
makefile:
	@echo Skip 'make upgrade'
else
makefile:
	@cp Makefile /tmp/
	make upgrade
	@if [ -n "`diff Makefile /tmp/Makefile`" ]; then \
	    echo "Makefile updated. Try again"; \
	    exit 1; \
	fi
	@rm /tmp/Makefile
endif

version:
	$(PERL_S) zild-version-update
