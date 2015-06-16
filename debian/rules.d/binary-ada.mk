ifeq ($(with_separate_gnat),yes)
  $(lib_binaries) += gnatbase
endif
arch_binaries := $(arch_binaries) ada
ifneq ($(GFDL_INVARIANT_FREE),yes)
  indep_binaries := $(indep_binaries) ada-doc
endif

ifeq ($(with_libgnat),yes)
  $(lib_binaries) += libgnat
endif

ifneq ($(DEB_CROSS),yes)
  p_gbase	= gnat-$(GNAT_VERSION)-base
  p_glbase	= gnat-$(GNAT_VERSION)-base
  ifneq ($(with_separate_gnat),yes)
    p_gbase = gcc$(pkg_ver)-base
    p_glbase = $(p_lbase)
  endif
else
  p_gbase = gnat$(pkg_ver)$(cross_bin_arch)-base
  ifneq ($(with_separate_gnat),yes)
    p_gbase = gcc$(pkg_ver)$(cross_bin_arch)-base
  endif
  p_glbase = $(p_gbase)
endif

p_gnat	= gnat-$(GNAT_VERSION)$(cross_bin_arch)
p_gnsjlj= gnat-$(GNAT_VERSION)-sjlj$(cross_bin_arch)
p_lgnat	= libgnat-$(GNAT_VERSION)$(cross_lib_arch)
p_lgnat_dbg = libgnat-$(GNAT_VERSION)-dbg$(cross_lib_arch)
p_lgnatvsn = libgnatvsn$(GNAT_VERSION)$(cross_lib_arch)
p_lgnatvsn_dev = libgnatvsn$(GNAT_VERSION)-dev$(cross_lib_arch)
p_lgnatvsn_dbg = libgnatvsn$(GNAT_VERSION)-dbg$(cross_lib_arch)
p_lgnatprj = libgnatprj$(GNAT_VERSION)$(cross_lib_arch)
p_lgnatprj_dev = libgnatprj$(GNAT_VERSION)-dev$(cross_lib_arch)
p_lgnatprj_dbg = libgnatprj$(GNAT_VERSION)-dbg$(cross_lib_arch)
p_gnatd	= $(p_gnat)-doc

d_gbase	= debian/$(p_gbase)
d_gnat	= debian/$(p_gnat)
d_lgnat	= debian/$(p_lgnat)
d_lgnatvsn = debian/$(p_lgnatvsn)
d_lgnatprj = debian/$(p_lgnatprj)
d_gnatd	= debian/$(p_gnatd)

GNAT_TOOLS = gnat gnatbind gnatchop gnatclean gnatfind gnatkr gnatlink \
	     gnatls gnatmake gnatname gnatprep gnatxref gnathtml

ifeq ($(with_gnatsjlj),yes)
	rts_subdir = rts-native/
endif

dirs_gnat = \
	$(docdir)/$(p_gbase) \
	$(PF)/bin \
	$(PF)/share/man/man1 \
	$(gcc_lib_dir) \
	$(gcc_lexec_dir)

files_gnat = \
	$(gcc_lexec_dir)/gnat1 \
	$(gcc_lib_dir)/{adalib,adainclude} \
	$(foreach i,$(GNAT_TOOLS),$(PF)/bin/$(cmd_prefix)$(i)$(pkg_ver))

ifeq ($(with_gnatsjlj),yes)
files_gnat += \
	$(gcc_lib_dir)/$(rts_subdir)
endif
# rts-sjlj moved to a separate package

dirs_lgnat = \
	$(docdir) \
	$(PF)/lib
files_lgnat = \
	$(usr_lib)/lib{gnat,gnarl}-$(GNAT_SONAME).so.1

$(binary_stamp)-gnatbase: $(install_stamp)
	dh_testdir
	dh_testroot
	dh_installdocs -p$(p_gbase) debian/README.gnat debian/README.maintainers
	: # $(p_gbase)
ifeq ($(PKGSOURCE),gnat-$(BASE_VERSION))
	mkdir -p $(d_gbase)/$(docdir)/$(p_xbase)
	ln -sf ../$(p_gbase) $(d_gbase)/$(docdir)/$(p_xbase)/Ada
endif
	dh_installchangelogs -p$(p_gbase) src/gcc/ada/ChangeLog
	dh_compress -p$(p_gbase)
	dh_fixperms -p$(p_gbase)
	dh_gencontrol -p$(p_gbase) -- -v$(DEB_VERSION) $(common_substvars)
	dh_installdeb -p$(p_gbase)
	dh_md5sums -p$(p_gbase)
	dh_builddeb -p$(p_gbase)
	touch $@


$(binary_stamp)-libgnat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	: # libgnat
	rm -rf $(d_lgnat)
	dh_installdirs -p$(p_lgnat) $(dirs_lgnat)

	for lib in lib{gnat,gnarl}; do \
	  vlib=$$lib-$(GNAT_SONAME); \
	  mv $(d)/$(gcc_lib_dir)/$(rts_subdir)/adalib/$$vlib.so.1 $(d)/$(usr_lib)/. ; \
	  rm -f $(d)/$(gcc_lib_dir)/adalib/$$lib.so.1; \
	done
	dh_movefiles -p$(p_lgnat) $(files_lgnat)

	debian/dh_doclink -p$(p_lgnat) $(p_glbase)

	debian/dh_rmemptydirs -p$(p_lgnat)

	b=libgnat; \
	v=$(GNAT_VERSION); \
	for ext in preinst postinst prerm postrm; do \
	  for t in '' -dev -dbg; do \
	    if [ -f debian/$$b$$t.$$ext ]; then \
	      cp -pf debian/$$b$$t.$$ext debian/$$b$$v$$t.$$ext; \
	    fi; \
	  done; \
	done
	$(cross_makeshlibs) dh_makeshlibs -p$(p_lgnat) -V '$(p_lgnat) (>= $(DEB_VERSION))'
	$(call cross_mangle_shlibs,$(p_lgnat))

ifneq (,$(filter $(build_type), build-native cross-build-native))
	mkdir -p $(d_lgnat)/usr/share/lintian/overrides
	cp -p debian/$(p_lgnat).overrides \
		$(d_lgnat)/usr/share/lintian/overrides/$(p_lgnat)
endif

	dh_strip -p$(p_lgnat) --dbg-package=$(p_lgnat_dbg)
	dh_compress -p$(p_lgnat)
	dh_fixperms -p$(p_lgnat)
	$(cross_shlibdeps) dh_shlibdeps -p$(p_lgnat) \
		$(call shlibdirs_to_search,,)
	$(call cross_mangle_substvars,$(p_lgnat))
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnat) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnat))
	dh_installdeb -p$(p_lgnat)
	dh_md5sums -p$(p_lgnat)
	dh_builddeb -p$(p_lgnat)

	: # $(p_lgnat_dbg)
	debian/dh_doclink -p$(p_lgnat_dbg) $(p_glbase)
	dh_compress -p$(p_lgnat_dbg)
	dh_fixperms -p$(p_lgnat_dbg)
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnat_dbg) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnat_dbg))
	dh_installdeb -p$(p_lgnat_dbg)
	dh_md5sums -p$(p_lgnat_dbg)
	dh_builddeb -p$(p_lgnat_dbg)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)


$(binary_stamp)-libgnatvsn: $(binary_stamp)-libgnat
	: # $(p_lgnatvsn_dev)
	dh_movefiles -p$(p_lgnatvsn_dev) usr/lib/ada/adalib/gnatvsn
	dh_movefiles -p$(p_lgnatvsn_dev) usr/share/ada/adainclude/gnatvsn
	dh_install -p$(p_lgnatvsn_dev) \
	   debian/gnatvsn.gpr usr/share/ada/adainclude
	dh_movefiles -p$(p_lgnatvsn_dev) $(usr_lib)/libgnatvsn.a
	dh_link -p$(p_lgnatvsn_dev) \
	   $(usr_lib)/libgnatvsn.so.$(GNAT_VERSION) \
	   $(usr_lib)/libgnatvsn.so
	debian/dh_doclink -p$(p_lgnatvsn_dev) $(p_gbase)
	dh_strip -p$(p_lgnatvsn_dev) -X.a --keep-debug
	dh_fixperms -p$(p_lgnatvsn_dev)
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnatvsn_dev) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnatvsn_dev))
	dh_md5sums -p$(p_lgnatvsn_dev)
	dh_builddeb -p$(p_lgnatvsn_dev)

	: # $(p_lgnatvsn)
ifneq (,$(filter $(build_type), build-native cross-build-native))
	mkdir -p $(d_lgnatvsn)/usr/share/lintian/overrides
	cp -p debian/$(p_lgnatvsn).overrides \
		$(d_lgnatvsn)/usr/share/lintian/overrides/$(p_lgnatvsn)
endif
	dh_movefiles -p$(p_lgnatvsn) $(usr_lib)/libgnatvsn.so.$(GNAT_VERSION)
	debian/dh_doclink -p$(p_lgnatvsn) $(p_gbase)
	dh_strip -p$(p_lgnatvsn) --dbg-package=$(p_lgnatvsn_dbg)
	$(cross_makeshlibs) dh_makeshlibs -p$(p_lgnatvsn) \
		-V '$(p_lgnatvsn) (>= $(DEB_VERSION))'
	$(call cross_mangle_shlibs,$(p_lgnatvsn))
	cat debian/$(p_lgnatvsn)/DEBIAN/shlibs >> debian/shlibs.local
	dh_fixperms -p$(p_lgnatvsn)
	$(cross_shlibdeps) dh_shlibdeps -p$(p_lgnatvsn) \
		$(call shlibdirs_to_search,$(p_lgnat),)
	$(call cross_mangle_substvars,$(p_lgnatvsn))
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnatvsn) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnatvsn))
	dh_installdeb -p$(p_lgnatvsn)
	dh_md5sums -p$(p_lgnatvsn)
	dh_builddeb -p$(p_lgnatvsn)

	: # $(p_lgnatvsn_dbg)
	debian/dh_doclink -p$(p_lgnatvsn_dbg) $(p_gbase)
	dh_compress -p$(p_lgnatvsn_dbg)
	dh_fixperms -p$(p_lgnatvsn_dbg)
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnatvsn_dbg) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnatvsn_dbg))
	dh_installdeb -p$(p_lgnatvsn_dbg)
	dh_md5sums -p$(p_lgnatvsn_dbg)
	dh_builddeb -p$(p_lgnatvsn_dbg)
	touch $@

$(binary_stamp)-libgnatprj: $(binary_stamp)-libgnat $(binary_stamp)-libgnatvsn
	: # $(p_lgnatprj_dev)
	dh_movefiles -p$(p_lgnatprj_dev) usr/lib/ada/adalib/gnatprj
	dh_movefiles -p$(p_lgnatprj_dev) usr/share/ada/adainclude/gnatprj
	dh_install -p$(p_lgnatprj_dev) \
	   debian/gnatprj.gpr usr/share/ada/adainclude
	dh_movefiles -p$(p_lgnatprj_dev) $(usr_lib)/libgnatprj.a
	dh_link -p$(p_lgnatprj_dev) \
	   $(usr_lib)/libgnatprj.so.$(GNAT_VERSION) \
	   $(usr_lib)/libgnatprj.so
	dh_strip -p$(p_lgnatprj_dev) -X.a --keep-debug
	debian/dh_doclink -p$(p_lgnatprj_dev) $(p_gbase)
	dh_fixperms -p$(p_lgnatprj_dev)
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnatprj_dev) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnatprj_dev))
	dh_md5sums -p$(p_lgnatprj_dev)
	dh_builddeb -p$(p_lgnatprj_dev)

	: # $(p_lgnatprj)
ifneq (,$(filter $(build_type), build-native cross-build-native))
	mkdir -p $(d_lgnatprj)/usr/share/lintian/overrides
	cp -p debian/$(p_lgnatprj).overrides \
		$(d_lgnatprj)/usr/share/lintian/overrides/$(p_lgnatprj)
endif
	dh_movefiles -p$(p_lgnatprj) $(usr_lib)/libgnatprj.so.$(GNAT_VERSION)
	debian/dh_doclink -p$(p_lgnatprj) $(p_gbase)
	dh_strip -p$(p_lgnatprj) --dbg-package=$(p_lgnatprj_dbg)
	dh_fixperms -p$(p_lgnatprj)
	$(cross_makeshlibs) dh_makeshlibs -p$(p_lgnatprj) \
		-V '$(p_lgnatprj) (>= $(DEB_VERSION))'
	$(call cross_mangle_shlibs,$(p_lgnatprj))
	cat debian/$(p_lgnatprj)/DEBIAN/shlibs >> debian/shlibs.local
	$(cross_shlibdeps) dh_shlibdeps -p$(p_lgnatprj) \
		$(call shlibdirs_to_search,$(p_lgnat) $(p_lgnatvsn),)
	$(call cross_mangle_substvars,$(p_lgnatprj))
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnatprj) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnatprj))
	dh_installdeb -p$(p_lgnatprj)
	dh_md5sums -p$(p_lgnatprj)
	dh_builddeb -p$(p_lgnatprj)

	: # $(p_lgnatprj_dbg)
	debian/dh_doclink -p$(p_lgnatprj_dbg) $(p_gbase)
	dh_compress -p$(p_lgnatprj_dbg)
	dh_fixperms -p$(p_lgnatprj_dbg)
	$(cross_gencontrol) dh_gencontrol -p$(p_lgnatprj_dbg) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_lgnatprj_dbg))
	dh_installdeb -p$(p_lgnatprj_dbg)
	dh_md5sums -p$(p_lgnatprj_dbg)
	dh_builddeb -p$(p_lgnatprj_dbg)
	touch $@

ifeq ($(with_libgnat),yes)
$(binary_stamp)-ada: $(install_stamp) $(binary_stamp)-libgnat
$(binary_stamp)-ada: $(binary_stamp)-libgnatvsn
$(binary_stamp)-ada: $(binary_stamp)-libgnatprj
else
$(binary_stamp)-ada: $(install_stamp)
endif

ifeq ($(with_separate_gnat),yes)
$(binary_stamp)-ada: $(binary_stamp)-gnatbase
else
$(binary_stamp)-ada:
endif
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	: # $(p_gnat)
	rm -rf $(d_gnat)
	dh_installdirs -p$(p_gnat) $(dirs_gnat)
	# Upstream does not install gnathtml.
	cp src/gcc/ada/gnathtml.pl debian/tmp/$(PF)/bin/$(cmd_prefix)gnathtml$(pkg_ver)
	chmod 755 debian/tmp/$(PF)/bin/$(cmd_prefix)gnathtml$(pkg_ver)
	dh_movefiles -p$(p_gnat) $(files_gnat)

ifeq ($(with_gnatsjlj),yes)
	dh_installdirs -p$(p_gnsjlj) $(gcc_lib_dir)
	dh_movefiles -p$(p_gnsjlj) $(gcc_lib_dir)/rts-sjlj
	dh_link -p$(p_gnsjlj) \
	   $(gcc_lib_dir)/rts-sjlj usr/share/ada/adainclude/rts-sjlj
	dh_link -p$(p_gnsjlj) \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnat.a \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnat-$(GNAT_VERSION).a
	dh_link -p$(p_gnsjlj) \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnarl.a \
	   $(gcc_lib_dir)/rts-sjlj/adalib/libgnarl-$(GNAT_VERSION).a
endif

ifeq ($(with_libgnat),yes)
	for lib in lib{gnat,gnarl}; do \
	  vlib=$$lib-$(GNAT_SONAME); \
	  dh_link -p$(p_gnat) \
	    /$(usr_lib)/$$vlib.so.1 /$(usr_lib)/$$vlib.so \
	    /$(usr_lib)/$$vlib.so.1 /$(usr_lib)/$$lib.so; \
	done
	for lib in lib{gnat,gnarl}; do \
	  vlib=$$lib-$(GNAT_SONAME); \
	  dh_link -p$(p_gnat) \
	    /$(usr_lib)/$$vlib.so.1 $(gcc_lib_dir)/$(rts_subdir)adalib/$$lib.so; \
	done
endif
	debian/dh_doclink -p$(p_gnat)      $(p_gbase)
ifeq ($(with_gnatsjlj),yes)
	debian/dh_doclink -p$(p_gnsjlj) $(p_gbase)
endif
ifeq ($(PKGSOURCE),gnat-$(BASE_VERSION))
  ifeq ($(with_check),yes)
	cp -p test-summary $(d_gnat)/$(docdir)/$(p_gbase)/.
  endif
else
	mkdir -p $(d_gnat)/$(docdir)/$(p_gbase)/ada
	cp -p src/gcc/ada/ChangeLog $(d_gnat)/$(docdir)/$(p_gbase)/ada/.
endif

	for i in $(GNAT_TOOLS); do \
	  case "$$i" in \
	    gnat) cp -p debian/gnat.1 $(d_gnat)/$(PF)/share/man/man1/$(cmd_prefix)gnat$(pkg_ver).1 ;; \
	    *) ln -sf $(cmd_prefix)gnat$(pkg_ver).1 $(d_gnat)/$(PF)/share/man/man1/$(cmd_prefix)$$i$(pkg_ver).1; \
	  esac; \
	done

ifneq (,$(filter $(build_type), build-native cross-build-native))
	: # ship the versioned prefixed names in the gnat package.
	for i in $(GNAT_TOOLS); do \
	  ln -sf $$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$(DEB_TARGET_GNU_TYPE)-$$i$(pkg_ver); \
	  ln -sf $$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$(TARGET_ALIAS)-$$i$(pkg_ver); \
	  ln -sf gnat$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$(DEB_TARGET_GNU_TYPE)-$$i$(pkg_ver).1; \
	  ln -sf $$i$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$(TARGET_ALIAS)-$$i$(pkg_ver).1; \
	done

	: # still ship the unversioned names in the gnat package.
	for i in $(GNAT_TOOLS); do \
	  ln -sf $$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$$i; \
	  ln -sf $$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$$i; \
	  ln -sf gnat$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$$i.1; \
	  ln -sf $$i$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$$i.1; \
	done

	: # still ship the unversioned prefixed names in the gnat package.
	for i in $(GNAT_TOOLS); do \
	  ln -sf $$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$(DEB_TARGET_GNU_TYPE)-$$i; \
	  ln -sf $$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$(TARGET_ALIAS)-$$i; \
	  ln -sf gnat$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$(DEB_TARGET_GNU_TYPE)-$$i.1; \
	  ln -sf $$i$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$(TARGET_ALIAS)-$$i.1; \
	done
else
	: # still ship the unversioned names in the gnat package.
	for i in $(GNAT_TOOLS); do \
	  ln -sf $(DEB_TARGET_GNU_TYPE)-$$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$(DEB_TARGET_GNU_TYPE)-$$i; \
	  ln -sf $(DEB_TARGET_GNU_TYPE)-$$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$(TARGET_ALIAS)-$$i; \
	  ln -sf $(DEB_TARGET_GNU_TYPE)-gnat$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$(DEB_TARGET_GNU_TYPE)-$$i.1; \
	  ln -sf $(DEB_TARGET_GNU_TYPE)-$$i$(pkg_ver).1 \
	    $(d_gnat)/$(PF)/share/man/man1/$(TARGET_ALIAS)-$$i.1; \
	done
endif

ifneq (,$(filter $(build_type), build-native cross-build-native))
	dh_install -p$(p_gnat) debian/ada/debian_packaging.mk usr/share/ada
	mv $(d_gnat)/usr/share/ada/debian_packaging.mk \
	    $(d_gnat)/usr/share/ada/debian_packaging-$(GNAT_VERSION).mk
endif
	dh_link -p$(p_gnat) usr/bin/$(cmd_prefix)gcc$(pkg_ver) usr/bin/$(cmd_prefix)gnatgcc$(pkg_ver)
	dh_link -p$(p_gnat) usr/share/man/man1/$(cmd_prefix)gnat$(pkg_ver).1.gz usr/share/man/man1/$(cmd_prefix)gnatgcc$(pkg_ver).1.gz

	debian/dh_rmemptydirs -p$(p_gnat)

	dh_strip -p$(p_gnat)
	dh_compress -p$(p_gnat)
	dh_fixperms -p$(p_gnat)
	find $(d_gnat) -name '*.ali' | xargs chmod 444
	$(cross_makeshlibs) dh_shlibdeps -p$(p_gnat)
	dh_gencontrol -p$(p_gnat) -- -v$(DEB_VERSION) $(common_substvars)
	dh_installdeb -p$(p_gnat)
	dh_md5sums -p$(p_gnat)
	dh_builddeb -p$(p_gnat)

ifeq ($(with_gnatsjlj),yes)
	dh_strip -p$(p_gnsjlj)
	dh_compress -p$(p_gnsjlj)
	dh_fixperms -p$(p_gnsjlj)
	find $(d_gnat)-sjlj -name '*.ali' | xargs chmod 444
	$(cross_shlibdeps) dh_shlibdeps -p$(p_gnsjlj)
	$(cross_gencontrol) dh_gencontrol -p$(p_gnsjlj) \
		-- -v$(DEB_VERSION) $(common_substvars)
	$(call cross_mangle_control,$(p_gnsjlj))
	dh_installdeb -p$(p_gnsjlj)
	dh_md5sums -p$(p_gnsjlj)
	dh_builddeb -p$(p_gnsjlj)
endif

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)


ada_info_dir = $(d_gnatd)/$(PF)/share/info

$(binary_stamp)-ada-doc: $(build_html_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_gnatd)
	dh_installdirs -p$(p_gnatd) \
		$(PF)/share/info

	cd $(ada_info_dir) && \
	    makeinfo -I $(srcdir)/gcc/doc/include -I $(srcdir)/gcc/ada \
		-I $(builddir)/gcc \
		-o gnat_ugn-$(GNAT_VERSION).info \
		$(srcdir)/gcc/ada/gnat_ugn.texi
	cd $(ada_info_dir) && \
	    makeinfo -I $(srcdir)/gcc/doc/include -I $(srcdir)/gcc/ada \
		-I $(builddir)/gcc \
		-o gnat_rm-$(GNAT_VERSION).info \
		$(srcdir)/gcc/ada/gnat_rm.texi
	cd $(ada_info_dir) && \
	    makeinfo -I $(srcdir)/gcc/doc/include -I $(srcdir)/gcc/ada \
		-I $(builddir)/gcc \
		-o gnat-style-$(GNAT_VERSION).info \
		$(srcdir)/gcc/ada/gnat-style.texi

	dh_installdocs -p$(p_gnatd) \
	    html/gnat_ugn.html html/gnat_rm.html html/gnat-style.html
	dh_installchangelogs -p$(p_gnatd)
	dh_compress -p$(p_gnatd)
	dh_fixperms -p$(p_gnatd)
	dh_installdeb -p$(p_gnatd)
	dh_gencontrol -p$(p_gnatd) -- -v$(DEB_VERSION) $(common_substvars)
	dh_md5sums -p$(p_gnatd)
	dh_builddeb -p$(p_gnatd)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
