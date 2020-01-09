#!/usr/bin/make -f
include Makefile.mk

LV2NAME=bitcrusher
BUNDLE=bitcrusher.lv2
PREFIX ?= /usr/local
DESTDIR ?=

all: build
build: $(LV2NAME)

$(LV2NAME): $(BUNDLE)/$(LV2NAME)$(LIB_EXT) $(BUNDLE)/manifest.ttl

$(BUNDLE)/$(LV2NAME)$(LIB_EXT): bitcrusher.c
	$(CC) $^ $(BUILD_C_FLAGS) $(LINK_FLAGS) -lm $(SHARED) -o $@

$(BUNDLE)/manifest.ttl: $(BUNDLE)/manifest.ttl.in
	sed -e "s|@LV2NAME@|$(LV2NAME)|g" $< > $@
	sed -e "s|@LIB_EXT@|$(LIB_EXT)|g" -i $@

clean:
	rm -f $(BUNDLE)/$(LV2NAME)$(LIB_EXT) $(BUNDLE)/manifest.ttl

install: build
	install -d $(DESTDIR)$(PREFIX)/lib/lv2/$(BUNDLE)

	install -m 644 $(BUNDLE)/*.so  $(DESTDIR)$(PREFIX)/lib/lv2/$(BUNDLE)/
	install -m 644 $(BUNDLE)/*.ttl $(DESTDIR)$(PREFIX)/lib/lv2/$(BUNDLE)/

.PHONY: all $(LV2NAME) clean install
