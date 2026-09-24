{$INCLUDE defs.inc }
unit logLib;
{$I NoRTTI.inc}

interface
uses
  Windows, SysUtils, Graphics, SyncObjs,
  hsLib, srvConst, serverLib,
  srvClassesLib
  ;

type
  PLogData = ^TLogData;
  TLogData = record
    id: Integer;              // monotonic id for incremental clients
    lines: UnicodeString;
    time: TDateTime;
    addr: String;
    address: String;
    fileStr: String;
    fileDynName: String;
    clr: Tcolor;
   {$IFDEF SHOW_GEO_BY_IP}
//    cc: String; // CountryCode
    countryNum: Cardinal;
   {$ENDIF SHOW_GEO_BY_IP}
  end;
  TLogDatas = array of TLogData;

  TAdd2LogEvent = procedure(data: TLogData; doSync: Boolean = True) of Object;

  procedure add2logData(var ld: TLogData; const lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault);

  function getDynLogFilename(cd: TconnDataMain): String;

  procedure doServerLog(conn: ThttpConn; data: TconnData; event: ThttpEvent);

 {$IFDEF FMX}
  procedure add2Log(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= TAlphaColorRec.Null; doSync: Boolean = True);
 {$ELSE ~FMX}
  procedure add2Log(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault; doSync: Boolean = True);
 {$ENDIF FMX}
  procedure applyISOdateFormat();

  /// Snapshot of recent in-memory log lines (ring buffer). maxLines=0 > all kept.
  function getLogText(maxLines: Integer = 500): UnicodeString;
  /// JSON array of {id,ts,addr,ip,msg,cont,color}. afterId>0 > only newer entries.
  function getLogJSON(maxLines: Integer = 500; afterId: Integer = 0): RawByteString;
  procedure clearLogBuffer();
  function getLogCount: Integer;

var
//  fAddLogFunc: TAdd2LogEvent;
  fOnAdd2Log: TAdd2LogEvent;
  LogPrefs: TLogPrefs;
  /// Max entries kept in the in-memory ring buffer (default 2000).
  LogBufferMax: Integer;

implementation
uses
  DateUtils,
 {$IFDEF SHOW_GEO_BY_IP}
  GeoIP,
 {$ENDIF SHOW_GEO_BY_IP}
  hsUtils,
  srvUtils, RDUtils, srvVars;

var
  FLogArr: TLogDatas;
  FLogLock: TCriticalSection;
  FLogSeq: Integer;

resourcestring
  MSG_LOG_SERVER_START = 'Server start';
  MSG_LOG_SERVER_STOP = 'Server stop';
  MSG_LOG_CONNECTED = 'Connected';
  MSG_LOG_DISC_SRV = 'Disconnected by server';
  MSG_LOG_DISC = 'Disconnected';
  MSG_LOG_GOT = 'Got %d bytes';
  MSG_LOG_BYTES_SENT = '%s bytes sent';
  MSG_LOG_SERVED = 'Served %s';
  MSG_LOG_HEAD = 'Served head';
  MSG_LOG_NOT_MOD = 'Not modified, use cache';
  MSG_LOG_REDIR = 'Redirected to %s';
  MSG_LOG_NOT_SERVED = 'Not served: %d - %s';
  MSG_LOG_UPL = 'Uploading %s';
  MSG_LOG_UPLOADED = 'Fully uploaded %s - %s @ %sB/s';
  MSG_LOG_UPL_FAIL = 'Upload failed %s';
  MSG_LOG_DL = 'Fully downloaded - %s @ %sB/s - %s';

 {$IFDEF FPC}
  function GetLocaleStr(LID, LT: Longint; const Def: string): AnsiString;
  var
    L: Integer;
    Buf: unicodestring;
  begin
    L := GetLocaleInfoW(LID, LT, nil, 0);
    if L > 0 then
      begin
        SetLength(Buf,L-1); // L includes terminating NULL
        if l>1 Then
          L := GetLocaleInfoW(LID, LT, @Buf[1], L);
        result:=buf;
      end
    else
      Result := Def;
  end;
 {$ENDIF FPC}


procedure applyISOdateFormat();
begin
  if useISOdate in LogPrefs then
    FormatSettings.ShortDateFormat := 'yyyy-mm-dd'
   else
     FormatSettings.ShortDateFormat := GetLocaleStr(LOCALE_USER_DEFAULT, LOCALE_SSHORTDATE,'');
end;

procedure add2logFile(const data: TLogData);
var
  s, lines: UnicodeString;
  ts, first, rest, addr: string;
begin
  if ((logFile.filename = '') or (logFile.apacheFormat > '')) then
    exit;

  if LogDate in LogPrefs then
    begin
     applyISOdateFormat(); // this call shouldn't be necessary here, but it's a workaround to this bug www.rejetto.com/forum/?topic=5739
     if logTime in LogPrefs then
       ts := datetimeToStr(data.time)
      else
       ts := dateToStr(data.time)
    end
   else
    if logTime in LogPrefs then
      ts := timeToStr(data.time)
     else
      ts := '';
  lines := data.lines;
  first := chopLine(lines);
  if lines = '' then
    rest := ''
   else
    rest := reReplace(lines, '^', '> ')+CRLF;
 addr := data.addr;
 {$IFDEF SHOW_GEO_BY_IP}
  if data.countryNum > 0 then
    addr := addr + ' from {' + CountryCodes[data.countryNum] + '}';
 {$ENDIF SHOW_GEO_BY_IP}


  if (logFile.filename > '') and (logFile.apacheFormat = '') then
   begin
    s := ts + data.fileStr +TAB+ first;

    if tabOnLogFile in LogPrefs then
      s := s+stripChars(reReplace(lines, '^', TAB),[#13,#10])
     else
      s := s+CRLF+rest;

    includeTrailingString(s, CRLF);
    appendFileU(data.fileDynName, s);
   end;
end;

procedure add2logData(var ld: TLogData; const lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault);
var
  addr: String;
begin
  ld.id := 0; // filled later in add2logArr under lock
  ld.lines := lines;
  ld.time := now;
 {$IFDEF SHOW_GEO_BY_IP}
  ld.countryNum := 0;
 {$ENDIF SHOW_GEO_BY_IP}

  if assigned(cd) then
    begin
      ld.address := cd.address;
      if assigned(cd.conn) then
        addr := nonEmptyConcat('', cd.usr, '@')
          +ifThen(cd.conn.v6, '['+cd.address+']', cd.address)
          +':'+cd.conn.port
          +nonEmptyConcat(' {', localDNSget(cd.address), '}')
       else
        addr := nonEmptyConcat('', cd.usr, '@')
          + cd.address
          + nonEmptyConcat(' {', localDNSget(cd.address), '}');
      ld.addr := addr;
    end
   else
    addr := '';

  if (cd = NIL) or (cd.conn = nil) then
    ld.fileStr := TAB+''+TAB+''+TAB+''+TAB+''
   else
    ld.fileStr := TAB+cd.usr+TAB+cd.address+TAB+cd.conn.port+TAB+localDNSget(cd.address);
  ld.fileDynName := getDynLogFilename(cd);
end;

procedure trimLogBufferLocked;
var
  excess, i: Integer;
begin
  if (LogBufferMax <= 0) or (Length(FLogArr) <= LogBufferMax) then
    Exit;
  excess := Length(FLogArr) - LogBufferMax;
  for i := 0 to High(FLogArr) - excess do
    FLogArr[i] := FLogArr[i + excess];
  SetLength(FLogArr, LogBufferMax);
end;

procedure add2logArr(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault); OverLoad;
begin
  FLogLock.Acquire;
  try
    SetLength(FLogArr, Length(FLogArr) + 1);
    add2logData(FLogArr[ High(FLogArr)], lines, cd, clr);
    // Always assign a fresh monotonic id (never trust uninitialized stack garbage)
    Inc(FLogSeq);
    if FLogSeq <= 0 then
      FLogSeq := 1;
    FLogArr[ High(FLogArr)].id := FLogSeq;
    trimLogBufferLocked;
   finally
    FLogLock.Release;
  end;
end;

procedure add2logArr(ld: TLogData); OverLoad;
begin
  FLogLock.Acquire;
  try
    // Always overwrite id — callers often pass an uninitialized TLogData
    // whose id field holds stack garbage (e.g. 103049296 or repeated 1).
    Inc(FLogSeq);
    if FLogSeq <= 0 then
      FLogSeq := 1;
    ld.id := FLogSeq;
    SetLength(FLogArr, Length(FLogArr) + 1);
    FLogArr[ High(FLogArr)] := ld;
    trimLogBufferLocked;
   finally
    FLogLock.Release;
  end;
end;

function getLogText(maxLines: Integer = 500): UnicodeString;
var
  i, fromIdx: Integer;
  ts: string;
begin
  Result := '';
  if not Assigned(FLogLock) then
    Exit;
  FLogLock.Acquire;
  try
    fromIdx := 0;
    if (maxLines > 0) and (Length(FLogArr) > maxLines) then
      fromIdx := Length(FLogArr) - maxLines;
    for i := fromIdx to High(FLogArr) do
      begin
        applyISOdateFormat();
        if logTime in LogPrefs then
          ts := DateTimeToStr(FLogArr[i].time)
        else
          ts := DateToStr(FLogArr[i].time);
        if FLogArr[i].addr <> '' then
          Result := Result + ts + '  [' + FLogArr[i].addr + ']  ' + FLogArr[i].lines + #13#10
        else
          Result := Result + ts + '  ' + FLogArr[i].lines + #13#10;
      end;
   finally
    FLogLock.Release;
  end;
end;

function jsonEsc(const u: UnicodeString): UnicodeString;
var
  i: Integer;
  ch: Char;
begin
  // Minimal JSON string escape for log fields
  Result := '';
  for i := 1 to Length(u) do
    begin
      ch := u[i];
      case ch of
        '\': Result := Result + '\\';
        '"': Result := Result + '\"';
        #8:  Result := Result + '\b';
        #9:  Result := Result + '\t';
        #10: Result := Result + '\n';
        #12: Result := Result + '\f';
        #13: Result := Result + '\r';
      else
        if Ord(ch) < 32 then
          Result := Result + '\u' + IntToHex(Ord(ch), 4)
        else
          Result := Result + ch;
      end;
    end;
end;

function getLogJSON(maxLines: Integer = 500; afterId: Integer = 0): RawByteString;
var
  i, fromIdx: Integer;
  s, lines, first, rest, ts, colorStr: UnicodeString;
  clr: TColor;
  firstOut: Boolean;
begin
  // Shape matches Sciter log.html addLogEvent + id for incremental clients
  s := '[';
  firstOut := True;
  if Assigned(FLogLock) then
    begin
      FLogLock.Acquire;
      try
        fromIdx := 0;
        if (maxLines > 0) and (Length(FLogArr) > maxLines) then
          fromIdx := Length(FLogArr) - maxLines;
        for i := fromIdx to High(FLogArr) do
          begin
            if FLogArr[i].id <= afterId then
              Continue;
            applyISOdateFormat();
            if logTime in LogPrefs then
              ts := DateTimeToStr(FLogArr[i].time)
            else if logDate in LogPrefs then
              ts := DateToStr(FLogArr[i].time)
            else
              ts := TimeToStr(FLogArr[i].time);
            lines := FLogArr[i].lines;
            first := chopLine(lines);
            if lines = '' then
              rest := ''
            else
              rest := reReplace(lines, '^', '> ') + #13#10;
            clr := FLogArr[i].clr;
            if (clr = Graphics.clDefault) or (clr = clWindowText) then
              colorStr := ''
            else
              colorStr := Format('#%6.6x', [ColorToRGB(clr) and $FFFFFF]);
            if not firstOut then
              s := s + ',';
            firstOut := False;
            s := s + '{"id":' + IntToStr(FLogArr[i].id) + ','
              + '"ts":"' + jsonEsc(ts) + '",'
              + '"addr":"' + jsonEsc(FLogArr[i].addr) + '",'
              + '"ip":"' + jsonEsc(FLogArr[i].address) + '",'
              + '"msg":"' + jsonEsc(first) + '",'
              + '"cont":"' + jsonEsc(rest) + '",'
              + '"color":"' + jsonEsc(colorStr) + '"}';
          end;
       finally
        FLogLock.Release;
      end;
    end;
  s := s + ']';
  Result := UTF8Encode(s);
end;

procedure clearLogBuffer();
begin
  if not Assigned(FLogLock) then
    Exit;
  FLogLock.Acquire;
  try
    SetLength(FLogArr, 0);
    // keep FLogSeq so clients detect a gap / clear
   finally
    FLogLock.Release;
  end;
end;

function getLogCount: Integer;
begin
  Result := 0;
  if not Assigned(FLogLock) then
    Exit;
  FLogLock.Acquire;
  try
    Result := Length(FLogArr);
   finally
    FLogLock.Release;
  end;
end;

procedure add2Log(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault; doSync: Boolean = True);
var
  ld: TLogData;
begin
  add2logData(ld, lines, cd, clr);
//  if not doSync then
//    add2log(lines, cd, clr)
//   else
//    add2logArr(lines, cd, clr);
  if Assigned(FLogLock) then
    add2logArr(ld);
  if Assigned(fOnAdd2Log) then
    fOnAdd2Log(ld, doSync);
end;

function getDynLogFilename(cd: TconnDataMain): String;// overload;
var
  d, m, y, w: word;
  u: string;
begin
  decodeDateFully(now(), y,m,d,w);
  if cd = NIL then
    u := ''
   else
    u := nonEmptyConcat('(', cd.usr, ')');
  result := xtpl(logFile.filename, [
    '%d%', int0(d,2),
    '%m%', int0(m,2),
    '%y%', int0(y,4),
    '%dow%', int0(w-1,2),
    '%w%', int0(weekOf(now()),2),
    '%user%', u
  ]);
end; // getDynLogFilename

procedure doServerLog(conn: ThttpConn; data: TconnData; event: ThttpEvent);
var
  i: integer;
  s, s1: string;
   function decodedUrl(): String;
    begin
    if conn = NIL then
      exit('');
    result := decodeURL(conn.httpRequest.url);
   end;
begin
  if assigned(data) and data.dontLog and (event <> HE_DISCONNECTED) then
    exit; // we exit expect for HE_DISCONNECTED because dontLog is always set AFTER connections, so HE_CONNECTED is always logged. The coupled HE_DISCONNECTED should be then logged too.

  if assigned(data) and (data.preReply = PR_BAN)
  and not (logBanned in LogPrefs) then
    exit;

  if not (event in [HE_OPEN, HE_CLOSE, HE_CONNECTED, HE_DISCONNECTED, HE_GOT, HE_DESTROID]) then
    if not ((logIcons in LogPrefs) and Assigned(data) and (data.downloadingWhat = DW_ICON))
    and not ((logBrowsing in LogPrefs) and Assigned(data) and (data.downloadingWhat = DW_FOLDERPAGE))
    and not ((logProgress in LogPrefs) and (decodedUrl() = '/~progress')) then
      exit;

  if Assigned(data) and not (event in [HE_OPEN, HE_CLOSE, HE_DESTROID])
  and addressMatch(dontLogAddressMask, data.address) then
    exit;

  case event of
    HE_OPEN: if (logServerstart in LogPrefs) then
               add2log(MSG_LOG_SERVER_START);
    HE_CLOSE: if (logServerStop in LogPrefs) then
                add2log(MSG_LOG_SERVER_STOP);
    HE_CONNECTED: if (logconnections in LogPrefs) then
                    add2log(MSG_LOG_CONNECTED, data);
    HE_DISCONNECTED: if (logDisconnections in LogPrefs) then
        begin
          if Assigned(data) then
            s1 := nonEmptyConcat(': ', data.disconnectReason)
           else
            s1 := '';
          add2log(if_(conn.disconnectedByServer, MSG_LOG_DISC_SRV,MSG_LOG_DISC)
            + s1
            + if_(conn.bytesSent>0, ' - '+format(MSG_LOG_BYTES_SENT, [dotted(conn.bytesSent)])),
          data);
        end;
    HE_GOT:
      begin
      i := conn.bytesGot-data.lastBytesGot;
      if i <= 0 then
        exit;
      if (logBytesReceived in LogPrefs) and ((logAPI in LogPrefs)or not Assigned(data) or not data.isAPIReq) then
        if now()-data.bytesGotGrouping.since <= BYTES_GROUPING_THRESHOLD then
          inc(data.bytesGotGrouping.bytes, i)
        else
          begin
          add2log(format(MSG_LOG_GOT,[i+data.bytesGotGrouping.bytes]), data);
          data.bytesGotGrouping.since := now();
          data.bytesGotGrouping.bytes := 0;
          end;
      inc(data.lastBytesGot, i);
      end;
    HE_SENT:
      begin
        i:=conn.bytesSent-data.lastBytesSent;
        if i <= 0 then
          exit;
        if (logBytesSent in LogPrefs)and ((logAPI in LogPrefs)or not Assigned(data) or not data.isAPIReq) then
          if now()-data.bytesSentGrouping.since <= BYTES_GROUPING_THRESHOLD then
            inc(data.bytesSentGrouping.bytes, i)
           else
            begin
              add2log(format(MSG_LOG_BYTES_SENT,[dotted(i+data.bytesSentGrouping.bytes)]), data);
              data.bytesSentGrouping.since:=now();
              data.bytesSentGrouping.bytes:=0;
            end;
        inc(data.lastBytesSent, i);
      end;
    HE_REQUESTED:
      if (not (logOnlyServed in LogPrefs)
      or (conn.reply.mode in [HRM_REPLY, HRM_REPLY_HEADER, HRM_REDIRECT]))
      and ((logAPI in LogPrefs)or not Assigned(data) or not data.isAPIReq)
      then
        begin
        data.logLaterInApache := TRUE;
        if logRequests in LogPrefs then
          begin
          s := subStr(conn.getHeader('Range'), 7);
          if s > '' then
            s:=TAB+'['+s+']';
          add2log(format('Requested %s %s%s', [ METHOD2STR[conn.httpRequest.method], decodedUrl(), s ]), data);
          end;
        if dumpRequests in LogPrefs then
          add2log(RawByteString('Request dump')+CRLF+conn.httpRequest.full, data);
        end;
    HE_REPLIED:
      if (logReplies in LogPrefs) and  ((logAPI in LogPrefs)or not Assigned(data) or not data.isAPIReq) then
       case conn.reply.mode of
          HRM_REPLY: if not data.fullDLlogged then
                       add2log(format(MSG_LOG_SERVED, [smartSize(conn.bytesSentLastItem)]) + ' ' + conn.reply.comprType, data);
          HRM_REPLY_HEADER: add2log(MSG_LOG_HEAD, data);
          HRM_NOT_MODIFIED: add2log(MSG_LOG_NOT_MOD, data);
          HRM_REDIRECT: add2log(format(MSG_LOG_REDIR, [conn.reply.url]), data);
          else if not (logOnlyServed in LogPrefs) then
            add2log(format(MSG_LOG_NOT_SERVED, [HRM2CODE[conn.reply.mode], HRM2STR[conn.reply.mode] ])
              +nonEmptyConcat(': ', data.error), data);
          end;
    HE_POST_FILE:
      if (logUploads in LogPrefs) and (data.uploadFailed = '') then
        add2log(format(MSG_LOG_UPL, [data.uploadSrc]), data);
    HE_POST_END_FILE:
      if (logUploads in LogPrefs) then
        if data.uploadFailed = '' then
          add2log(format(MSG_LOG_UPLOADED, [
            data.uploadSrc,
            smartSize(conn.bytesPostedLastItem),
            smartSize(data.calcAverageSpeed(conn.bytesPostedLastItem)) ]), data)
        else
          add2log(format(MSG_LOG_UPL_FAIL, [data.uploadSrc]), data);
    HE_LAST_BYTE_DONE:
      if (logFullDownloads in LogPrefs)
      and data.countAsDownload
      and (data.downloadingWhat in [DW_FILE, DW_ARCHIVE]) then
        begin
        data.fullDLlogged := TRUE;
        add2log(format(MSG_LOG_DL, [
          smartSize(conn.bytesSentLastItem),
          smartSize(data.calcAverageSpeed(conn.bytesSentLastItem)),
          decodedUrl()]), data);
        end;
    end;

  { apache format log is only related to http events, that's why it resides
  { inside httpEvent(). moreover, it needs to access to some variables. }
  if (logFile.filename = '') or (logFile.apacheFormat = '')
  or (data = NIL) or not data.logLaterInApache
  or not (event in [HE_LAST_BYTE_DONE, HE_DISCONNECTED]) then exit;

  data.logLaterInApache := FALSE;
  s:=xtpl(logfile.apacheFormat, [
    '\t', TAB,
    '\r', #13,
    '\n', #10,
    '\"', '"',
    '\\', '\'
  ]);
  s := reCB('%(!?[0-9,]+)?(\{([^}]+)\})?>?([a-z])', s, apacheLogCb, data);
  appendFileU(getDynLogFilename(data), s+CRLF);
end; // doLog

initialization
  FLogLock := TCriticalSection.Create;
  LogBufferMax := 2000;
  FLogSeq := 0;

finalization
  FLogLock.Free;
  FLogLock := NIL;

end.
