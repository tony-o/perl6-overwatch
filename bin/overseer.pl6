#!/usr/bin/env perl6

use Shell::Command;

sub MAIN ($script, Str :$execute = 'perl6', Bool :$keep-alive = True, Bool :$exit-on-error = False, Bool :$quiet = False) {
  if !$quiet {
    '[INFO] Starting overseer with options:'.say;
    "[INFO]    --execute: $execute".say;
    "[INFO]    --restart: $execute".say;
    "[INFO]       script: $script".say;
  }
  my ($prom, $proc);
  signal(SIGTERM,SIGINT,SIGHUP,SIGQUIT).tap({
    ''.say;
    "[INFO] Killing process with $_".say if !$quiet;
    await $proc.kill($_);
    exit 0;
  });

  while Any ~~ $proc || $keep-alive {
    $proc = Proc::Async.new($execute, $script);
    await ($prom = $proc.start);
    if $prom.result.exit != 0 && $exit-on-error {
      "[INFO] Exit code ({$prom.result.exit}) from process caught, exiting".say if !$quiet;
      exit 0;
    }
    "[INFO] Restarting $execute $script".say if !$quiet;
  }

}
