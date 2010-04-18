package MjNCMS::Content;
#
# (c) Fedor F Lejepekov, ffl.public@gmail.com, 2010
#

#
# Bender: Suck my luck!
#
# Leela: Remember, professor. Bender is Santa. You don't need to hurt him. 
#
# (c) Futurama
#

use common::sense;
use base 'Mojolicious::Controller';

use FindBin;
use lib "$FindBin::Bin/../";

use MjNCMS::Config qw/:vars /;
use MjNCMS::Service qw/:subs /;

use MjNCMS::NS;

use MjNCMS::Menus;
use MjNCMS::Usercontroller;
use MjNCMS::FileManager;

use Digest::SHA1 qw/sha1_hex /;#urls chk_sum

########################################################################
#                       ROUTE CONTENT-SIDE CALLS
########################################################################

sub content_rt_filemanager_connector_get () {
    my $self = shift;
    my $fm_responce; 
    
    unless ($SESSION{'USR'}->chk_access('filemanager', 'manage', 'w')) {
        $TT_CFG{'tt_controller'} = 
            $TT_VARS{'tt_controller'} = 
                'admin';
        $TT_CFG{'tt_action'} = 
            $TT_VARS{'tt_action'} = 
                'no_access_perm';
        $self->render('admin/admin_index');
        return;
    }

    $fm_responce = &MjNCMS::Content::fm_getresponce(
        scalar $SESSION{'REQ'}->param('action'), 
        scalar $SESSION{'REQ'}->param('filemanager_id'),
    );
    
    $fm_responce = {
        status => 'fail',
        message => 'unknown error on server side',
    } unless defined $fm_responce;
    
    if (ref $fm_responce && ref $fm_responce eq 'HASH') {
        $$fm_responce{'filemanager_id'} = $SESSION{'REQ'}->param('filemanager_id');
        $self->render_json($fm_responce);
    }
    else{
        $self->render_text($fm_responce);
    }
    
    return;
    
} #-- content_filemanager_connector_get

########################################################################
#                           INTERNAL SUBS
########################################################################

sub fm_getresponce (;$$) {

    my $action = $_[0];
    $action = $SESSION{'REQ'}->param('action')
        unless $action;

    my $filemanager_id = $_[1];
    $filemanager_id = $SESSION{'REQ'}->param('filemanager_id')
        unless $filemanager_id;
    
    return undef unless $action;
    return undef unless $filemanager_id;
    
    return {
        status => 'fail', 
        message => 'userfiles path or directory not set. or both :)', 
    } unless (
        $SESSION{'USERFILES_URL'} &&
        $SESSION{'USERFILES_PATH'}
    );
    
    my $fm = MjNCMS::FileManager->new();
    
    return {
        status => 'fail', 
        message => 'userfiles paths set fail', 
    } unless $fm->set_paths({
            #login is better, but there are can be bad letters, or non-latin chars
            root_url => $SESSION{'USERFILES_URL'} . '/' . $SESSION{'USR'}->{'member_id'}, 
            root_path => $SESSION{'USERFILES_PATH'} . '/' . $SESSION{'USR'}->{'member_id'}, 
        });
    
    return {
        status => 'fail', 
        message => 'filemanager_id set fail', 
    } unless $fm->set_filemanager_id($filemanager_id);
    
    return $fm->run_action($action);
    
}

1;
