# nuspell throws from search_dirs_for_one_dict if any directory in its search
# path is inaccessible, and since Enchant doesn't catch that, it aborts Emacs
final: prev: {
  nuspell = prev.nuspell.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./nuspell-search-dirs-no-throw.patch ];

    # checked by the emacs module, which warns if this patch is missing
    passthru = (old.passthru or { }) // { tesujimathSearchDirsNoThrow = true; };
  });
}
