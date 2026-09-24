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
  SRV_VERSION = '2.5.0 by RD';
  VERSION = '2.5.0 Alpha5 by RD' {$IFDEF CPUX64 } +' x64' {$ENDIF} {$IFDEF FPC } +' FPC' {$ENDIF};
  VERSION_BUILD = '325';
  VERSION_STABLE = {$IFDEF STABLE } TRUE {$ELSE} FALSE {$ENDIF};
  HFS_HTTP_AGENT = 'HFS/'+SRV_VERSION;
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
  graphSamplesLenth = 3000;
 {$IFDEF FPC}
  maxComp = $7FFFFFFFFFFFFFFF;
 {$ENDIF FPC}

  IP_SERVICES_URL = 'http://hfsservice.rejetto.com/ipservices.php';
  SELF_TEST_URL = 'http://hfstest.rejetto.com/';

  ETA_FRAME = 5; // time frame for ETA (in seconds)

  YESNO: array [boolean] of string=('no','yes');

  USER_ANONYMOUS = '@anonymous';
  USER_ANYONE = '@anyone';
  USER_ANY_ACCOUNT = '@any account';

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
  PUnicodeChar = PChar;
 {$ENDIF FPC}
  TContentTypeType = RawByteString;

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

  TLoadPrefsVal = (lpION, lpHideProt, lpSysAttr, lpHdnAttr, lpSnglCmnt, lpFingerPrints, //lpRecurListing,
                   lpOEMForION, lpDeletePartialUploads, lpNumberFilesOnUpload, lpUseCommentAsRealm);

  TLoadPrefs = set of TLoadPrefsVal;

  TShowPrefsVal = (spUseSysIcons, spHttpsUrls, spFoldersBefore, spLinksBefore,
                       spNoPortInUrl, spEncodeNonascii, spEncodeSpaces, spCompressed,
                       spNoWaitSysIcons, spSendHFSIdentifier, spFreeLogin,
                       spStopSpiders, spPreventLeeching,
                       spEnableMacros, spNonLocalIPDisableMacros,
                       spPwdInPages, spEnableNoDefault, spDMbrowserTpl,
                       spRecursiveListing, spOemTar, spNoContentDisposition, spPreventStandby,
                       spCompressedZip);

  TShowPrefs = set of TShowPrefsVal;

  TLogPrefsVal = (logBanned, logIcons, logBrowsing, logProgress,
                      logServerstart, logServerstop,
                      logConnections, logDisconnections,
                      logUploads, logFullDownloads, LogDeletions,
                      logBytesReceived, logBytesSent, logOnlyServed,
                      logRequests, logReplies, logOtherEvents,
                      dumpRequests, dumpTraffic,
                      logMacros,
                      logDate, logTime, logOnVideo,
                      tabOnLogFile, useISOdate, logAPI);

  TLogPrefs = set of TLogPrefsVal;

  TSrvPrefsVal = (thumbedTypes);

type
  TPrefBoolDefine = record
    pCaption: String;
    pCode: String;
    pDefault: Boolean;
  end;

  TPrefStrDefine = record
    pCaption: String;
    pCode: String;
    pDefault: String;
  end;

const
  cLoadPrefs: array[TLoadPrefsVal] of TPrefBoolDefine = (
    (pCaption: 'Support DESCRIPT.ION'; pCode: 'support-descript.ion'; pDefault: True),                            // lpION
    (pCaption: 'List protected items only for allowed users'; pCode: 'list-protected-items'; pDefault: False),    // lpHideProt
    (pCaption: 'List files with <system> attribute'; pCode: 'list-system-files'; pDefault: False),                // lpSysAttr
    (pCaption: 'List files with <hidden> attribute'; pCode: 'list-hidden-files'; pDefault: False),                // lpHdnAttr
    (pCaption: 'Load single comment files'; pCode: 'load-single-comment-files'; pDefault: True),                  // lpSnglCmnt
    (pCaption: 'Enabled fingerprints'; pCode: 'enable-fingerprints'; pDefault: True),                             // lpFingerPrints
//    'recursive-listing',         // lpRecurListing
    (pCaption: 'Use OEM for DESCRIPT.ION'; pCode: 'oem-descript.ion'; pDefault: False),                           // lpOEMForION
    (pCaption: 'Delete partial uploads'; pCode: 'delete-partial-uploads'; pDefault: False),                       // lpDeletePartialUploads
    (pCaption: 'Number files on upload instead of overwriting'; pCode: 'number-files-on-upload'; pDefault: True), // lpNumberFilesOnUpload
    (pCaption: 'Use comment as realm'; pCode: 'use-comment-as-realm'; pDefault: True)                             // lpUseCommentAsRealm
  );

  cShowPrefs: array[TShowPrefsVal] of TPrefBoolDefine = (
     (pCaption: 'Use system icons'; pCode: 'use-system-icons'; pDefault: True),                                       // spUseSysIcons
     (pCaption: 'URLs starting with https instead of http'; pCode: 'https-url'; pDefault: False),                     // spHttpsUrls
     (pCaption: 'Folders before'; pCode: 'folders-before'; pDefault: True),                                           // spFoldersBefore
     (pCaption: 'Links before'; pCode: 'links-before'; pDefault: True),                                               // spLinksBefore
     (pCaption: 'Don''t include port in URL'; pCode: 'dont-include-port-in-url'; pDefault: False),                    // spNoPortInUrl
     (pCaption: 'Encode non-ASCII characters'; pCode: 'encode-non-ascii'; pDefault: False),                           // spEncodeNonascii
     (pCaption: 'Encode spaces'; pCode: 'encode-spaces'; pDefault: True),                                             // spEncodeSpaces
     (pCaption: 'Compressed browsing'; pCode: 'compressed-browsing'; pDefault: True),                                 // spCompressed
     (pCaption: ''; pCode: ''; pDefault: True),                                                                       // spNoWaitSysIcons
     (pCaption: 'Send HFS identifier'; pCode: 'send-hfs-identifier'; pDefault: True),                                 // spSendHFSIdentifier
     (pCaption: 'Accept any login for unprotected resources'; pCode: 'free-login'; pDefault: False),                  // spFreeLogin
     (pCaption: 'Stop spiders'; pCode: 'stop-spiders'; pDefault: True),                                               // spStopSpiders
     (pCaption: 'Prevent leeching (download accelerators)'; pCode: 'prevent-leeching'; pDefault: True),               // spPreventLeeching
     (pCaption: 'Enable macros'; pCode: 'enable-macros'; pDefault: True),                                             // spEnableMacros
     (pCaption: 'Disable macros for non-local IP'; pCode: 'macros-not4nonlocal'; pDefault: True),                     // spNonLocalIPDisableMacros
     (pCaption: 'Include password in pages (for download managers)'; pCode: 'include-pwd-in-pages'; pDefault: False), // spPwdInPages
     (pCaption: 'Enable ~nodefault'; pCode: 'enable-no-default'; pDefault: False),                                    // spEnableNoDefault
     (pCaption: 'Specific HTML for download managers'; pCode: 'getright-template'; pDefault: True),                   // spDMbrowserTpl
     (pCaption: 'Enable recursive listing'; pCode: 'recursive-listing'; pDefault: True),                              // spRecursiveListing
     (pCaption: 'OEM file names for TAR archives'; pCode: 'oem-tar'; pDefault: False),                                // spOemTar
     (pCaption: 'No Content-disposition'; pCode: ''; pDefault: False),                                                // spNoContentDisposition
     (pCaption: 'Prevent system standby on network activity'; pCode: 'prevent-standby'; pDefault: False),             // spPreventStandby
     (pCaption: 'Compress ZIP streams'; pCode: 'compressed-zip-stream'; pDefault: True)                               // spCompressedZip
  );

  cLogPrefs: array[TLogPrefsVal] of TPrefBoolDefine = (
     (pCaption: 'Only served requests'; pCode: 'log-banned'; pDefault: True),       // logBanned
     (pCaption: 'Icons'; pCode: 'log-icons'; pDefault: False),                      // logIcons
     (pCaption: 'Browsing'; pCode: 'log-browsing'; pDefault: True),                 // logBrowsing);
     (pCaption: 'Progress'; pCode: 'log-progress'; pDefault: False),                // logProgress);
     (pCaption: 'Server start'; pCode: 'log-server-start'; pDefault: False),        // logServerstart
     (pCaption: 'Server stop'; pCode: 'log-server-stop'; pDefault: False),          // logServerstop
     (pCaption: 'Connections'; pCode: 'log-connections'; pDefault: False),          // logconnections
     (pCaption: 'Disconnections'; pCode: 'log-disconnections'; pDefault: False),    // logDisconnections
     (pCaption: 'Uploads'; pCode: 'log-uploads'; pDefault: True),                   // logUploads
     (pCaption: 'Full downloads'; pCode: 'log-full-downloads'; pDefault: True),     // logFullDownloads
     (pCaption: 'Deletions'; pCode: 'log-deletions'; pDefault: True),               // LogDeletions);
     (pCaption: 'Other events'; pCode: 'log-others'; pDefault: True),               // logOtherEvents);
     (pCaption: 'Bytes received'; pCode: 'log-bytes-received'; pDefault: False),    // logBytesReceived);
     (pCaption: 'Bytes sent'; pCode: 'log-bytes-sent'; pDefault: False),            // logBytesSent);
     (pCaption: 'Only served requests'; pCode: 'log-only-served'; pDefault: True),  // logOnlyServed);
     (pCaption: 'Requests'; pCode: 'log-requests'; pDefault: False),                // logRequests);
     (pCaption: 'Replies'; pCode: 'log-replies'; pDefault: False),                  // logReplies);
     (pCaption: 'Requests dump'; pCode: 'log-dump-request'; pDefault: False),       // dumpRequests);
     (pCaption: 'Dump traffic'; pCode: 'log-dump-traffic'; pDefault: False),        // dumpTraffic);
     (pCaption: 'Enable macros.log'; pCode: 'log-macros'; pDefault: False),         // logMacros);
     (pCaption: 'Date'; pCode: 'log-date'; pDefault: False),                        // LogDate);
     (pCaption: 'Time'; pCode: 'log-time'; pDefault: True),                         // LogTime);
     (pCaption: 'Log to screen'; pCode: 'log-to-screen'; pDefault: True),            // logOnVideo
     (pCaption: 'Tabbed instead of multi-line for the log file'; pCode: 'log-file-tabbed'; pDefault: False), // tabOnLogFile
     (pCaption: 'Use ISO date format'; pCode: 'use-iso-date-format'; pDefault: False), //useISOdate
     (pCaption: 'API requests'; pCode: 'log-api'; pDefault: False) //logAPI
  );

const
  cSrvPrefs: array[TSrvPrefsVal] of TPrefStrDefine = (
    (pCaption: 'Select extensions to get thumbnails for'; pCode: 'thumbs-get-for'; pDefault: '.jpg; .jpeg; .png; .gif; .webp; .bmp; .ico')
    );

const
  ILLEGAL_FILE_CHARS = [#0..#31,'/','\',':','?','*','"','<','>','|'];
  ENCODED_TABLE_HEADER = 'this is an encoded table'+CRLF;
  pngMime = 'image/png';
  webpMime = 'image/webp';


  DEFAULT_MIME = TContentTypeType('application/octet-stream');
  DEFAULT_MIME_TYPES: array [0..31] of string = (
    '*.htm;*.html', 'text/html',
    '*.jpg;*.jpeg;*.jpe', 'image/jpeg',
    '*.gif', 'image/gif',
    '*.png', pngMime, //'image/png',
    '*.bmp', 'image/bmp',
    '*.ico', 'image/x-icon',
    '*.mpeg;*.mpg;*.mpe', 'video/mpeg',
    '*.avi', 'video/x-msvideo',
    '*.txt', 'text/plain',
    '*.css', 'text/css',
    '*.js',  'text/javascript',
    '*.mkv', 'video/x-matroska',
    '*.webp', webpMime, //'image/webp',
    '*.heic', 'image/heic',
    '*.heif', 'image/heif',
    '*.zip', 'application/zip'
  );
//  thumbsShowToExtDefaultStr = '.jpg; .jpeg; .png; .gif; .webp; .bmp; .ico';
  ZIP_MIME = TContentTypeType('application/zip');

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
