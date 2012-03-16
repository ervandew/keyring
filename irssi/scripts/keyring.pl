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
      if (scalar(@parts) >= 5){
        $username = $parts[3];
      }
    }else{
      next;
    }

    # handle alternate username
    if($command =~ m/.*<password:([^>]*)>.*/){
      $username = $1;
    }

    if(!$username || ($account && $account ne $username)){
      next;
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
