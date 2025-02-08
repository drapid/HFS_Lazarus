unit hfsGlobal;
{$I NoRTTI.inc}

interface
uses
  System.UITypes,
 {$IFDEF FMX}
  FMX.Graphics,
 {$ELSE ~FMX}
  Graphics,
 {$ENDIF FMX}
  Types, SysUtils, srvConst;

const
{$I RnQBuiltTime.inc}
  CRLF = #13#10;
  CRLFA = RawByteString(#13#10);
  TAB = #9;
  BAK_EXT = '.bak';
  CFG_KEY = 'Software\rejetto\HFS';
  CFG_FILE = 'hfs.ini';
  TPL_FILE = 'hfs.tpl';
  IPS_FILE = 'hfs.ips.txt';
  VFS_TEMP_FILE = '~temp.vfs';
  EVENTSCRIPTS_FILE = 'hfs.events';
  PREVIOUS_VERSION = 'hfs.old.exe';
  IPS_THRESHOLD = 50;  // used to avoid an external file for few IPs (ipsEverConnected list)
  STATUSBAR_REFRESH = 10; // tenth of second
  MAX_RECENT_FILES = 5;
  MANY_ITEMS_THRESHOLD = 1000;
  YESNO: array [boolean] of string=('no','yes');
//  LIBS_DOWNLOAD_URL = 'http://rejetto.com/hfs/';
  LIBS_DOWNLOAD_URL = 'http://libs.rnq.ru/';
  HFS_GUIDE_URL = 'http://www.rejetto.com/hfs/guide/';

  ALWAYS_ON_WEB_SERVER = 'google.com';
  ADDRESS_COLOR = clGreen;
  BG_ERROR = $BBBBFF;
  TRAY_ICON_SIZE = 32;

  // messages
resourcestring
  S_PORT_LABEL = 'Port: %s';
  S_PORT_ANY = 'any';
  DISABLED = 'disabled';
  MSG_OK = 'Ok';
  // messages
  MSG_MENU_VAL = ' (%s)';
  MSG_DL_TIMEOUT = 'No downloads timeout';
  MSG_MAX_CON = 'Max connections';
  MSG_MAX_CON_SING = 'Max connections from single address';
  MSG_MAX_SIM_ADDR = 'Max simultaneous addresses';
  MSG_MAX_SIM_ADDR_DL = 'Max simultaneous addresses downloading';
  MSG_MAX_SIM_DL_SING = 'Max simultaneous downloads from single address';
  MSG_MAX_SIM_DL = 'Max simultaneous downloads';
  MSG_SET_LIMIT = 'Set limit';
  MSG_UNPROTECTED_LINKS = 'Links are NOT actually protected.'
    +#13'The feature is there to be used with the "list protected items only..." option.'
    +#13'Continue?';
  MSG_SAME_NAME ='An item with the same name is already present in this folder.'
    +#13'Continue?';
  MSG_CONTINUE = 'Continue?';
  MSG_PROCESSING = 'Processing...';
  MSG_OPTIONS_SAVED = 'Options saved';
  MSG_SOME_LOCKED = 'Some items were not affected because locked';
  MSG_ITEM_LOCKED = 'The item is locked';
  MSG_INVALID_VALUE = 'Invalid value';
  MSG_EMPTY_NO_LIMIT = 'Leave blank to get no limits.';
  MSG_ADDRESSES_EXCEED = 'The following addresses exceed the limit:'#13'%s';
  MSG_NO_TEMP = 'Cannot save temporary file';
  MSG_ERROR_REGISTRY = 'Can''t write to registry.'
    +#13'You may lack necessary rights.';
  MSG_MANY_ITEMS = 'You are putting many files.'
    +#13'Try using real folders instead of virtual folders.'
    +#13'Read documentation or ask on the forum for help.';
  MSG_ADD_TO_HFS = '"Add to HFS" has been added to your Window''s Explorer right-click menu.';
  MSG_SINGLE_INSTANCE = 'Sorry, this feature only works with the "Only 1 instance" option enabled.'
    +#13#13'You can find this option under Menu -> Start/Exit'
    +#13'(only in expert mode)';
  MSG_ENABLED =   'Option enabled';
  MSG_DISABLED = 'Option disabled';
  MSG_COMM_ERROR = 'Network error. Request failed.';
  MSG_CON_PAUSED = 'paused';
  MSG_CON_SENT = '%s / %s sent';
  MSG_CON_RECEIVED = '%s / %s received';

type

//  Pboolean = ^boolean;

  TfilterMethod = function(self: Tobject): Boolean;

  Thelp = ( HLP_NONE, HLP_TPL );

type
  TTrayShows = (TS_downloads, TS_connections, TS_uploads, TS_hits, TS_ips, TS_ips_ever, TS_none);

implementation

end.
