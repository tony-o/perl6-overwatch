#!/usr/bin/env perl6

use Shell::Command;

sub MAIN ($script, Str :$execute = 'perl6', Bool :$keep-alive = True, Bool :$exit-on-error = False, Bool :$quiet = False) {
  if $quiet {
    '[INFO] Starting overseer with options:'.say;
    "[INFO]    --execute: $execute".say;
    "[INFO]    --restart: $execute".say;
    "[INFO]       script: $script".say;
  }
  my ($promise, $proc);
  CONTROL {
    when (Error::Signal::INT) {
      'caught'.say;
      .perl.say;
    }
    default {
      'caugh'.say;
      .perl.say;
    }
  }

  while Any ~~ $proc || $keep-alive {
    $promise = start {
      $proc = run $execute, $script;
    };
    $proc.^methods.say;

    await $promise;
    $proc.perl.say;
    exit 0 if $proc.exit != 0 && $exit-on-error;
    ''.say;
    "[INFO] Restarting $execute $script".say if $quiet;
  }

}
