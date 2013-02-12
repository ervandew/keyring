use strict;

use IPC::Open3;
use Irssi;
use Symbol;

Irssi::command_bind keyring => sub {
  my ($account) = @_;

  open(LOGIN, "$ENV{HOME}/.irssi/login");
  while (<LOGIN>) {
    chomp;
    my $command = $_;
    my @parts = split(/\s/, $command);
    my $username;
    if ($parts[0] eq 'connect'){
      if (scalar(@parts) >= 5){
        $username = "$parts[4]\@$parts[1]";
      }
    }elsif ($parts[0] eq 'xmppconnect'){
      foreach (@parts) {
        if ($_ =~ '@'){
          $username = $_;
          last;
        }
      }
    }else{
      next;
    }

    # just print available account names
    if($account eq 'names') {
      print $username;
      next;
    }

    if(!$username || ($account && $account ne $username)){
      next;
    }

    # handle alternate username
    if($command =~ m/.*<password:([^>]*)>.*/){
      $username = $1;
    }

    my ($stdin, $stdout, $stderr);
    $stderr = gensym();
    my  $pid = open3($stdin, $stdout, $stderr, "keyring password $username");
    waitpid($pid, 0);

    my $status = $? >> 8;
    if ($status == 0){
      my $password = join('', <$stdout>);
      chomp($password);
      $command =~ s/<password(:[^>]*)?>/$password/;
      print "keyring: connecting $username";
      Irssi::command($command);
    }else{
      my $error = join('', <$stderr>);
      die "Error reading data from stderr: $!" if !eof($stderr);
      chomp($error);
      print "keyring: Error invoking keyring command: $error";
    }
  }
  close(LOGIN);
};
