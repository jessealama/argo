.PHONY: clean test

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 $(MAKE) --stop --jobs=1 --directory="{}" clean

test:
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 --halt-on-error now,fail=1 $(MAKE) --stop --jobs=1 --directory="{}" test
