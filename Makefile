#!/usr/bin/make -f
OPTIMIZATIONS ?= -msse -msse2 -mfpmath=sse -ffast-math -fomit-frame-pointer -O3 -fno-finite-math-only -DNDEBUG
PREFIX ?= /usr/local
CFLAGS ?= $(OPTIMIZATIONS) -Wall

PKG_CONFIG?=pkg-config
STRIP?=strip
STRIPFLAGS?=-s

LV2DIR ?= $(PREFIX)/lib64/lv2
LOADLIBS=-lm
LV2NAME=bitcrusher
BUNDLE=bitcrusher.lv2
BUILDDIR=build/
targets=

UNAME=$(shell uname)
ifeq ($(UNAME),Darwin)
  LV2LDFLAGS=-dynamiclib
  LIB_EXT=.dylib
  EXTENDED_RE=-E
  STRIPFLAGS=-u -r -arch all -s lv2syms
  targets+=lv2syms
else
  LV2LDFLAGS=-Wl,-Bstatic -Wl,-Bdynamic
  LIB_EXT=.so
  EXTENDED_RE=-r
endif

targets+=$(BUILDDIR)$(LV2NAME)$(LIB_EXT)

# check for build-dependencies
ifeq ($(shell pkg-config --exists lv2 || echo no), no)
  $(error "LV2 SDK was not found")
endif

override CFLAGS += -fPIC -std=c99
override CFLAGS += `pkg-config --cflags lv2`

# build target definitions
default: all

all: $(BUILDDIR)manifest.ttl $(BUILDDIR)$(LV2NAME).ttl $(targets)

lv2syms:
	echo "_lv2_descriptor" > lv2syms

$(BUILDDIR)manifest.ttl: manifest.ttl.in
	@mkdir -p $(BUILDDIR)
	sed "s/@LV2NAME@/$(LV2NAME)/g;s/@LIB_EXT@/$(LIB_EXT)/g" \
		manifest.ttl.in > $(BUILDDIR)manifest.ttl

$(BUILDDIR)$(LV2NAME).ttl: $(LV2NAME).ttl.in
	@mkdir -p $(BUILDDIR)
	cp $(LV2NAME).ttl.in $(BUILDDIR)$(LV2NAME).ttl

$(BUILDDIR)$(LV2NAME)$(LIB_EXT): $(LV2NAME).c
	@mkdir -p $(BUILDDIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) \
	  -o $(BUILDDIR)$(LV2NAME)$(LIB_EXT) $(LV2NAME).c \
	  -shared $(LV2LDFLAGS) $(LDFLAGS) $(LOADLIBS)
	$(STRIP) $(STRIPFLAGS) $(BUILDDIR)$(LV2NAME)$(LIB_EXT)

install: all
	install -d $(DESTDIR)$(LV2DIR)/$(BUNDLE)
	install -m755 $(BUILDDIR)$(LV2NAME)$(LIB_EXT) $(DESTDIR)$(LV2DIR)/$(BUNDLE)
	install -m644 $(BUILDDIR)manifest.ttl $(BUILDDIR)$(LV2NAME).ttl $(DESTDIR)$(LV2DIR)/$(BUNDLE)
	cp -r modgui $(DESTDIR)$(LV2DIR)/$(BUNDLE)
	install -m644 modgui.ttl $(DESTDIR)$(LV2DIR)/$(BUNDLE)

modsdk:
	docker pull moddevices/modsdk
	make
	make PREFIX=`pwd`/tgt install
	docker run -p 9000:9000 -v `pwd`/tgt/lib64/lv2:/lv2 moddevices/modsdk

validate:
	sord_validate $(find /usr/lib64/lv2 -name '*.ttl') $(find build -name '*.ttl')

clean:
	rm -f $(BUILDDIR)manifest.ttl $(BUILDDIR)$(LV2NAME).ttl $(BUILDDIR)$(LV2NAME)$(LIB_EXT) lv2syms
	-test -d $(BUILDDIR) && rmdir $(BUILDDIR) || true

.PHONY: clean all install validate modsdk
