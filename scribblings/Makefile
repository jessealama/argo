.PHONY: all clean test

scrbls = $(wildcard *.scrbl)
scrbl-bases = $(basename $(scrbls))
htmls = $(addsuffix .html,$(scrbl-bases))

all: argo.html

view: argo.html
	open $<

%.html: %.scrbl
	scribble $<

clean:
	rm -Rf compiled
	find . -mindepth 1 -maxdepth 1 -type f \( -name '*~' -o -name '*.html' -name '*.css' -o -name '*.js' \) -delete

	find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name 'compiled' -exec basename {} ';' | parallel --jobs=1 $(MAKE) --directory="{}" --stop --jobs=1 clean

test:
	# nothing to do (yet)
