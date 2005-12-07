
CACHED = $(shell ls | grep Makefile.cache)
ifeq ($(findstring Makefile.cache,$(CACHED)), Makefile.cache)
MKDEF = $(shell cat Makefile.cache)
else

CC = gcc -pipe
# CC = g++ --pipe

MAKE = make
# MAKE = gmake

OPT = -g
OPT += -O2
# OPT += -O3
# OPT += -mmmx
# OPT += -msse
# OPT += -msse2
# OPT += -msse3
# OPT += -rdynamic
OPT += -ffast-math
# OPT += -fbounds-checking
# OPT += -fomit-frame-pointer
OPT += -Wall -Wno-sign-compare
# OPT += -DCHRIF_OLDINFO
# OPT += -DPCRE_SUPPORT
# OPT += -DGCOLLECT
# OPT += -DMEMWATCH
# OPT += -DDMALLOC -DDMALLOC_FUNC_CHECK
# OPT += -DBCHECK

# LIBS += -lgc
# LIBS += -ldmalloc
# LIBS += -L/usr/local/lib -lpcre

PLATFORM = $(shell uname)

ifeq ($(findstring Linux,$(PLATFORM)), Linux)
   LIBS += -ldl
endif

ifeq ($(findstring SunOS,$(PLATFORM)), SunOS)
   LIBS += -lsocket -lnsl -ldl
   MAKE = gmake
endif

ifeq ($(findstring FreeBSD,$(PLATFORM)), FreeBSD)
   MAKE = gmake
endif

ifeq ($(findstring NetBSD,$(PLATFORM)), NetBSD)
   MAKE = gmake
   OS_TYPE = -D__NETBSD__
endif

ifeq ($(findstring CYGWIN,$(PLATFORM)), CYGWIN)
   OPT += -DFD_SETSIZE=4096
   ifeq ($(findstring mingw,$(shell gcc --version)), mingw)
      IS_MINGW = 1
      OS_TYPE = -DMINGW
      LIBS += -L../.. -lwsock32
   else
      OS_TYPE = -DCYGWIN
   endif
endif

CFLAGS = $(OPT) -I../common $(OS_TYPE)

ifdef SQLFLAG
  ifdef IS_MINGW
    CFLAGS += -I../mysql
    LIBS += -lmysql
  else
    MYSQLFLAG_CONFIG = $(shell which mysql_config)
    ifeq ($(findstring /,$(MYSQLFLAG_CONFIG)), /)
      MYSQLFLAG_VERSION = $(shell $(MYSQLFLAG_CONFIG) --version | sed s:\\..*::)
      ifeq ($(findstring 5,$(MYSQLFLAG_VERSION)), 5)
        MYSQLFLAG_CONFIG_ARGUMENT = --include
      else
        MYSQLFLAG_CONFIG_ARGUMENT = --cflags
      endif
      CFLAGS += $(shell $(MYSQLFLAG_CONFIG) $(MYSQLFLAG_CONFIG_ARGUMENT))
      LIBS += $(shell $(MYSQLFLAG_CONFIG) --libs)
    else
      CFLAGS += -I/usr/local/include/mysql
      LIBS += -L/usr/local/lib/mysql -lmysqlclient
    endif
  endif
endif

ifneq ($(findstring -lz,$(LIBS)), -lz)
   LIBS += -lz
endif
ifneq ($(findstring -lm,$(LIBS)), -lm)
   LIBS += -lm
endif

MKDEF = CC="$(CC)" CFLAGS="$(CFLAGS)" LIB_S="$(LIBS)"

endif

.PHONY: txt sql common login login_sql char char_sql map map_sql ladmin converters \
	addons plugins tools webserver clean zlib depend

all: txt

txt : Makefile.cache conf common login char map ladmin

ifdef SQLFLAG
sql: Makefile.cache conf common login_sql char_sql map_sql
else
sql:
	$(MAKE) SQLFLAG=1 $@
endif

conf:
	cp -r conf-tmpl conf
	rm -rf conf/.svn conf/*/.svn
	cp -r save-tmpl save
	rm -rf save/.svn

common: src/common/GNUmakefile
	$(MAKE) -C src/$@ $(MKDEF)

login: src/login/GNUmakefile common
	$(MAKE) -C src/$@ $(MKDEF) txt

char: src/char/GNUmakefile common
	$(MAKE) -C src/$@ $(MKDEF) txt

map: src/map/GNUmakefile common
	$(MAKE) -C src/$@ $(MKDEF) txt

login_sql: src/login_sql/GNUmakefile common
	$(MAKE) -C src/$@ $(MKDEF) sql

char_sql: src/char_sql/GNUmakefile common
	$(MAKE) -C src/$@ $(MKDEF) sql

map_sql: src/map/GNUmakefile common
	$(MAKE) -C src/map $(MKDEF) sql

ladmin: src/ladmin/GNUmakefile common
	$(MAKE) -C src/$@ $(MKDEF)

plugins addons: src/plugins/GNUmakefile common
	$(MAKE) -C src/plugins $(MKDEF)

webserver:
	$(MAKE) -C src/$@ $(MKDEF)

tools:
	$(MAKE) -C src/tool $(MKDEF)

converters: src/txt-converter/GNUmakefile common
	$(MAKE) -C src/txt-converter $(MKDEF)

zlib:
	$(MAKE) -C src/$@ $(MKDEF)

clean: src/common/GNUmakefile src/login/GNUmakefile src/login_sql/GNUmakefile \
	src/char/GNUmakefile src/char_sql/GNUmakefile src/map/GNUmakefile \
	src/ladmin/GNUmakefile src/plugins/GNUmakefile src/txt-converter/GNUmakefile
	rm -f Makefile.cache
	$(MAKE) -C src/common $@
	$(MAKE) -C src/login $@
	$(MAKE) -C src/login_sql $@
	$(MAKE) -C src/char $@
	$(MAKE) -C src/char_sql $@
	$(MAKE) -C src/map $@
	$(MAKE) -C src/ladmin $@
	$(MAKE) -C src/plugins $@
	$(MAKE) -C src/zlib $@
	$(MAKE) -C src/txt-converter $@

depend: src/common/GNUmakefile src/login/GNUmakefile src/login_sql/GNUmakefile \
	src/char/GNUmakefile src/char_sql/GNUmakefile src/map/GNUmakefile \
	src/ladmin/GNUmakefile src/plugins/GNUmakefile src/txt-converter/GNUmakefile
	cd src/common; makedepend -fGNUmakefile -pobj/ -Y. *.c; cd ../..;
	cd src/login; makedepend -DTXT_ONLY -fGNUmakefile -Y. -Y../common *.c; cd ../..;
	cd src/login_sql; makedepend -fGNUmakefile -Y. -Y../common *.c; cd ../..;
	cd src/char; makedepend -DTXT_ONLY -fGNUmakefile -Y. -Y../common *.c; cd ../..;
	cd src/char_sql; makedepend -fGNUmakefile -Y. -Y../common *.c; cd ../..;
	cd src/map; makedepend -DTXT_ONLY -fGNUmakefile -ptxtobj/ -Y. -Y../common *.c; cd ../..;
	cd src/map; makedepend -fGNUmakefile -a -psqlobj/ -Y. -Y../common *.c; cd ../..;
	cd src/ladmin; makedepend -fGNUmakefile -Y. -Y../common *.c; cd ../..;
	cd src/txt-converter; makedepend -fGNUmakefile -Y. -Y../common *.c; cd ../..;
	$(MAKE) -C src/plugins $@

Makefile.cache:
	printf "$(subst ",\",$(MKDEF))" > Makefile.cache

src/%/GNUmakefile: src/%/Makefile
	sed -e 's/$$>/$$^/' $< > $@

src/common/GNUmakefile: src/common/Makefile
src/login/GNUmakefile: src/login/Makefile
src/login_sql/GNUmakefile: src/login_sql/Makefile
src/char/GNUmakefile: src/char/Makefile
src/char_sql/GNUmakefile: src/char_sql/Makefile
src/map/GNUmakefile: src/map/Makefile
src/plugins/GNUmakefile: src/plugins/Makefile
src/ladmin/GNUmakefile: src/ladmin/Makefile
src/txt-converter/GNUmakefile: src/txt-converter/Makefile
