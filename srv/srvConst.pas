unit srvConst;
{$I NoRTTI.inc}

interface
uses
  {$IFDEF FMX}
  {$ELSE ~FMX}
  Graphics,
  {$ENDIF FMX}
  Types, SysUtils;

const
  VERSION = '2.5.0 Alpha3 by RD' {$IFDEF CPUX64 } +' x64' {$ENDIF} {$IFDEF FPC } +' FPC' {$ENDIF};
  VERSION_BUILD = '324';
  VERSION_STABLE = {$IFDEF STABLE } TRUE {$ELSE} FALSE {$ENDIF};
  HFS_HTTP_AGENT = 'HFS/'+VERSION;
  CURRENT_VFS_FORMAT: integer = 1;
  CRLF = #13#10;
  CRLFA = RawByteString(#13#10);
  TAB = #9;
  G_VAR_PREFIX = '#';
  HOURS = 24;
  MINUTES = HOURS*60;
  SECONDS = MINUTES*60; // Tdatetime * SECONDS = time in seconds
  KILO = 1024;
  MEGA = KILO*KILO;
  CORRUPTED_EXT = '.corrupted';
  COMMENT_FILE_EXT = '.comment';
  COMMENTS_FILE = 'hfs.comments.txt';
  DESCRIPT_ION = 'descript.ion';
  DIFF_TPL_FILE = 'hfs.diff.tpl';
  FILELIST_TPL_FILE = 'hfs.filelist.tpl';
  MACROS_LOG_FILE = 'macros-log.html';
  PROTECTED_FILES_MASK = 'hfs.*;*.htm*;descript.ion;*.comment;*.md5;*.corrupted;*.lnk';
  SESSION_COOKIE = 'HFS_SID_';
  VFS_FILE_IDENTIFIER = 'HFS.VFS';
  STARTING_SNDBUF = 32000;
  COMPRESSION_THRESHOLD = 10*KILO; // if more than X bytes, VFS files are compressed
  BYTES_GROUPING_THRESHOLD: TDateTime = 1/SECONDS; // group bytes in log
  DOWNLOAD_MIN_REFRESH_TIME: TDateTime = 1/(5*SECONDS); // 5 Hz
  sendGraphWidth = 512;
  sendGraphHeight = 32;

  IP_SERVICES_URL = 'http://hfsservice.rejetto.com/ipservices.php';
  SELF_TEST_URL = 'http://hfstest.rejetto.com/';

  ETA_FRAME = 5; // time frame for ETA (in seconds)

  USER_ANONYMOUS = '@anonymous';
  USER_ANYONE = '@anyone';
  USER_ANY_ACCOUNT = '@any account';

  DEFAULT_MIME = 'application/octet-stream';
  DEFAULT_MIME_TYPES: array [0..29] of string = (
    '*.htm;*.html', 'text/html',
    '*.jpg;*.jpeg;*.jpe', 'image/jpeg',
    '*.gif', 'image/gif',
    '*.png', 'image/png',
    '*.bmp', 'image/bmp',
    '*.ico', 'image/x-icon',
    '*.mpeg;*.mpg;*.mpe', 'video/mpeg',
    '*.avi', 'video/x-msvideo',
    '*.txt', 'text/plain',
    '*.css', 'text/css',
    '*.js',  'text/javascript',
    '*.mkv', 'video/x-matroska',
    '*.webp', 'image/webp',
    '*.heic', 'image/heic',
    '*.heif', 'image/heif'
  );
  thumbsShowToExtDefaultStr = '.jpg; .jpeg; .png; .gif; .webp; .bmp; .ico';

  DOW2STR: array [1..7] of string=( 'Sun','Mon','Tue','Wed','Thu','Fri','Sat' );
  MONTH2STR: array [1..12] of string = ( 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec' );

//const
//  libsBaseUrl = 'http://rejetto.com/hfs/';

type
  TcharSetA = TSysCharSet; //set of char;
  TcharSetW = set of Char deprecated 'Holds Char values in the ordinal range of 0..255 only.'; //set of char;
  PstringDynArray = ^TstringDynArray;
 {$IFDEF FPC}
  TUnicodeStringDynArray = array of UnicodeString;
  TProc = procedure();
  TProc<TParam> = procedure(param: TParam);
  TProcO<TParam> = procedure(param: TParam) of Object;
 {$ELSE FPC}
  TUnicodeStringDynArray = TStringDynArray;
  TUnicodeSearchRec = TSearchRec;
  TProcedureOfObject = procedure() of Object;
 {$ENDIF FPC}

  Paccount = ^Taccount;
	Taccount = record   // user/pass profile
    user, pwd, redir, notes: string;
    wasUser: string; // used in user renaming panel
    enabled, noLimits, group: boolean;
    link: TStringDynArray;
   end;
  Taccounts = array of Taccount;

  TdownloadingWhat = ( DW_UNK, DW_FILE, DW_FOLDERPAGE, DW_ICON, DW_ERROR, DW_ARCHIVE );

  TpreReply =  (PR_NONE, PR_BAN, PR_OVERLOAD);

type
  TaccountRecursionStopCase = (ARSC_REDIR, ARSC_NOLIMITS, ARSC_IN_SET);

const
  ILLEGAL_FILE_CHARS = [#0..#31,'/','\',':','?','*','"','<','>','|'];
  ENCODED_TABLE_HEADER = 'this is an encoded table'+CRLF;

const // Messages
  MSG_SPEED_KBS = '%.1f kB/s';

resourcestring
  MSG_MAX_CON = 'Max connections';
  MSG_MAX_CON_SING = 'Max connections from single address';
  MSG_MAX_SIM_ADDR = 'Max simultaneous addresses';
  MSG_MAX_SIM_ADDR_DL = 'Max simultaneous addresses downloading';
  MSG_MAX_SIM_DL_SING = 'Max simultaneous downloads from single address';
  MSG_MAX_SIM_DL = 'Max simultaneous downloads';

implementation

end.
