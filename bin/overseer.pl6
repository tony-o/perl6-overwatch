#!/usr/bin/env perl6

use Shell::Command;

sub MAIN (
  $script, 
  Str :$execute = 'perl6', 
  Bool :$keep-alive = True, 
  Bool :$exit-on-error = False, 
  Bool :$quiet = False,
  :@watchdir = ['.'],
) {
  my ($prom, $proc, $killer);

  if !$quiet {
    '[INFO] Starting overseer with options:'.say;
    "[INFO]    --execute: $execute".say;
    "[INFO]    --restart: $execute".say;
    "[INFO]  --watchdirs: ".say;
    for @watchdir -> $dir {
      say ' ' x 4 ~ $dir;
    }
    "[INFO]       script: $script".say;
  }

  for @watchdir -> $dir {
    $dir.IO.watch.tap: -> $f {
      $proc.kill(SIGQUIT);
      $killer.keep(True);
      "[INFO] Restart process, file changed: {"$dir/{$f.path}".IO.path}".say;
    }
  }

  signal(SIGTERM,SIGINT,SIGHUP,SIGQUIT).tap({
    ''.say;
    "[INFO] Killing process with $_".say if !$quiet;
    await $proc.kill($_);
    exit 0;
  });

  while Any ~~ $proc || $keep-alive {
    $proc = Proc::Async.new($execute, $script);
    $proc.stdout.act(&say);
    $proc.stderr.act(&warn);
    $prom = $proc.start;
    $killer = Promise.new;
    await Promise.anyof($prom, $killer);
    $killer.break if $killer.status !~~ Kept;
    if $killer.status !~~ Kept && $prom.result.exit != 0 && $exit-on-error {
      "[INFO] Exit code ({$prom.result.exit}) from process caught, exiting".say if !$quiet;
      exit 0;
    }
    "[INFO] Restarting $execute $script".say if !$quiet;
  }

}
