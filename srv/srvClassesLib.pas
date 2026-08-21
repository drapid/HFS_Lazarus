{
Copyright (C) 2002-2020  Massimo Melina (www.rejetto.com)

This file is part of HFS ~ HTTP File Server.

    HFS is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    HFS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with HFS; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
{$INCLUDE defs.inc }
unit srvClassesLib;
{$I NoRTTI.inc}

interface

uses
  windows,
  Forms,
  Graphics,
  Contnrs,
  iniFiles, types, strUtils, sysUtils, classes,
  ComCtrls,
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  Generics.Collections,
  {$ELSE USE_MORMOT_COLLECTIONS}
  mormot.core.collections,
  mormot.core.json,
  {$ENDIF USE_MORMOT_COLLECTIONS}
  hslib, srvConst;

type
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  Tip2av = Tdictionary<string, Tdatetime>;
  {$ELSE USE_MORMOT_COLLECTIONS}
  Tip2av = IKeyValue<string, TDateTime>;
  {$ENDIF USE_MORMOT_COLLECTIONS}

  TantiDos = class
    const MAX_CONCURRENTS = 3;
  class var
    folderConcurrents: integer;
    ip2availability2: Tip2av;
    class constructor Create;
  protected
    accepted: boolean;
    Paddress: String;
  public
    constructor Create;
    destructor Destroy; override;
    function accept(conn: ThttpConn; address: String=''): Boolean;
  {$IFDEF USE_MORMOT_COLLECTIONS}
    function RemoveOld(const aKey; var aValue;
        aIndex, aCount: integer; aOpaque: pointer): boolean;
  {$ENDIF USE_MORMOT_COLLECTIONS}
   end;

  PcachedIcon = ^TcachedIcon;
  TcachedIcon = record
    data: string;
    idx: integer;
    time: Tdatetime;
    end;

  TiconsCache = class
    n: integer;
    icons: array of TcachedIcon;
    function get(const data: String): PcachedIcon;
    procedure put(const data: String; idx: Integer; time: Tdatetime);
    procedure clear();
    procedure purge(olderThan: Tdatetime);
    function idxOf(const data: String): Integer;
    end;

  TusersInVFS = class
  protected
    users: TstringDynArray;
    pwds: array of TstringDynArray;
  public
    procedure reset();
    procedure track(usr, pwd: String); overload;
    procedure drop(const usr, pwd: String); overload;
    function match(const usr, pwd: String): Boolean; overload;
    function empty():boolean;
    end;

  Thasher = class(TStringList)
    procedure loadFrom(const path: String);
    function getHashFor(const fn: String): String;
    end;

  {$IFNDEF USE_MORMOT_COLLECTIONS}
  Tstr2str = Tdictionary<String, String>;
  {$ELSE USE_MORMOT_COLLECTIONS}
  Tstr2str = IKeyValue<string, String>;
  {$ENDIF USE_MORMOT_COLLECTIONS}

  TstringToIntHash = class(ThashedStringList)
    constructor create;
    function  getInt(const s: String): integer;
    function  getIntByIdx(idx: integer): integer;
    function  incInt(const s: String): integer;
    procedure setInt(const s: String; int: integer);
    end;

  TstringIntPairs = array of record
    str: string;
    int: integer;
   end;

  TZencoding=(E_PLAIN, E_B64, E_ZIP);

  TstringIntPairsHelper = record helper for TstringIntPairs
    function toStr(var userIconMasks: String; imgSize: Integer = 16): String;
    function AddFromStr(pStr: String): Integer;
    function AddUserIconMasksFromStr(pStr: String; imgSize: Integer = 16): Integer;
  end;

  TAccountsHelper = record helper for Taccounts
    function toStr(): String;
    function fromStr(pStr: String): Integer;
  end;

  TSectionName = RawByteString;
  PSections = ^TSections;
  TSections = TArray<TSectionName>;

  PtplSection = ^TtplSection;
  TtplSection = record
    name: TSectionName;
    txt: UnicodeString;
    nolog, public, noList, cache: boolean;
    ts: Tdatetime;
    end;

  {$IFNDEF USE_MORMOT_COLLECTIONS}
  Tstr2section = Tdictionary<TSectionName, PtplSection>;
  {$ELSE USE_MORMOT_COLLECTIONS}
  Tstr2section = IKeyValue<TSectionName, PtplSection>;
  {$ENDIF USE_MORMOT_COLLECTIONS}

  Ttpl = class
  protected
//    src: RawByteString;
    srcU: UnicodeString;
//    lastExt,   // cache for getTxtByExt()
//    last: record section:string; idx:integer; end; // cache for getIdx()
    fileExts: TStringDynArray;
    strTable: THashedStringList;
//    fUTF8: boolean;
    fOver: Ttpl;
    sections2: Tstr2section;
    function  getTxt(const section: TSectionName): UnicodeString;
    function  newSection(const section: TSectionName): PtplSection;
    procedure fromString(const txt: UnicodeString);
    function  toS: UnicodeString;
    procedure fromRaw(const txt: RawByteString);
    function  toRaw: RawByteString;
    procedure setOver(v:Ttpl);
    procedure clear();
  {$IFDEF USE_MORMOT_COLLECTIONS}
    function  DisposeSections(const aKey; var aValue;
      aIndex, aCount: integer; aOpaque: pointer): Boolean;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  public
    onChange: TNotifyEvent;
    constructor createResource(const ResourceName: String; over: Ttpl=NIL); OverLoad;
    constructor create(const txt: RawByteString=''; over: Ttpl=NIL); OverLoad;
    constructor create(const txt: String; over: Ttpl=NIL); OverLoad;
   {$IFDEF FPC}
    constructor create(const txt: UnicodeString; over: Ttpl=NIL); OverLoad;
   {$ENDIF FPC}
    destructor Destroy; override;
    property txt[const section: TSectionName]: UnicodeString read getTxt; default;
    property fullText: RawByteString read toRaw write fromRaw;
    property fullTextS: UnicodeString read toS write fromString;
//    property utf8:boolean read fUTF8;
    property over:Ttpl read fOver write setOver;
    function sectionExist(const section: TSectionName): Boolean;
    function getTxtByExt(const fileExt: String): UnicodeString;
    function getSection(section: TSectionName; inherit: Boolean=TRUE): PtplSection;
    function getSections(): TSections;
    procedure appendString(txt: UnicodeString);
    function getStrByID(const id: String): String;
    function me(): Ttpl;
    function anyMacroMarkerIn: Boolean;
   end; // Ttpl

  TcachedTplObj = class
    ts: Tdatetime;
    tpl: Ttpl;
   end;

  TcachedTpls = class(THashedStringList)
  public
    function getTplFor(fn: String): Ttpl;
    destructor Destroy; override;
   end; // TcachedTpls

  Ttlv = class
  protected
    cur, bound: integer;
    whole: RawByteString;
    lastValue: RawByteString;
    stack: array of integer;
    stackTop: integer;
  public
    constructor create(const data: RawByteString);
    procedure parse(const data: RawByteString);
//    function pop(var value:string): integer; OverLoad
    function pop(var value: RawByteString): integer;
    function down(): Boolean;
    function up(): Boolean;
    function getTotal(): Integer;
    function getCursor(): Integer;
    function getPerc(): Real;
    function isOver(): Boolean;
    function getTheRest(): RawByteString;
    end;

  TSessionId = String;

  Tsession = class
    fSrv: ThttpSrv;
    vars: THashedStringList;
    ttl: Double;
    created, expires: Tdatetime;
    user, ip, redirect: String;
    procedure setVar(k: TSessionId; const v: String);
    function getVar(k: TSessionId): String;
    class function sanitizeSID(s: TSessionId): TSessionId;
    class function getNewSID(): TSessionId;
  public
    id: TSessionId;
    constructor create(srv: ThttpSrv; const sid: TSessionId='');
    destructor Destroy; override;
    procedure init;
    procedure keepAlive();
    procedure setTTL(t: Tdatetime);
    property v[k: TSessionId]: String read getVar write setVar; default;
   end;

  {$IFNDEF USE_MORMOT_COLLECTIONS}
  TSessId2Sess = TDictionary<TSessionId, Tsession>;
  {$ELSE USE_MORMOT_COLLECTIONS}
  TSessId2Sess = IKeyValue<TSessionId, Tsession>;
  {$ENDIF USE_MORMOT_COLLECTIONS}

  Tsessions = class
   fSrv: ThttpSrv;
   fS2: TSessId2Sess;
  private
  {$IFDEF USE_MORMOT_COLLECTIONS}
    function onCheckExpired(const aKey; var aValue;
               aIndex, aCount: integer; aOpaque: pointer): boolean;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  public
    constructor create(srv: ThttpSrv);
    destructor Destroy; override;
    procedure  clearSession(sId: TSessionId);
    procedure  destroySession(sId: TSessionId);
    function   createSession(sId: TSessionId = ''): Tsession;
    function   initNewSession(peerIp: String = ''; sid: TSessionId = ''): TSessionId;
    function   getSession(sId: TSessionId): Tsession; OverLoad;
    function   noSession(sId: TSessionId): Boolean;
    procedure  keepAlive(sId: TSessionId);
    procedure  checkExpired;
    property   ss[sId: TSessionId]: Tsession read getSession; default;
  end;

  TParameter = record
    k: String;
    v: String;
    full: UnicodeString;
  end;

  {$IFNDEF USE_MORMOT_COLLECTIONS}
//  TParsVal = Tdictionary<string, Tdatetime>;
  TParsVal = TDictionary<String, String>;
  {$ELSE USE_MORMOT_COLLECTIONS}
  TParsVal = IKeyValue<String, String>;
  {$ENDIF USE_MORMOT_COLLECTIONS}

  TPars2 = class
   private
    fD2: TParsVal;
    fA: array of TParameter;
    fCount: Integer;
   public
    function  parEx(const name: string; doTrim: boolean=TRUE): string; overload;
    function  tryParToInt(const name: string; var val: Integer): Boolean;
    function  parExI(idx: integer; const name: string=''; doTrim: boolean=TRUE): string; overload;
    function  parExNE(idx: integer; const name: string=''; doTrim: boolean=TRUE): UnicodeString; overload;
    function  parExNE(const name: string; doTrim: boolean=TRUE):string; overload; // No Exception
    function  parExist(const names: array of string): Boolean; OverLoad;
    function  parExist(const name: string): Boolean; OverLoad;
    function  parExistVal(const name: String; var val: String; doTrim: boolean=TRUE): boolean;
   public
    constructor create;
    destructor  Destroy; OverRide;
    procedure Add(const s: String); OverLoad;
    procedure Add(const s: UnicodeString); OverLoad;
    procedure Delete(idx: Integer);
    function  get(idx: Integer): UnicodeString;
    function  getNames(idx: Integer): String;
    procedure setItem(idx: Integer; const s: UnicodeString);
    procedure clear;
    function  TryGetValue(const k: String; var v: String): Boolean; OverLoad;
    function  TryGetValue(const k: String; var v: UnicodeString): Boolean; OverLoad;
    function  ContainsKey(const k: String): Boolean;
    function  toArray: TStringDynArray;
    property  count: Integer read fCount;
    property  Items[Index: Integer]: UnicodeString read Get write setItem; default;
    property  names[Index: Integer]: String read GetNames;
    property  d2: TParsVal read fD2;
  end;

  TperIp = class // for every different address, we have an object of this class. These objects are never freed until hfs is closed.
    fSrv: ThttpSrv;
   public
    limiter: TspeedLimiter;
    customizedLimiter: boolean;
    constructor create(srv: ThttpSrv);
    destructor Destroy; override;
   end;

  TuploadResult = record
    fn, reason: String;
    speed: Integer;
    size: Int64;
   end;

  ThashFunc = function(const s: String): String;

  TconnDataMain = class abstract   // data associated to a client connection
  public
    class function getSafeHost(cd: TconnDataMain): String;
  public
    address: String;   // this is address shown in the log, and it is not necessarily the same as the socket address
    time: Tdatetime;  // connection start time
    requestTime: Tdatetime; // last request start time
    // cache User-Agent because often retrieved by connBox.
    // this value is filled after the http request is complete (HE_REQUESTED),
    // or before, during the request as we get a file (HE_POST_FILE).
    agent: string;
    conn: ThttpConn;
    limiter: TspeedLimiter;
    fileXferStart: Tdatetime;
    guiData: TObject;
    averageSpeed: real;   { calculated on disconnection as bytesSent/totalTime. it is calculated also while
                            sending and it is different from conn.speed because conn.speed is average speed
                            in the last second, while averageSpeed is calculated on ETA_FRAME seconds }
    eta: record
      idx: integer;   // estimation time (seconds)
      data: array [0..ETA_FRAME-1] of real;  // accumulates speed data
      result: Tdatetime;
      end;
    acceptedCredentials: boolean;
    usr, pwd: string;
    account: Paccount;
    sessionID: TsessionId;
    vars, // defined by {.set.}
    urlvars,  // as $_GET in php
    postVars  // as $_POST in php
      : THashedStringList;
    tpl: Ttpl;
    tplCounters: TstringToIntHash;
    workaroundForIEutf8: (WI_toDetect, WI_yes, WI_no);
    downloadingWhat: TdownloadingWhat;
    countAsDownload: Boolean; // cache the value for the Tfile method
    disconnectAfterReply, logLaterInApache, dontLog, fullDLlogged: boolean;
    banReason: String;
    disconnectReason: String;
    error: String;         // error details
    uploadFailed: String; // reason (empty on success)
    uploadSrc, uploadDest: String;
    uploadResults: array of TuploadResult;
    lastActivityTime: Tdatetime;
    lastFN: String;
    isLocalAddress: Boolean;
    procedure CreateLimiter(max: Integer=MAXINT);
    procedure RemoveLimiter;
    function  goodPassword(const pwd: String; s: String; func: ThashFunc): Boolean;
    function  passwordValidation(const pwd: String): Boolean;
//    procedure setSessionVar(const k, v: String);
    procedure disconnect(const reason: string);
    function  allowRecur: Boolean;
    function  getFilesSelection(): TStringDynArray;
    function  getLastRequested: String;
    function  isReplyFinished: Boolean;
    function  isDownloading: boolean;
    function  isSendingFile: Boolean;
    function  isReceivingFile: Boolean;
    function  getSpeed(): Real;
    function  getFileName(): String;
  end;

  TFileTree = TTreeView;
  TFileNode = TTreeNode;
  TFileNodeDynArray = array of TFileNode;

  IFile = interface;

  TFileEvent = procedure(f: TObject);
  TFileEventR = procedure(var s: RawByteString; f: TObject);

  IFileTree = interface
    procedure Repaint;
    procedure ClearItems;
    function  RemoveSecondRoot: Boolean;
    function  newNode(parent: TFileNode; const name: String; f: IFile): TFileNode;
    function  findNode(f: IFile): TFileNode;
    function  nodeToFile(node: TFileNode): TObject;
    function  nodeText(node: TFileNode): String;
    function  nodeHasChildren(node: TFileNode): Boolean;
    function  getParentNode(node: TFileNode): TFileNode;
    function  getFirstChild(node: TFileNode): TFileNode;
    function  getNextSibling(node: TFileNode): TFileNode;
    procedure DoImageChanged(Sender: IFile; n: TFileNode = NIL);
    procedure ChangedName(Sender: IFile; const Name: String);
    procedure DeleteChildren(node: TFileNode);
    procedure DeleteNode(node: TFileNode);
    procedure ExpandNode(node: TFileNode);
//    procedure ForAllSubNodes(Sender: TFileNode; proc: TProc<TFileNode>);
    procedure ForAllSubNodes(Sender: TFileNode; proc: TProc<IFile>);
  end;


  TfileAttribute = (
    FA_FOLDER,       // folder kind
    FA_VIRTUAL,      // does not exist on disc
    FA_ROOT,         // only the root item has this attribute
    FA_BROWSABLE,    // permit listing of this folder (not recursive, only dir)
    FA_HIDDEN,       // hidden items won't be shown to browsers (not recursive)
     //no more used attributes have to stay for backward compatibility with
    { VFS files }
    FA_NO_MORE_USED1,
    FA_NO_MORE_USED2,
    FA_TEMP,            // this is a temporary item and is not part of the VFS
    FA_HIDDENTREE,      // recursive hidden
    FA_LINK,            // redirection
    FA_UNIT,            // logical unit (drive)
    FA_VIS_ONLY_ANON,   // visible only to anonymous users [no more used]
    FA_DL_FORBIDDEN,    // forbid download (not recursive)
    FA_HIDE_EMPTY_FOLDERS,  // (recursive)
    FA_DONT_COUNT_AS_DL,    // (not recursive)
    FA_SOLVED_LNK,
    FA_HIDE_EXT,       // (recursive)
    FA_DONT_LOG,       // (recursive)
    FA_ARCHIVABLE      // (recursive)
  );
  TfileAttributes = set of TfileAttribute;

  TfileAction = (FA_ACCESS, FA_DELETE, FA_UPLOAD);
  TSpeedType = (ST_INCOME, ST_OUTCOME, ST_AVERAGE);
  TfileCallbackReturn = set of (FCB_NO_DEEPER, FCB_DELETE, FCB_RECALL_AFTER_CHILDREN); // use FCB_* flags

  // returning FALSE stops recursion
  TfileCallbackI = function(f: Ifile; childrenDone: boolean; par, par2: IntPtr): TfileCallbackReturn;

  IFile = interface
    procedure freeObject;
    function  getObject: TObject;
    function  getParent: IFile;
    function  getResource: UnicodeString;
    function  getFlags: TfileAttributes;
    function  getMainFileI: IFile;
    function  getNode: TFileNode;
    function  getFolder(): String;
    function  getName: String;
    procedure setName(const name: String);
    function  getUser: String;
    function  getPWD: String;
    function  getLnk: String;
    function  getComment: String;
    procedure setComment(sc: String);
    procedure setResource(const pRes: UnicodeString);
    procedure initSizeTime(pSize: Int64; pTime: TDateTime);
    function  getSize: Int64;
    function  getLocked: Boolean;
    procedure DeleteNode;
    function  isFolder(): Boolean;
    function  isFile(): Boolean;
    function  isFileOrFolder(): Boolean;
    function  isRealFolder(): Boolean;
    function  isVirtualFolder(): Boolean;
    function  isEmptyFolder(loadPrefs: TLoadPrefs; cd: TconnDataMain=NIL): Boolean;
    function  isArchive(): Boolean;
    function  isRoot(): Boolean;
    function  isLink(): Boolean;
    function  isTemp(): Boolean;
    function  isNew(): Boolean;
    function  isDLforbidden(): Boolean;
    function  getSystemIcon(): Integer;
    function  gotSystemIcon(): Boolean;
    function  getIconForTreeview(sysIcons: Boolean): Integer;
    function  getIcon: Integer;
    function  getHasThumb: Boolean;
    function  getTime(isAdded: Boolean): TDateTime;
    function  getDLcount(): Integer;
    function  relativeURL(doEncode: Boolean=FALSE): String;
    function  getDynamicComment(loadPrefs: TLoadPrefs; skipParent: Boolean=FALSE): String;
    function  getAccounts(fa: TfileAction): Types.TStringDynArray;
    procedure getFiltersRecursively(var files, folders: String);
    function  hasRecursive(attributes: TfileAttributes; orInsteadOfAnd: Boolean=FALSE; outInherited: Pboolean=NIL): Boolean; overload;
    function  hasRecursive(attribute: TfileAttribute; outInherited: Pboolean=NIL): Boolean; overload;
    procedure recursiveApplyI(callback: TfileCallbackI; par: IntPtr=0; par2: IntPtr=0);
    function  getAccountsFor(action: TfileAction; specialUsernames: Boolean=FALSE; outInherited: Pboolean=NIL): TstringDynArray;
    function  accessFor(const username, password: String): Boolean; overload;
    function  accessFor(cd: TconnDataMain): Boolean; overload;
    function  accountAllowed(action: TfileAction; cd: TconnDataMain): Boolean;
    procedure setAttr(a: TfileAttribute; isInclude: Boolean);
    procedure setupImage(sysIcons: Boolean; pNode: TFileNode = NIL);
    property  Parent: IFile read getParent;
    property  Resource: UnicodeString read getResource;
    property  name: String read getName write SetName;
    property  comment: String read getComment write setComment;
    property  lnk: String read getLnk;
    property  user: String read getUser;
    property  pwd: String read getPWD;
    property  size: Int64 read getSize;
    property  node: TFileNode read getNode;
    property  icon: Integer read getIcon;
    property  locked: Boolean read getLocked;
    property  hasThumb: Boolean read getHasThumb;
    property  flags: TfileAttributes read getFlags;
    property  DLcount: Integer read getDLcount;
    property  accounts[fa: TfileAction]: Types.TStringDynArray read getAccounts;
  end;

  IServerTree = interface
//    function  getMainTree: TFileTree;
    procedure DoImageChanged(Sender: TObject; n: TFileNode = NIL);
    procedure ChangedName(Sender: TObject; const Name: String);
    function  findNode(f: TObject): TFileNode;
    procedure DeleteChildren(f: TObject);
    procedure DeleteNode(f: TObject);
    procedure ForAllSubNodes(Sender: TObject; proc: TProc<TObject>);
    function  getParentNode(f: TObject): TFileNode;
    function  getFirstChild(f: TObject): TFileNode;
    function  getNextSibling(f: TObject): TFileNode;
    function  nodeToFile(n: TFileNode): TObject;
    function  nodeIsLocked(n: TFileNode): Boolean;
    function  nodeText(n: TFileNode): String;
    procedure setStatusBarText(const s: String; lastFor: Integer = 5);
//    property MainTree: TFileTree read getMainTree;
  end;

  {$IFNDEF USE_MORMOT_COLLECTIONS}
  TMacroTableVal = TDictionary<String, UnicodeString>;
  TMacroTableValPair = TPair<String, UnicodeString>;
  {$ELSE USE_MORMOT_COLLECTIONS}
  TMacroTableVal = IKeyValue<String, UnicodeString>;
  {$ENDIF USE_MORMOT_COLLECTIONS}

  TAdd2LogEvent = procedure(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault; doSync: Boolean = True);


  function conn2dataMain(p: Tobject): TconnDataMain; inline; overload;
  function conn2dataMain(srv: ThttpSrv; i: integer): TconnDataMain; inline; overload;
  function getETA(data: TconnDataMain): String;
  function countIPs(srv: ThttpSrv; onlyDownloading: boolean=FALSE; usersInsteadOfIps: boolean=FALSE): integer;
  function countConnectionsByIP(srv: ThttpSrv; const ip: String): Integer;
  function getGraphPic(cd: TconnDataMain; samplesLenght: Integer; w, h: Integer; var format: TContentTypeType): RawByteString;
  function newMacroTableVal: TMacroTableVal;

const
  FILEACTION2STR: array [TfileAction] of string = ('Access', 'Delete', 'Upload');

implementation

uses
  Math,
  dateUtils,
  {$IFNDEF FPC}
  ansiStrings,
  {$ENDIF ~FPC}
  RDFileUtil, RDUtils,
  IconsLib,
  HSUtils, scriptLib, srvUtils;

resourcestring
  MSG_ANTIDOS_REPLY = 'Please wait, server busy';

class constructor TantiDos.Create;

begin
  ip2availability2 := NIL;
  folderConcurrents := 0;
end;


constructor TantiDos.create();
begin
  accepted := FALSE;
  Paddress := '';
end;

function TantiDos.accept(conn: ThttpConn; address: String=''): Boolean;
  procedure reject();
  begin
    conn.reply.mode:=HRM_OVERLOAD;
    conn.addHeader(ansistring('Refresh: '+intToStr(1+random(2)))); // random for less collisions
    conn.reply.body:=UTF8Encode(MSG_ANTIDOS_REPLY);
  end;
begin
  if address= '' then
    address := conn.address;
  if ip2availability2 = NIL then
  {$IFNDEF USE_MORMOT_COLLECTIONS}
    ip2availability2 := Tip2av.create();
  {$ELSE USE_MORMOT_COLLECTIONS}
    ip2availability2 := Collections.NewKeyValue<String, TDateTime>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  try
    if ip2availability2.ContainsKey(address) then
     if ip2availability2[address] > now() then // this specific address has to wait?
      begin
        reject();
        exit(FALSE);
      end;
   except
  end;
  if folderConcurrents >= MAX_CONCURRENTS then   // max number of concurrent folder loading, others are postponed
    begin
      reject();
      exit(FALSE);
    end;
  inc(folderConcurrents);
  Paddress := address;
  if ip2availability2.ContainsKey(address) then
    ip2availability2[address] := now()+1/HOURS
   else
    ip2availability2.Add(address, now()+1/HOURS);
  accepted := TRUE;
  Result := TRUE;
end;

{$IFDEF USE_MORMOT_COLLECTIONS}
function TantiDos.RemoveOld(const aKey; var aValue;
    aIndex, aCount: integer; aOpaque: pointer): boolean;
var
  t: TDateTime;
begin
  t := PDateTime(aOpaque)^;
  if TDateTime(aValue) < t then
    ip2availability2.Data.DeleteAt(aIndex);
  Result := True;
end;
{$ENDIF USE_MORMOT_COLLECTIONS}

destructor TantiDos.Destroy;
var
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  pair: Tpair<String, Tdatetime>;
  {$ENDIF ~USE_MORMOT_COLLECTIONS}
  t: Tdatetime;
begin
  if not accepted then
    exit;
  t := now();
  if folderConcurrents = MAX_CONCURRENTS then // serving multiple addresses at max capacity, let's give a grace period for others
    ip2availability2[Paddress] := t + 1/SECONDS
   else
    ip2availability2.Remove(Paddress);
  dec(folderConcurrents);
// purge leftovers
  if ip2availability2.Count > 0 then
  {$IFNDEF USE_MORMOT_COLLECTIONS}
   for pair in ip2availability2 do
    if pair.Value < t then
      ip2availability2.Remove(pair.Key);
  {$ELSE USE_MORMOT_COLLECTIONS}
    ip2availability2.Data.ForEach(RemoveOld, @t);
  {$ENDIF USE_MORMOT_COLLECTIONS}

end;
//////////// TcachedTpls

destructor TcachedTpls.Destroy;
var
  i: integer;
begin
  if not Assigned(Self) then
    Exit;
 if count > 0 then
   for i:= count-1 to 0 do
     begin
       objects[i].free;
       objects[i] := NIL;
     end;
end;

function TcachedTpls.getTplFor(fn: String): Ttpl;
var
  i: integer;
  o: TcachedTplObj;
  s: RawByteString;
begin
  fn := trim(lowercase(fn));
  i := indexOf(fn);
  if i >= 0 then
    o := objects[i] as TcachedTplObj
   else
    begin
      o := TcachedTplObj.create();
      if addObject(fn, o) > 100 then
        delete(0);
    end;
  result := o.tpl;
  if getMtime(fn) = o.ts then
    exit;
  o.ts := getMtime(fn);
  s := loadFile(fn);
  if o.tpl = NIL then
    begin
    result := Ttpl.create();
    o.tpl := result;
    end;
  o.tpl.fromRaw(s);
end; // getTplFor

//////////// TusersInVFS

function TusersInVFS.empty():boolean;
begin
  result:= users = NIL
end;

procedure TusersInVFS.reset();
begin
users:=NIL;
pwds:=NIL;
end; // reset

procedure TusersInVFS.track(usr, pwd: string);
var
  i: integer;
begin
if usr = '' then exit;
i:=idxOf(usr, users);
if i < 0 then i:=addString(usr, users);
if i >= length(pwds) then setLength(pwds, i+1);
addString(pwd, pwds[i]);
end; // track

procedure TusersInVFS.drop(const usr, pwd: string);
var
  i, j: integer;
begin
i:=idxOf(usr, users);
if i < 0 then exit;
j:=AnsiIndexStr(pwd, pwds[i]);
if j < 0 then exit;
removeString(pwds[i], j);
if assigned(pwds[i]) then exit;
// this username does not exist with any password
removeString(users, i);
while i+1 < length(pwds) do
  begin
  pwds[i]:=pwds[i+1];
  inc(i);
  end;
setLength(pwds, i);
end; // drop

function TusersInVFS.match(const usr, pwd: String): Boolean;
var
  i: integer;
begin
result:=FALSE;
i:=idxOf(usr, users);
if i < 0 then exit;
result:= 0 <= AnsiIndexStr(pwd, pwds[i]);
end; // match

//////////// TiconsCache

function TiconsCache.idxOf(const data: string):integer;
var
  b, e, c: integer;
begin
result:=0;
if n = 0 then exit;
// binary search
b:=0;
e:=n-1;
  repeat
  result:=(b+e) div 2;
  c:=compareStr(data, icons[result].data);
  if c = 0 then exit;
  if c < 0 then e:=result-1;
  if c > 0 then b:=result+1;
  until b > e;
result:=b;
end; // idxOf

function TiconsCache.get(const data: String): PcachedIcon;
var
  i: integer;
begin
  result := NIL;
  i := idxOf(data);
  if (i >= 0) and (i < n) and (icons[i].data = data) then
    result := @icons[i];
end; // get

procedure TiconsCache.put(const data: String; idx: Integer; time: Tdatetime);
var
  i, w: integer;
begin
  if length(icons) <= n then
    setlength(icons, n+50);
  w := idxOf(data);
  for i:=n downto w+1 do
    icons[i]:=icons[i-1]; // shift
  icons[w].data:=data;
  icons[w].idx:=idx;
  icons[w].time:=time;
  inc(n);
end; // put

procedure TiconsCache.clear();
begin
icons:=NIL;
n:=0;
end; // clear

procedure TiconsCache.purge(olderThan:Tdatetime);
var
  i, m: integer;
begin
exit;
m:=0;
for i:=0 to n-1 do
  if icons[i].time < olderThan then dec(n) // this does not shorten the loop
  else
    begin
    if m < i then icons[m]:=icons[i];
    inc(m);
    end;
end; // purge

//////////// Thasher

procedure Thasher.loadFrom(const path: String);
var
  sr: TsearchRec;
  sA, l, h: RawByteString;
  f: String;
  p: String;
begin
  if path='' then
    exit;
  p := includeTrailingPathDelimiter(lowercase(path));
  if findFirst(p +'*.md5', faAnyFile-faDirectory, sr) <> 0 then
    exit;
  repeat
   sA := loadfile(p+sr.name);
  while sA > '' do
    begin
      l := chopline(sA);
      h:=trim(chop(RawByteString('*'),l));
      if h = '' then
        break;
      if l = '' then
        // assume it is referring to the filename without the extention
        f := copy(sr.name, 1, length(sr.name)-4)
       else
        f := UnUTF(l);
      add(p+lowercase(f)+'='+UnUTF(h));
    end;
  until findnext(sr) <> 0;
  sysutils.findClose(sr);
end; // loadFrom

function Thasher.getHashFor(const fn: String): String;
begin
  try
    result := values[lowercase(fn)]
   except
    result := ''
  end;
end;

//////////// TstringToIntHash

constructor TstringToIntHash.create;
begin
  inherited create;
  sorted := TRUE;
  duplicates := dupIgnore;
end; // create

function TstringToIntHash.getIntByIdx(idx:integer):integer;
begin
  if idx < 0 then
    result := 0
   else
    result := integer(objects[idx])
end;

function TstringToIntHash.getInt(const s:string):integer;
begin
  result := getIntByIdx(indexOf(s))
end;

procedure TstringToIntHash.setInt(const s:string; int:integer);
begin
  beginUpdate();
  objects[add(s)]:=Tobject(int);
  endUpdate();
end; // setInt

function TstringToIntHash.incInt(const s:string):integer;
var
  i: integer;
begin
  beginUpdate();
  i:=add(s);
  result:=integer(objects[i]);
  inc(result);
  objects[i]:=Tobject(result);
  endUpdate();
end; // autoupdatedFiles_getCounter

function TstringIntPairsHelper.toStr(var userIconMasks: String; imgSize: Integer = 16): String;
var
  i, j: integer;
begin
  result:='';
  if length(Self) > 0 then
   for i:=0 to length(Self)-1 do
    begin
    j:=idx_img2ico(Self[i].int);
    if j >= USER_ICON_MASKS_OFS then
      userIconMasks := userIconMasks+format('%d:%s|', [j, ZEncodeA(pic2str(j, imgSize), E_ZIP)]);
    result:=result+format('%s|%d||', [Self[i].str, j]);
    end;
end;

function TstringIntPairsHelper.AddFromStr(pStr: String): Integer;
var
  l: Integer;
begin
  Result := 0;
  while pStr > '' do
    begin
      l := length(Self);
      setLength(Self, l+1);
      Self[l].str := chop('|', pStr);
      Self[l].int := StrToIntDef(chop('||',pStr), 0);
      Inc(Result);
    end;
end; // strToIconmasks

function TstringIntPairsHelper.AddUserIconMasksFromStr(pStr: String; imgSize: Integer = 16): Integer;
var
  i, iFrom, iTo: integer;
//  userIconOfs: Integer;
begin
  Result := 0;
//  userIconOfs := IconsDM.images.Count;
  while pStr > '' do
    begin
      iFrom := strTointDef(chop(':', pStr), -1);
      iTo := str2pic(unzipRaw(chop('|', pStr)), imgSize);
      for i:=0 to length(Self)-1 do
        if Self[i].int = iFrom then
          Self[i].int:=iTo;
      Inc(Result);
    end;
end; // readUserIconmasks

function TAccountsHelper.ToStr(): String;
var
  i: integer;
  a: Paccount;

  function prop(const name, value:string; encoding:TZEncoding=E_PLAIN): string;
  begin
    if value > '' then
      result:='|'+name+':'+ ZEncodeW(value, encoding)
     else
      Result := '';
  end;

begin
  result := '';
  if Length(Self) > 0 then
  for i:=0 to length(Self)-1 do
  	begin
    a := @Self[i];
    result := result
      +prop('login', a.user+':'+a.pwd, E_B64)
      +prop('enabled', yesno[a.enabled])
      +prop('group', yesno[a.group])
      +prop('no-limits', yesno[a.noLimits])
      +prop('redir', a.redir)
      +prop('link', join(':',a.link))
      +prop('notes', a.notes, E_ZIP)
      +';';
    end;
end; // accountsToStr

function TAccountsHelper.fromStr(pStr: String): Integer;
  function yes(const s: String=''): Boolean;
  begin
    result := if_(s>'',s, pStr)='yes'
  end;
var

  s, t, p: string;
  i: integer;
  a: Paccount;
begin
  Result := 0;
  SetLength(Self, 0);
//  Self :=NIL;
  while pStr > '' do
    begin
    // accounts are separated by semicolons
    s := chop(';', pStr);
    if s = '' then
      continue;
    i := length(Self);
    setLength(Self, i+1);
    a := @Self[i];
    a.enabled:=TRUE; // by default
    while s > '' do
      begin
      // account properties are separated by pipes
      t:=chop('|',s);
      p:=chop(':',t); // get property name
      if p = '' then
        continue;
      if p = 'login' then
        begin
        if not anycharIn(':', t) then
          t:=decodeB64utf8(t);
        a.user:=chop(':',t);
        a.pwd:=t;
        end
       else
      if p = 'enabled' then a.enabled:=yes(t)
       else
      if p = 'no-limits' then a.noLimits:=yes(t)
       else
      if p = 'group' then a.group:=yes(t)
       else
      if p = 'redir' then a.redir:=t
       else
      if p = 'link' then a.link:=split(':',t)
       else
      if p = 'notes' then a.notes := unzipS(t);
      end;
    end;
end; // strToAccounts


//////////// Ttpl

constructor Ttpl.createResource(const ResourceName: String; over: Ttpl=NIL);
var
  lRaw: RawByteString;
begin
  lRaw := getResText(PChar(ResourceName));
  Create(lRaw, over);
end;

constructor Ttpl.create(const txt: RawByteString=''; over:Ttpl=NIL);
begin
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  sections2 := Tstr2section.Create();
  {$ELSE USE_MORMOT_COLLECTIONS}
  sections2 := Collections.NewKeyValue<TSectionName, PtplSection>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  fullText := txt;
  self.over := over;
end;

constructor Ttpl.create(const txt: String; over: Ttpl=NIL);
begin
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  sections2 := Tstr2section.Create();
  {$ELSE USE_MORMOT_COLLECTIONS}
  sections2 := Collections.NewKeyValue<TSectionName, PtplSection>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  fullTextS := txt;
  self.over := over;
end;

constructor Ttpl.create(const txt: UnicodeString; over: Ttpl=NIL);
begin
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  sections2 := Tstr2section.Create();
  {$ELSE USE_MORMOT_COLLECTIONS}
  sections2 := Collections.NewKeyValue<TSectionName, PtplSection>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  fullTextS := txt;
  self.over := over;
end;

destructor Ttpl.destroy;
begin
  fullText := ''; // this will cause the disposing
  inherited;
end; // destroy

function Ttpl.getStrByID(const id: String): String;
begin
  if strTable = NIL then
   begin
    strTable := THashedStringList.create;
    strTable.text:=txt['special:strings'];
   end;
  result := strTable.values[id];
  if (result = '') and assigned(over) then
    result := over.getStrByID(id)
end; // getStrByID

function Ttpl.newSection(const section: TSectionName): PtplSection;
begin
  new(result);
  sections2.Add(section, result);
  result.name := section;
end; // newSection

function Ttpl.sectionExist(const section: TSectionName): Boolean;
begin
  result := assigned(getSection(section));
  if not result and assigned(over) then
    result := over.sectionExist(section);
end;

function Ttpl.getSection(section: TSectionName; inherit:boolean=TRUE):PtplSection;
begin
  result := NIL;
  if sections2.containsKey(section) then
   if not sections2.TryGetValue(section, result) then
     result := NIL;
  if inherit and assigned(over) and (result = NIL) then
    result := over.getSection(section);
end; // getSection

function Ttpl.getTxt(const section: TSectionName): UnicodeString;
var
  p: PTplSection;
begin
  p := getSection(section);
  if p <> NIL then
    result := p.txt
  else
    result := ''
end; // getTxt

function Ttpl.getTxtByExt(const fileExt: String): UnicodeString;
begin
  result := getTxt('file'+fileExt)
end;

{$IFDEF USE_MORMOT_COLLECTIONS}
function Ttpl.DisposeSections(const aKey; var aValue;
    aIndex, aCount: integer; aOpaque: pointer): Boolean;
var
  p: PtplSection;
begin
  p := PtplSection(aValue);
  dispose(p);
  PtplSection(aValue) := NIL;
  Result := True;
end;
{$ENDIF USE_MORMOT_COLLECTIONS}

procedure Ttpl.clear();
{$IFNDEF USE_MORMOT_COLLECTIONS}
var
  p: PtplSection;
{$ENDIF ~USE_MORMOT_COLLECTIONS}
begin
  srcU := '';
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  for p in sections2.values do
    dispose(p);
  {$ELSE USE_MORMOT_COLLECTIONS}
  sections2.Data.ForEach(DisposeSections);
  {$ENDIF USE_MORMOT_COLLECTIONS}
  sections2.clear();
  freeAndNIL(strTable);  // mod by mars
end;

procedure Ttpl.fromRaw(const txt: RawByteString);
var
  s: String;
begin
  clear;
  s := unUTF(txt);
  appendString(s);
end; // fromString

procedure Ttpl.fromString(const txt: UnicodeString);
begin
  clear;

  appendString(txt);
end; // fromString

function Ttpl.toRaw: RawByteString;
begin
  Result := utf8Encode(srcU);
end;

function Ttpl.toS: UnicodeString;
begin
  Result := srcU;
end;

procedure Ttpl.appendString(txt: UnicodeString);
var
  ptxt, bos: PUnicodeChar;
  cur_section, next_section: UnicodeString;

  function pred(p: PUnicodeChar): PUnicodeChar; inline;
  begin
  result:=p;
  if p <> NIL then
    dec(result);
  end;

  function succ(p: PUnicodeChar): PUnicodeChar; inline;
  begin
  result:=p;
  if p <> NIL then
    inc(result);
  end;

  procedure findNextSection();
  begin
  // find start
    bos := ptxt;
    repeat
      if bos^ <> '[' then
        //bos := strpos(bos, #10'[');
       bos := strpos(bos, #10'[');
      if bos = NIL then exit;
      if bos^ = #10 then inc(bos);
      if getSectionAt(bos, next_section) then
        exit;
      inc(bos);
    until false;
  end; // findNextSection

  procedure saveInSection();
  var
    base: TtplSection;

    function parseFlagsAndAcceptSection(flags: TUnicodeStringDynArray): Boolean;
    var
      f, k, v, s: UnicodeString;
      i: integer;
    begin
    for f in flags do
      begin
      i:=pos('=',f);
      if i = 0 then
        begin
        if f='no log' then
          base.nolog:=TRUE
        else if f='public' then
          base.public:=TRUE
        else if f='no list' then
          base.noList:=TRUE
        else if f='cache' then
          base.cache:=TRUE;
        Continue;
        end;
      k:=copy(f,1,i-1);
      v:=copy(f,i+1,MAXINT);
      if k = 'build' then
        begin
        s:=chop('-',v);
        if (v > '') and (VERSION_BUILD > v) // max
        or (s > '') and (VERSION_BUILD < s) then // min
          exit(FALSE);
        end
      else if k = 'ver' then
        if fileMatch(v, VERSION) then continue
        else exit(FALSE)
      else if k = 'template' then
        if fileMatch(v, getTill(#13,getTxt('template id'))) then continue
        else exit(FALSE)
      end;
    result:=TRUE;
    end;
  var
    ss: TUnicodeStringDynArray;
    s: UnicodeString;
    si: UnicodeString;
    till: PUnicodeChar;
    append, prepend, add: boolean;
    sect, from: PtplSection;
  begin
    till := pred(bos);
    if till = NIL then
      till:=pred(strEnd(ptxt));
    if till^ = #10 then dec(till);
    if till^ = #13 then dec(till);

    base := default(TtplSection);
    base.txt := getStr(ptxt, till);
    base.ts := now();
    ss := UnicodeSplit('|', cur_section);
    cur_section := popString(ss);
    if not parseFlagsAndAcceptSection(ss) then
      exit;

    prepend := startsStr('^', cur_section);
    append := ansiStartsStr('+', cur_section);
    add := prepend or append;
    if add then
      delete(cur_section,1,1);

  // there may be several section names separated by =
    ss := UnicodeSplit('=', cur_section);
  // handle the main section specific case
    if ss = NIL then
      addString('', ss);
  // assign to every name the same txt
    for si in ss do
     begin
      s:=trim(si);
      sect:=getSection(s, FALSE);
      from:=NIL;
      if sect = NIL then // not found
        begin
        if add then
          from:=getSection(s);
        sect:=newSection(s);
        end
      else
        if add then
          from:=sect;
      if from<>NIL then
        begin // inherit from it
        if append then
          sect.txt := from.txt+base.txt
         else
          sect.txt := base.txt+CRLF+from.txt;
        sect.nolog:=from.nolog or base.nolog;
        sect.public:=from.public or base.public;
        sect.noList:=from.noList or base.noList;
        continue;
        end;
      sect^:=base;
      sect.name:=s; // restore this lost attribute
     end;
  end; // saveInSection

//const
//  BOM = RawByteString(#$EF#$BB#$BF);
var
  first: boolean;
begin
// this is used by some unicode files. at the moment we just ignore it.
//  if ansiStartsStr(BOM, txt) then
//    delete(txt, 1, length(BOM));

  if txt = '' then
    exit;
  srcU := srcU + txt;
  cur_section := '';
  ptxt := @txt[1];
  first := TRUE;
  repeat
    findNextSection();
    if not first or (trim(getStr(ptxt, pred(bos))) > '') then
      saveInSection();
    if bos = NIL then
      break;
    cur_section := next_section;
    inc(bos, length(cur_section)); // get faster to the end of line
    ptxt:=succ(StrPos(bos, #10)); // get to the end of line (and then beyond)
    first:=FALSE;
  until ptxt = NIL;
  if assigned(onChange) then
    onChange(self);
end; // appendString

procedure Ttpl.setOver(v: Ttpl);
begin
  fOver := v;
end; // setOver

function Ttpl.getSections(): TSections;
 {$IFDEF USE_MORMOT_COLLECTIONS}
var
  i: Integer;
  d: TSynDictionary;
 {$ENDIF USE_MORMOT_COLLECTIONS}
begin
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  result := sections2.Keys.ToArray();
  {$ELSE USE_MORMOT_COLLECTIONS}
  d := sections2.Data;
  if Assigned(d) then //and (d.Keys <> NIL) then
    begin
      SetLength(Result, d.Keys.Count);
      if Length(Result) > 0 then
        for I := Low(Result) to High(Result) do
//          Result[i] := PString(d.Keys.ItemPtr(i))^;
          Result[i] := PRawByteString(d.Keys.ItemPtr(i))^;
    end;
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

function Ttpl.me(): Ttpl;
begin
  result := self
end;

function Ttpl.anyMacroMarkerIn: Boolean;
begin
  Result := scriptLib.anyMacroMarkerIn(Self.fullTextS);
end;

constructor Ttlv.create(const data: RawByteString);
begin
  Inherited create;
  parse(data);
end;

procedure Ttlv.parse(const data: RawByteString);
begin
  whole := data;
  cur := 1;
  bound := length(data);
  stackTop := 0;
end; // parse

function Ttlv.pop(var value: RawByteString): integer;
var
  n: integer;
begin
  result := -1;
  if isOver() then
    exit; // finished
  result := integer((@whole[cur])^);
  n := Pinteger(@whole[cur+4])^;
  value :=  copy(whole, cur+8, n);
  lastValue := value;
  inc(cur, 8+n);
end;

function Ttlv.down():boolean;
begin
// do we have anything to recur on?
if (cur = 1) then
  begin
  result:=false;
  exit;
  end;
// push into the stack
if (stackTop = length(stack)) then // space over
  setLength(stack, stackTop+10); // make space
stack[stackTop]:=cur;
inc(stackTop);
stack[stackTop]:=bound;
inc(stackTop);

bound:=cur;
dec(cur, length(lastValue));
result:=true;
end; // down

function Ttlv.up():boolean;
begin
if stackTop = 0 then
  exit(FALSE);
dec(stackTop);
bound:=stack[stackTop];
dec(stackTop);
cur:=stack[stackTop];
result:=true;
end; // up

function Ttlv.getTotal():integer;
begin
  result:=length(whole)
end;

function Ttlv.getCursor():integer;
begin
  result:=cur
end;

function Ttlv.getPerc():real;
begin
if length(whole) = 0 then result:=0
else result:=cur/length(whole)
end; // getPerc

function Ttlv.isOver():boolean;
begin
  result:=(cur+8 > bound)
end;

function Ttlv.getTheRest(): RawByteString;
begin
  result:=substr(whole, cur, bound)
end;

procedure TconnDataMain.CreateLimiter(max: Integer=MAXINT);
begin
  limiter := TspeedLimiter.create(max);
  conn.limiters.add(limiter);
//  fs.addLimiter(limiter);
end;

procedure TconnDataMain.RemoveLimiter;
begin
//  fs.removeLimiter(limiter);
  conn.limiters.remove(limiter);
  freeAndNIL(limiter);

end;

function TconnDataMain.goodPassword(const pwd: String; s: string; func: ThashFunc): boolean;
var
  a: String;
begin
  s := postVars.values[s];
  Result := s > '';
  if Result then
   begin
    a := func(func(pwd)+ sessionId);
    result:= s = a
   end;
end;

function TconnDataMain.passwordValidation(const pwd: String):boolean;
begin
  Result := (postVars.values['password'] = pwd)
         or goodPassword(pwd, 'passwordSHA256', strSHA256)
         or goodPassword(pwd, 'passwordMD5', strMD5)
end;

function TconnDataMain.allowRecur: Boolean;
begin
  Result := (urlvars.indexOf('recursive') >= 0) or (urlvars.values['search'] > '');
end;

{
procedure TconnDataMain.setSessionVar(const k, v: String);
var
  s: TSession;
begin
  s := sessions.getSession(sessionId);
  s.v[k] := v;
end;
}
function TconnDataMain.getFilesSelection(): TStringDynArray;
var
  i: Integer;
begin
  result:=NIL;
  for i :=0 to postvars.count-1 do
    if sameText('selection', postvars.names[i]) then
      addString(getTill('#', postvars.valueFromIndex[i]), result) // omit #anchors
end; // getFilesSelection

function TconnDataMain.getLastRequested: String;
begin
  if (conn.reply.bodyMode=RBM_RAW)or(conn.reply.bodyMode=RBM_TEXT) then
    Result := decodeURL(conn.httpRequest.url)
   else
    Result := lastFN;
end;

function TconnDataMain.isReplyFinished: Boolean;
begin
  Result := (conn.httpState <> HCS_REPLYING_BODY) or
  (conn.bytesSentLastItem = conn.bytesPartial);
end;

function TconnDataMain.isDownloading: boolean;
begin
  result := assigned(Self) and Self.countAsDownload
     and (Self.conn.httpState in [HCS_REPLYING_BODY, HCS_REPLYING_HEADER, HCS_REPLYING])
end; // isDownloading

function TconnDataMain.isSendingFile: Boolean;
begin
  result := Assigned(Self)
    and (Self.conn.httpState = HCS_REPLYING_BODY)
    and (Self.conn.reply.bodyMode in [RBM_FILE, RBM_STREAM])
    and (Self.downloadingWhat in [DW_FILE, DW_ARCHIVE])
end; // isSendingFile

function TconnDataMain.isReceivingFile: Boolean;
begin
  result := assigned(Self) and (Self.conn.httpState = HCS_POSTING) and (Self.uploadSrc > '')
end;

function TconnDataMain.getSpeed(): Real;
begin
  case conn.httpState of
    HCS_REPLYING_BODY: Result := conn.speedOut;
    HCS_POSTING: Result := conn.speedIn;
   else
     Result := averageSpeed;
  end;
end;

function TconnDataMain.getFileName(): String;
begin
  if isSendingFile then
    result := lastFN
   else if isReceivingFile then
    result := uploadSrc
   else
    result := '-'
end;

procedure TconnDataMain.disconnect(const reason: string);
begin
  disconnectReason := reason;
  conn.disconnect();
end; // disconnect

class function TconnDataMain.getSafeHost(cd: TconnDataMain): String;
begin
  result := srvUtils.getSafeHost(cd);
end; // getSafeHost

class function Tsession.getNewSID():TSessionId;
begin
  result:=sanitizeSID(b64U(str_(now())+str_(random())))
end;

class function Tsession.sanitizeSID(s:TSessionId):TSessionId;
//begin result:=reReplace(s, '[\D\W]', '', '!') end;
begin
  result:=reReplace(s, '[^0-9a-zA-Z]', '', '!')
end;

constructor Tsession.create(srv: ThttpSrv; const sid: String='');
begin
  id := sid;
  if Length(id) < 10 then
    id := getNewSID();
  fSrv := srv;
//sessions.Add(id, self);
  init;
end;
procedure Tsession.init;
begin
  created := now();
  ttl:=1; // days
  user := '';
  ip := '';
  redirect := '';
  keepAlive();
end;

destructor Tsession.Destroy;
var
  cd: TconnDataMain;
  o: ThttpConn;
begin
  for o in fSrv.conns do
  begin
    cd := ThttpConn(o).data;
    if cd.sessionID = self.id then
      cd.sessionID := '';
  end;
//sessions.remove(id);
  freeAndNIL(vars);
end;

procedure Tsession.keepAlive();
begin
  expires := now() + ttl
end;

function Tsession.getVar(k: TSessionId): String;
begin
  Result := '';
  if vars = NIL then
    Exit
   else
     if vars.IndexOfName(k) >= 0 then
      try
        result:=vars.values[k];
       except
        result:=''
      end;
end; // sessionGet

procedure Tsession.setVar(k: TSessionId; const v: String);
begin
  if vars= NIL then
    vars := THashedStringList.create;
  vars.addPair(k,v);
end;

procedure Tsession.setTTL(t: Tdatetime);
begin
  ttl:=t;
  keepAlive();
end;

constructor Tsessions.create(srv: ThttpSrv);
begin
  fSrv := srv;
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  fS2 := TSessId2Sess.Create();
  {$ELSE USE_MORMOT_COLLECTIONS}
  fS2 := Collections.NewKeyValue<TSessionId, Tsession>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

destructor Tsessions.Destroy;
begin
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  FreeAndNil(fS2);
  {$ELSE USE_MORMOT_COLLECTIONS}
  fS2 := NIL;
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

function Tsessions.getSession(sId: TSessionId): Tsession;
begin
  if not fS2.TryGetValue(sId, Result) then
    Result := NIL;
end;

function Tsessions.createSession(sId: TSessionId = ''): Tsession;
begin
  result := Tsession.create(fSrv, sid);
  fS2.Add(result.id, result);
end;

function Tsessions.initNewSession(peerIp: String = ''; sid: TSessionId = ''): TSessionId;
var
  s: Tsession;
begin
  s := getSession(sid);
  if s = NIL then
    s := createSession(sid);
  s.init;
  Result := s.id;
  s.ip := peerIp;
end;

procedure Tsessions.clearSession(sId: TSessionId);
begin
  fS2.Remove(sId);
end;

procedure Tsessions.destroySession(sId: TSessionId);
var
  s: Tsession;
begin
  s := getSession(sId);
  if Assigned(s) then
    begin
      fS2.Remove(sId);
      s.free;
    end;
end;

function Tsessions.noSession(sId: TSessionId): Boolean;
var
  s: TSession;
begin
  Result := (sID = '') or not fS2.ContainsKey(sId);
  if not Result then
   // Check if session was expired
    begin
      s := fS2.Items[sId];
      Result := s.expires < now;
    end;
end;

procedure Tsessions.keepAlive(sId: TSessionId);
var
  s: Tsession;
begin
  s := ss[sId];
  if Assigned(s) then
    s.keepAlive;
end;

{$IFDEF USE_MORMOT_COLLECTIONS}
function Tsessions.onCheckExpired(const aKey; var aValue;
    aIndex, aCount: integer; aOpaque: pointer): boolean;
var
  sId: TSessionId;
begin
  if Tsession(aValue) <> NIL then
   if PDateTime(aOpaque)^ > Tsession(aValue).expires then
   begin
    sId := Tsession(aValue).id;
    Tsession(aValue).free;
    Tsession(aValue) := NIL;
//    fS2.Items[sId] := NIL;
    fS2.Data.DeleteAt(aIndex);
   end;
  Result := True;
end;
{$ENDIF USE_MORMOT_COLLECTIONS}

procedure Tsessions.checkExpired;
var
  now_: TDateTime;
 {$IFNDEF USE_MORMOT_COLLECTIONS}
  sId: TSessionId;
  sess: Tsession;
 {$ENDIF USE_MORMOT_COLLECTIONS}
begin
  now_ := now();
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  for sess in self.fS2.Values do
   if now_ > sess.expires then
   begin
    sId := sess.id;
    sess.free;
    self.fS2.Items[sId] := NIL;
    self.fS2.Remove(sId);
   end;
  {$ELSE USE_MORMOT_COLLECTIONS}
  self.fS2.Data.ForEach(onCheckExpired, @now_);
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

constructor TPars2.create;
begin
  fCount := 0;
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  fD2 := TParsVal.Create;
  {$ELSE USE_MORMOT_COLLECTIONS}
  fD2 := Collections.NewKeyValue<String, String>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  setLength(fA, 0);
end;

destructor TPars2.Destroy;
begin
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  fD2.Free;
  {$ELSE USE_MORMOT_COLLECTIONS}
  fD2 := NIL;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  SetLength(fA, 0);
  fCount := 0;
end;

procedure TPars2.Add(const s: UnicodeString); OverLoad;
var
  i, idx: Integer;
begin
  idx := Length(fA);
  SetLength(fA, idx+1);
  fCount := idx+1;
  fA[idx].full := s;
  i := Pos(UnicodeString('='), s);
  if (i > 0)and(i<125) then
    begin
      fA[idx].k := copy(s, 1, i-1);
      fA[idx].v := copy(s, i+1, length(s))
    end
   else
    begin
//      fA[idx].k := s;
      fA[idx].k := '';
      fA[idx].v := '';
    end;
  if fA[idx].k > '' then
  {$IFNDEF USE_MORMOT_COLLECTIONS}
    fD2.AddOrSetValue(fA[idx].k, fA[idx].v);
  {$ELSE USE_MORMOT_COLLECTIONS}
    fD2[fA[idx].k] := fA[idx].v;
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

procedure TPars2.Add(const s: String);
var
  i, idx: Integer;
begin
  idx := Length(fA);
  SetLength(fA, idx+1);
  fCount := idx+1;
  fA[idx].full := s;
  i := AnsiPos('=', s);
  if (i > 0)and(i<125) then
    begin
      fA[idx].k := copy(s, 1, i-1);
      fA[idx].v := copy(s, i+1, length(s))
    end
   else
    begin
//      fA[idx].k := s;
      fA[idx].k := '';
      fA[idx].v := '';
    end;
  if fA[idx].k > '' then
  {$IFNDEF USE_MORMOT_COLLECTIONS}
    fD2.AddOrSetValue(fA[idx].k, fA[idx].v);
  {$ELSE USE_MORMOT_COLLECTIONS}
    fD2[fA[idx].k] := fA[idx].v;
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

procedure TPars2.Delete(idx: Integer);
var
  I: Integer;
begin
  if idx >= fCount then
    Exit;
  if fA[idx].k > '' then
    fD2.Remove(fA[idx].k);
  if idx < (fCount-1) then
    for I := idx to fCount-2 do
      fA[i] := fA[i+1];
  dec(fCount);
  SetLength(fA, fCount);
end;

function TPars2.get(idx: Integer): UnicodeString;
begin
  Result := fA[idx].full;
end;

function TPars2.getNames(idx: Integer): String;
begin
  Result := fA[idx].k;
end;

procedure TPars2.setItem(idx: Integer; const s: UnicodeString);
var
  k, v: string;
  i: Integer;
begin
  i := Pos(UnicodeString('='), s);
  if (i > 0)and(i<126) then
    begin
      k := copy(s, 1, i-1);
      v := copy(s, i+1, length(s))
    end
   else
    begin
//      k := s;
      k := '';
      v := '';
    end;

  if k = fA[idx].k then
    begin
      if k > '' then
//        fD.AddOrSetValue(k, v);
        fD2[k] := v;
    end
   else
    begin
      if fA[idx].k > '' then
        fD2.Remove(fA[idx].k);
      if k > '' then
        fD2.Add(k, v);
      fA[idx].k := k;
    end;

  fA[idx].v := v;
  fA[idx].full := s;
end;

function TPars2.TryGetValue(const k: String; var v: String): Boolean;
begin
  Result := fD2.TryGetValue(k, v);
end;

function TPars2.TryGetValue(const k: String; var v: UnicodeString): Boolean; OverLoad;
var
  v2: String;
begin
  Result := fD2.TryGetValue(k, v2);
  if Result then
    v := v2;
end;

function TPars2.ContainsKey(const k: String): Boolean;
begin
  Result := fD2.ContainsKey(k);
end;

procedure TPars2.clear;
begin
  fCount := 0;
  SetLength(fA, 0);
  fD2.clear;
end;

function TPars2.ToArray: TStringDynArray;
var
  i: integer;
begin
  if Length(fA) = 0 then
    Exit(NIL);
  try
    setLength(result, Length(fA));
      for i:=0 to Length(fA)-1 do
        result[i] := fA[i].full;
  except
    result:=NIL
    end
end; // ToArray

function TPars2.parEx(const name: string; doTrim: boolean=TRUE): string;
begin
  result:='';
  if name > '' then
    begin
//      i:=pars.IndexOfName(name);
      if Self.TryGetValue(name, Result) then
        if doTrim then
          Exit(trim(result))
         else
          exit;
    end;
  raise Exception.create('invalid parameter index');
end; // parEx

function TPars2.tryParToInt(const name: string; var val: Integer): Boolean;
var
  s: String;
begin
  result := false;
  if name > '' then
    begin
      if Self.TryGetValue(name, s) then
       begin
        Result := TryStrToInt(s, val);
       end;
    end;
end; // tryParToInt

function TPars2.parExI(idx: integer; const name: string=''; doTrim: boolean=TRUE): string;
//  var
//    i: integer;
begin
  result:='';
  if name > '' then
    begin
//      i:=pars.IndexOfName(name);
      if Self.TryGetValue(name, Result) then
        if doTrim then
          Exit(trim(result))
         else
          exit;
    end;
  if (idx < 0) // no numeric index accept
  or (idx >= Self.count) // invalid index
  or (name > '') and (Self.names[idx] > '') and not anycharIn(' '#13#10, Self.names[idx]) // this numerical index was already taken by a valid mnemonic name
  then
    raise Exception.create('invalid parameter index');
  result := Self[idx];
  if doTrim then
    result := trim(result);
end; // parExI

function TPars2.parExNE(idx: integer; const name: string=''; doTrim: boolean=TRUE): UnicodeString;
//  var
//    i: integer;
begin
  result := '';
  if name > '' then
    begin
      if Self.TryGetValue(name, Result) then
        if doTrim then
          Exit(trim(result))
         else
          exit;
    end;
  if (idx < 0) // no numeric index accept
  or (idx >= Self.count) // invalid index
  or (name > '') and (Self.names[idx] > '') and not anycharIn(' '#13#10, Self.names[idx]) // this numerical index was already taken by a valid mnemonic name
  then
    Exit('');
  result := Self[idx];
  if doTrim then
    result := trim(result);
end; // parExNE

function TPars2.parExNE(const name: string; doTrim: boolean=TRUE): String; // No Exception
begin
  Result := '';
  if name > '' then
    begin
      if Self.TryGetValue(name, Result) then
        if doTrim then
          Exit(trim(result))
         else
          exit;
    end;
end;

// note this function works on N parameters
function TPars2.parExist(const names: array of string): Boolean;
var
  i: integer;
begin
  result := FALSE;
  for i:=0 to length(names)-1 do
    if not Self.ContainsKey(names[i]) then
      exit;
  result := TRUE;
end; // parExist

function TPars2.parExist(const name: string): Boolean;
begin
  result := Self.ContainsKey(name);
end; // parExist

function TPars2.parExistVal(const name: String; var val: String; doTrim: boolean=TRUE): boolean;
begin
  Result := false;
  val := '';
  if name > '' then
    begin
      Result := Self.TryGetValue(name, val);
      if Result then
        if doTrim then
          val := trim(val)
    end;
end; // parExistVal

constructor TperIp.create(srv: ThttpSrv);
begin
  fSrv := srv;
  limiter := TspeedLimiter.create();
  srv.limiters.add(limiter);
end;

destructor TperIp.Destroy;
begin
  fSrv.limiters.remove(limiter);
  limiter.free;
end;

function conn2dataMain(p: Tobject): TconnDataMain; inline; overload;
begin
  if p = NIL then
    result := NIL
   else
    result := TconnDataMain((p as ThttpConn).data)
end; // conn2dataMain

function conn2dataMain(srv: ThttpSrv; i: integer): TconnDataMain; inline; overload;
begin
  try
    if i < srv.conns.count then
      result := conn2dataMain(srv.conns[i])
    else
      result := conn2dataMain(srv.offlines[i-srv.conns.count])
   except
    result := NIL
  end
end; // conn2dataMain

function getETA(data: TconnDataMain): String;
begin
  if (data.conn.httpState in [HCS_REPLYING_BODY, HCS_POSTING])
   and (data.eta.idx > ETA_FRAME) then
    result := elapsedToStr(data.eta.result)
   else
    result := '-'
end; // getETA

function countIPs(srv: ThttpSrv; onlyDownloading: boolean=FALSE; usersInsteadOfIps: boolean=FALSE): integer;
var
  i: integer;
  d: TconnDataMain;
  ips: TStringDynArray;
begin
  i := 0;
  ips := NIL;
  while i < srv.conns.count do
    begin
    d := conn2dataMain(srv, i);
    if Assigned(d) and (not onlyDownloading or d.isDownloading) then
      addUniqueString(if_(usersInsteadOfIps, d.usr, d.address), ips);
    inc(i);
    end;
  result := length(ips);
end; // countIPs

function countConnectionsByIP(srv: ThttpSrv; const ip: String): Integer;
var
  i: integer;
begin
  result:=0;
  i:=0;
  while i < srv.conns.count do
    begin
    if conn2dataMain(srv, i).address = ip then
      inc(result);
    inc(i);
    end;
end; // countConnectionsByIP

function getGraphPic(cd: TconnDataMain; samplesLenght: Integer; w, h: Integer; var format: TContentTypeType): RawByteString;
var
  bmp: Tbitmap;
  refresh: string;
  i: integer;
  colors: TIntegerDynArray;
  options: string;

  procedure addColor(c: Tcolor);
  var
    n: integer;
  begin
    n := length(colors);
    setLength(colors, n+1);
    colors[n] := c;
  end; // addColor

begin
  options := copy(decodeURL(cd.conn.httpRequest.url), 12, MAXINT);
  delete(options, pos('?',options), MAXINT);
  bmp := Tbitmap.create;
  bmp.SetSize(w, h);
  colors := NIL;
  if options = '' then
    begin
      // here is an initial support for ?parameters. colors not supported yet.
      try
        bmp.width := strToInt(cd.urlvars.Values['w'])
       except
      end;
      try
        bmp.height := min(strToInt(cd.urlvars.Values['h']), 300000 div max(1,bmp.width))
       except
      end;
      refresh := cd.urlvars.Values['refresh'];
    end
   else
    try
      i := strToInt(chop('x',options));
      if (i > 0) and (i <= samplesLenght) then
        bmp.Width:=i;
      i := strToInt(chop('x',options));
      if (i > 0) and (i <= samplesLenght) then
        bmp.height := min(i, 300000 div max(1,bmp.width));
      refresh := chop('x',options);
      for i:=1 to 5 do
        addColor(stringToColorEx(chop('x',options), graphics.clDefault));
     except
    end;
  drawGraphOn(bmp.canvas, colors);
  if bmp2strWebPAllowed and (ipos('image/webp', cd.conn.getHeader('Accept')) > 0) then
    begin
      Result := bmp2strWebP(bmp);
      format := webpMime;
    end
   else
    begin
      Result := bmp2str(bmp);
      format := pngMime;
    end;
  bmp.free;
  if cd = NIL then
    exit;
  cd.conn.addHeader(RawByteString('Cache-Control'), 'no-cache');
  if refresh > '' then
    cd.conn.addHeader('Refresh', refresh);
end; // getGraphPic

function newMacroTableVal: TMacroTableVal;
begin
 {$IFNDEF USE_MORMOT_COLLECTIONS}
  Result := TMacroTableVal.Create;
 {$ELSE USE_MORMOT_COLLECTIONS}
  Result := Collections.NewKeyValue<String, UnicodeString>;
 {$ENDIF USE_MORMOT_COLLECTIONS}
end;


end.
