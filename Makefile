.PHONY: all clean test

all:
	# nothing to do

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' -exec basename {} ';' | parallel --jobs=1 $(MAKE) -C {} clean

test:
	find . -mindepth 1 -maxdepth 1 -type f -name '*.rkt' -exec basename {} ';' | parallel --jobs=1 raco test {}
	find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' -exec basename {} ';' | parallel $(MAKE) -C {} test
