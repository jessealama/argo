.PHONY: all clean test

scrbls = $(wildcard *.scrbl)
scrbl-bases = $(basename $(scrbls))
htmls = $(addsuffix .html,$(scrbl-bases))

all: $(htmls)

%.html: %.scrbl
	find . -mindepth 1 -maxdepth 1 -type f -name '*.scrbl' -exec basename {} ';' | parallel --jobs=1 --halt-on-error=now,fail=1 scribble {}

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type f -name '*.html' -delete
	find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name 'compiled' -exec basename {} ';' | parallel --jobs=1 $(MAKE) --directory="{}" --stop --jobs=1 clean

test:
	# nothing to do (yet)
