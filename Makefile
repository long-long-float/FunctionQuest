.SUFFIXES:
.SUFFIXES: .md .html

tmp := $(shell mktemp)

.md.html :
	marked $< -o $(tmp)
	cat docs/intro.html $(tmp) docs/outro.html > $@

mdfiles := $(wildcard docs/*.md)
htmlfiles = $(mdfiles:.md=.html)

.PHONY: all
all: $(htmlfiles)
