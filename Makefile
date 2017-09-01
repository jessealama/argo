.PHONY: all clean test

all:
	find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name 'compiled' ! -name 'doc' -exec basename {} ';' | parallel --jobs=1 --halt-on-error now,fail=1 $(MAKE) --directory="{}" --jobs=1 --stop all

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name 'compiled' ! -name 'doc' -exec basename {} ';' | parallel --jobs=1 --halt-on-error now,fail=1 $(MAKE) --directory="{}" --jobs=1 --stop clean

test:
	find . -mindepth 1 -maxdepth 1 -type f -name '*.rkt' -exec basename {} ';' | parallel --jobs=1 raco test {}
	find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name 'compiled' ! -name 'doc' -exec basename {} ';' | parallel --jobs=1 --halt-on-error now,fail=1 $(MAKE) --directory="{}" --jobs=1 --stop test

# -*- mode: makefile-gmake-mode; -*-
