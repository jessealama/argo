.PHONY: clean test all

all: test

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 --halt-on-error now,fail=1 $(MAKE) --directory="{}" --jobs=1 --stop clean

test:
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 --halt-on-error now,fail=1 $(MAKE) --directory="{}" --jobs=1 --stop test
