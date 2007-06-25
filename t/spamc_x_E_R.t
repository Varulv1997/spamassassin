#!/usr/bin/perl

use lib '.'; use lib 't';
use SATest; sa_t_init("spamc_x_E_R");

our $DO_RUN = !$SKIP_SPAMD_TESTS;

use Test; plan tests => ($DO_RUN ? 31 : 0);

exit unless $DO_RUN;

# ---------------------------------------------------------------------------
# test case for bug 5412; exit status with -x/-E/-R combos

%patterns = ( );

ok(start_spamd("-L"));

# ----------------------------------------------------------------------
# nonspam mails -- return 0
ok(scrun("-E < data/nice/001", \&patterns_run_cb));
ok(scrun("-R < data/nice/001", \&patterns_run_cb));
ok(scrun("-x -E < data/nice/001", \&patterns_run_cb));
ok(scrun("-x -R < data/nice/001", \&patterns_run_cb));
ok(scrun("-x -R -E < data/nice/001", \&patterns_run_cb));

# ----------------------------------------------------------------------
# spam mails
ok(scrun("-R < data/spam/001", \&patterns_run_cb));
ok(scrun("-x -R < data/spam/001", \&patterns_run_cb));

# returns 1; this will kill spamd as a side-effect
ok(scrunwantfail("-x -E < data/spam/001", \&patterns_run_cb));
stop_spamd(); $spamd_pid = undef; $spamd_already_killed = undef;
ok(start_spamd("-L"));

# returns 1; this will kill spamd
ok(scrunwantfail("-E < data/spam/001", \&patterns_run_cb));
stop_spamd(); $spamd_pid = undef; $spamd_already_killed = undef;
ok(start_spamd("-L"));

# returns 1; this will kill spamd
ok(scrunwantfail("-x -R -E < data/spam/001", \&patterns_run_cb));
stop_spamd(); # just to be sure

# ----------------------------------------------------------------------
# error conditions
$spamdhost = '255.255.255.255'; # cause "connection failed" errors

# these should have exit code == 0
ok(scrun("--connect-retries 1 -E < data/spam/001", \&patterns_run_cb));
ok(scrun("--connect-retries 1 -R < data/spam/001", \&patterns_run_cb));

# we do not want to see the output with -x on error
%patterns = ();
%anti_patterns = (
  q{ Subject: There yours for FREE!}, 'subj',
  q{ X-Spam-Flag: YES}, 'flag',
);

# this should have exit code != 0
clear_pattern_counters();
ok(scrunwantfail("--connect-retries 1 -x < data/spam/001", \&patterns_run_cb));
ok ok_all_patterns();

# this should have exit code != 0
clear_pattern_counters();
ok(scrunwantfail("--connect-retries 1 -x -R < data/spam/001", \&patterns_run_cb));
ok ok_all_patterns();

# this should have exit code != 0
clear_pattern_counters();
ok(scrunwantfail("--connect-retries 1 -x -E -R < data/spam/001", \&patterns_run_cb));
ok ok_all_patterns();

# this should have exit code != 0
clear_pattern_counters();
ok(scrunwantfail("--connect-retries 1 -x -E < data/spam/001", \&patterns_run_cb));
ok ok_all_patterns();

# ----------------------------------------------------------------------

