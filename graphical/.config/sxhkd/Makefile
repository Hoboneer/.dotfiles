.PHONY: all
all: sxhkdrc.exec
.PHONY: clean
clean:
	rm -f -- sxhkdrc.exec
.PHONY: lint
lint:
	hkfind -c ./sxhkdrc | hkxargs -c ./sxhkdrc -m linter shellcheck -s sh -f gcc --color=always | uniq
sxhkdrc.exec: sxhkdrc
	hkfind $$(cat "$${XDG_CONFIG_HOME:-$$HOME/.config}/sxhkd/PARSER-ARGS") \! -in /MACROS | hkxargs -C '{}' sed "s/^/sxhkdmacro tick '@'; /" '{}' >$@.tmp
	hkfind $$(cat "$${XDG_CONFIG_HOME:-$$HOME/.config}/sxhkd/PARSER-ARGS") -in /MACROS | hkxargs >>$@.tmp
	mv $@.tmp $@
