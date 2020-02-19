use strict;

use IPC::Open3;
use Irssi;
use Symbol;

Irssi::command_bind keyring => sub {
  my ($account, $server, $witem) = @_;

  open(LOGIN, "$ENV{HOME}/.irssi/login");
  while (<LOGIN>) {
    chomp;
    my $command = $_;
    my @parts = split(/\s/, $command);
    my $username;
    my $username_alt;
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
    }elsif ($parts[0] eq 'msg'){
      if ($parts[1] eq '&bitlbee' && $parts[2] eq 'identify'){
        $username = 'bitlbee';
      }
    }elsif ($parts[0] eq 'set'){
      $username = "$parts[1]";
    }else{
      next;
    }

    # handle alternate username
    if ($command =~ m/.*<password:([^>]*)>.*/){
      $username_alt = $1;
    }

    # just print available account names
    if ($account eq 'names') {
      if ($username){
        print $username;
      }elsif ($username_alt){
        print $username_alt;
      }
      next;
    }

    if ($account && $account ne $username && $account ne $username_alt){
      next;
    }

    if (!$username && !$username_alt){
      next;
    }

    my ($stdin, $stdout, $stderr);
    $stderr = gensym();
    if ($username_alt){
      $username = $username_alt;
    }
    my  $pid = open3($stdin, $stdout, $stderr, "keyring password $username");
    waitpid($pid, 0);

    my $status = $? >> 8;
    if ($status == 0){
      my $password = join('', <$stdout>);
      chomp($password);
      if ($parts[0] eq 'set'){
        print "keyring: setting $username";
        Irssi::settings_set_str($username, $password);
      }else{
        print "keyring: connecting $username";
        $command =~ s/<password(:[^>]*)?>/$password/;
        if ($parts[0] eq 'msg' && $username eq 'bitlbee'){
          my $localhost;
          foreach (Irssi::servers()) {
            if ($server->{real_address} eq 'localhost'){
              $localhost = $server;
              last;
            }
          }
          if (!$localhost){
            print 'Unable to connect to bitlbee: not connected to localhost'
          }else{
            Irssi::Server::command($localhost, $command);
          }

        }else{
          Irssi::command($command);
        }
      }
    }else{
      my $error = join('', <$stderr>);
      die "Error reading data from stderr: $!" if !eof($stderr);
      chomp($error);
      print "keyring: Error invoking keyring command: $error";
    }
  }
  close(LOGIN);
};
