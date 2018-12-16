all: architecture.png

architecture.png: architecture.uxf
	java -jar ~/Applications/Umlet/umlet.jar \
		-action=convert \
		-format=png \
		-filename=$< \
		-output=$@.tmp
	pngquant --ext .png --force $@.tmp.png
	mv $@.tmp.png $@

.PHONY: all
