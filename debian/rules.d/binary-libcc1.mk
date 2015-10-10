ifneq ($(DEB_CROSS),yes)
  arch_binaries  := $(arch_binaries) libcc1
endif

p_cc1	= libcc1-$(CC1_SONAME)
d_cc1	= debian/$(p_cc1)

# ----------------------------------------------------------------------
$(binary_stamp)-libcc1: $(install_dependencies)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_cc1)
	dh_installdirs -p$(p_cc1) \
		$(docdir) \
		$(usr_lib)
	$(dh_compat2) dh_movefiles -p$(p_cc1) \
		$(usr_lib)/libcc1.so.*

	debian/dh_doclink -p$(p_cc1) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_cc1)

	dh_strip -p$(p_cc1)
	dh_compress -p$(p_cc1)
	dh_makeshlibs -p$(p_cc1)
	dh_shlibdeps -p$(p_cc1)
	dh_fixperms -p$(p_cc1)
	dh_installdeb -p$(p_cc1)
	dh_gencontrol -p$(p_cc1) -- -v$(DEB_VERSION) $(common_substvars)
	dh_md5sums -p$(p_cc1)
	dh_builddeb -p$(p_cc1)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
