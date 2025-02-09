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
unit scriptLib;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}
   {~$DEFINE HFS_SERVICE}

interface

uses
  iniFiles, types,
  srvConst, srvClassesLib, fileLib, serverLib;

var
  defaultAlias: THashedStringList;
  staticVars: THashedStringList; // these scripting variables are held for the whole run-time

function tryApplyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; var md: TmacroData; removeQuotings: Boolean=true): Boolean;
function runScript(fs: TFileServer; const script: UnicodeString; table: TUnicodeStringDynArray=NIL; tpl_:Ttpl=NIL; f:Tfile=NIL; folder:Tfile=NIL; cd:TconnDataMain=NIL): UnicodeString;
function runEventScript(fs: TFileServer; const event: String; table: TUnicodeStringDynArray=NIL; cd: TconnDataMain=NIL): String;
procedure resetLog();
procedure runTimedEvents(fs: TFileServer);
procedure runTplImport(fs: TFileServer);

implementation

uses
  Windows, classes,
 {$IFDEF FMX}
  System.UITypes, FMX.Types,
  FMX.Graphics, FMX.Controls, FMX.Forms,
  FMX.Platform, FMX.Clipboard,
 {$ELSE ~FMX}
  graphics,
  controls, forms, clipbrd, MMsystem, contnrs,
 {$IFDEF USE_VTV}
  VirtualTrees.Types, VirtualTrees.DrawTree,
 {$ELSE ~USE_VTV}
  ComCtrls,
 {$ENDIF ~USE_VTV}
 {$ENDIF ~FMX}
  sysutils, math, StrUtils,
  DateUtils,
  RDFileUtil, RDUtils, RnQCrypt,
  RegExpr,
  srvUtils, srvVars,
  netUtils,
   {$IFDEF HFS_SERVICE}
   {$ELSE ~HFS_SERVICE}
  RnQtrayLib,
  utilLib,
 {$IFDEF FMX}
  mainFMX,
 {$ELSE ~FMX}
  main,
 {$ENDIF ~FMX}
   {$ENDIF HFS_SERVICE}
  parserLib,
  HSLib, HSUtils,
  hfsVars, hfsGlobal;

const
  HEADER: RawByteString = RawByteString('<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><style>'
  +#13'dt, dd { margin:0; padding:0.2em 0.5em; white-space:pre; display:block; font-family:monospace; } dt { background:#dfd; } dd { background:#fdd; }'
  +#13'</style></head><body>');

var
  stopOnMacroRename: boolean; // this ugly global var is used to avoid endless recursion on a renaming rename event. this method won't work on a multithreaded system, but i opted for it because otherwise the changes would have been big.
  cachedTpls: TcachedTpls;
var
  timedEventsRE: TRegExpr;
  eventsLastRun: TstringToIntHash;

function macrosLog(const textIn, textOut: UnicodeString; ts: Boolean=FALSE): Boolean;
var
  s: UnicodeString;
begin
  s:='';
  if ts then
      s:='<hr>'+dateTimeToStr(now())+CRLF;
  s := s+#13'<dt>'+htmlEncode(textIn)+'</dt><dd>'+htmlEncode(textOut)+'</dd>';
  if sizeOfFile(MACROS_LOG_FILE) = 0 then
    saveFileA(MACROS_LOG_FILE, header, True);
  //result := appendFile(MACROS_LOG_FILE, UTF8Encode(s))
  result := saveFileU(MACROS_LOG_FILE, s, True);
end; // macrosLog

procedure resetLog();
begin saveFileA(MACROS_LOG_FILE, '') end;

function expandLinkedAccounts(account:Paccount):TStringDynArray;
var
  i: integer;
begin
  result:=NIL;
  if account = NIL then
    exit;
  i:=0;
  result:=account.link;
  while i < length(result) do
  begin
    account:=getAccount(result[i], TRUE);
    inc(i);
    if (account = NIL) or not account.enabled then
      continue;
    addUniqueArray(result, account.link);
  end;
end; // expandLinkedAccounts

function encodeMarkers(s: UnicodeString): UnicodeString;
var
  i: integer;
  t: UnicodeString;
begin
  for i:=0 to length(MARKERS)-1 do
   begin
    t := MARKERS[i];
    replace(t, '&#'+intToStr(charToUnicode(t[1]))+';', 1,1);
    s := xtpl(s, [MARKERS[i], t]);
   end;
  result:=s;
end; // encodeMarkers

function noMacrosAllowed(s: UnicodeString): UnicodeString;
// prevent hack attempts
var
  i: integer;
begin
  if s = '' then
    Exit('');
  i:=1;
  enforceNUL(s);
  repeat
    i:=findMacroMarker(s, i);
    if i = 0 then
      break;
    replace(s, '&#'+intToStr(charToUnicode(s[i]))+';', i,i);
  until false;
//  s := reReplace(s,'%([-a-z0-9]+%)','&#37;$1', 'mi');
//  result := s;
  Result := ReplaceStr(s, '%','&#37;');
end; // noMacrosAllowed

function cbMacros(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars; cbData: PMacroData): UnicodeString;
var
  md: ^TmacroData;
  name, p: string;
  pU: UnicodeString;
  unnamedPars: integer; // this is a guessing of the number of unnamed parameters. just guessing because there's no true distinction between a parameter "value" named "key", and parameter "key=value"
  lp: TLoadPrefs;
  sp: TShowPrefs;

  procedure macroError(const msg: String);
  begin result := '<div class=macroerror>macro error: '+name+nonEmptyConcat('<br>',msg)+'</div>' end;

  procedure deprecatedMacro(const what: String=''; const instead: String='');
  begin
    add2log('WARNING, deprecated macro: '+first(what, name)+nonEmptyConcat(' - Use instead: ',instead), NIL, clRed)
  end;

  procedure unsatisfied(b: Boolean=TRUE);
  begin
  if b then
    macroError('cannot be used here')
  end;

  function satisfied(p:pointer):boolean;
  begin
  result:=assigned(p);
  unsatisfied(not result);
  end;

  function par(idx: integer; const name: String=''; doTrim: Boolean=TRUE): UnicodeString; overload;
  begin
    if ((idx < 0) or (idx >= pars.count)) and (name = '') then
      Exit('');
    try
      result := pars.parExNE(idx, name, doTrim)
     except
      result := ''
    end
  end;

  function par(const name: String=''; doTrim: Boolean=TRUE; const defval: String=''): String; overload;
  begin
    result := defval;

    if name > '' then
      begin
        if pars.TryGetValue(name, Result) then
          if doTrim then
            Exit(trim(result))
           else
            exit;
      end;
  end;

  function parI(idx: Integer): Int64; overload;
  begin result:=strToInt64(par(idx)) end;

  function parI(idx:integer; def:int64):int64; overload;
  begin result:=strToInt64Def(par(idx), def) end;

  function parI(const name:string; def:int64):int64; overload;
  begin result:=strToInt64Def(par(name), def) end;

  function parF(idx:integer):extended; overload;
  begin result:=strToFloat(par(idx)) end;

  function parF(idx:integer; def:extended):extended; overload;
  begin result:=strToFloatDef(par(idx), def) end;

  function parF(const name:string; def:extended):extended; overload;
  begin result:=strToFloatDef(par(name), def) end;


  procedure trueIf(condition:boolean);
  begin if condition then result:='1' else result:='' end;

  // this is for cases where normally we want a "clean" output. User can still detect outcome by using macro "length".
  // Reason for having this instead of using in place a simple "result:=if_(cond, ' ')" is to evidence our purpose. It's not faster or cleaner, it's more semantic.
  procedure spaceIf(condition:boolean);
  begin if condition then result:=' ' else result:='' end;

  function isFalse(const s: String):boolean;
  begin result:=(s='') or (strToFloatDef(s,1) = 0) end;

  function isTrue(const s: String): boolean; inline;
  begin result:=not isFalse(s) end;

  function getVarSpace(var varname: String): THashedStringList;
  begin
  varname:=trim(varname);
  if ansiStartsStr(G_VAR_PREFIX, varname) then
    begin
    result:=staticVars;
    delete(varname,1,length(G_VAR_PREFIX));
    end
  else if assigned(md.cd) then
    result:=md.cd.vars
  else if assigned(md.tempVars) then
    result:=md.tempVars
  else
    raise Exception.create('no namespace available');
  end; // getVarSpace

  function getVar(varname:string):string; overload;
  begin result:=getVarSpace(varname).values[varname] end;

  // if par with name exists, then it's a var name, otherwise it's a constant value at specified index
  function parVar(const parname: String; idx: Integer): String; overload;
  begin
    if pars.parExist(parname) then
      result:=getVar(par(parname))
     else
      result:=pars[idx];
  end; // parVar

  function setVar(varname: String; const value: String; space: THashedStringList=NIL): Boolean;
  var
    o: Tobject;
    i: integer;
  begin
  result:=FALSE;
  if space = NIL then
    space:=getVarSpace(varname);
  if not satisfied(space) then exit;
  i:=space.indexOfName(varname);
  if i < 0 then
    if value = '' then exit(TRUE) // all is good the way it is
    else i:=space.add(varname+'='+value)
  else
    if value > '' then // in case of empty value, there's no need to assign, because we are going to delete it (after we cleared the bound object)
      space.valueFromIndex[i]:=value;

  assert(i >= 0, 'setVar: i<0');
  // the previous hash object linked to this data is not valid anymore, and must be freed
  o:=space.objects[i];
  freeAndNIL(o);

  if value = '' then
    space.delete(i)
  else
    space.objects[i]:=NIL;
  result:=TRUE;
  end; // setVar

  // we wrap pos() to switch between case sensitivity
  function pos_(caseSensitive:boolean; const ss, s:string; ofs:integer=1):integer;
  begin
    if caseSensitive then
      result:=posEx(ss,s,ofs)
     else
      result:= ipos(ss,s, ofs)
  end; // pos_

  procedure allLogic(isAnd:boolean); // when not "isAnd", then it isOr ;-)
  var
    i: integer;
  begin
  // AND will return first FALSE value, or having none, the last TRUE value.
  // OR will return last TRUE value, or having none, last value. 
  result:='';
  for i:=0 to pars.count-1 do
    begin
    result:=par(i);
    if isAnd xor isTrue(result) then exit;
    end;
  end; // allLogic

  procedure substring();
  var
    i, j: integer;
    s: UnicodeString;
    what2inc: integer;
    caseSens: boolean;
    p0, p1: UnicodeString;
  begin
    result:='';

    // input what to be included in the result
    s := par('include');
    try
      what2inc:=strToInt(s)
     except // we also support the following values
      if s = 'none' then
        what2inc:=0
      else if s = 'both' then
        what2inc:=3
      else if s = '1+2' then
        what2inc:=3
      else what2inc:=1; // by default we include only the first delimiter
    end;

    caseSens:=isTrue(par('case'));

    // find the delimiters
    s:=macroDequote(par(2));
    p0 := pars[0];
    if p0 = '' then
      i:=1
     else
      i := pos_(caseSens, p0, s); // we don' trim this, so you can use blank-space as delimiter
    if i = 0 then
      exit;
    p1 := pars[1];
    j:=pos_(caseSens, p1, s, i+1);
    if j = 0 then
      j:=length(s)+1;

    // apply what2inc
    if what2inc and 1 = 0 then
      inc(i, length(p0));
    if what2inc and 2 > 0 then
      inc(j, length(p1));

    // end of the story
    result := macroQuote(copy(s, i, j-i));
  end; // substring

  procedure switch();
  var
    what, sep: UnicodeString;
    i, j: integer;
    a: TUnicodeStringDynArray;
  begin
    what := par(0);
    sep := first(pars[1], ' '); // we don' trim this, so you can use blank-space as separator
    i:=2;
    while i < pars.count do
      begin
      if i = pars.count-1 then
        begin
        result := macroDequote(par(i));
        exit;
        end;
      a := unicodeSplit(sep, par(i));
      for j:=0 to length(a)-1 do
        if sameText(a[j], what) then
          begin
          result:=macroDequote(par(i+1));
          exit;
          end;
      inc(i, 2);
      end;
    result:='';
  end; // switch

  procedure cut();
  var
    from, upTo, l: integer;
    s, v: UnicodeString;
    t: String;
  begin
    v := par('var');
    if v = '' then
      s:=par(2,'what')
    else
      s:=getVar(v);
    l:=length(s);

    from:=strToIntDef(par(0,'from'), 1);
    if from < 0 then from:=l+from+1;

    if not pars.tryParToInt('to', upTo) then
     begin
      upTo:=strToIntDef(par(1,'size'), 0);
      if upTo = 0 then
        upTo:=l
      else if upTo > 0 then
        upTo:=from+upTo-1
      else
        upTo:=l+upTo;
     end;
    
    result:=substr(s, from, upTo);
    if pars.parExistVal('remainder', t) then
     try
       setVar(t, substr(s,1,from-1)+substr(s,upTo+1));
      except
     end;
    if v = '' then
      exit;
    setVar(v, result);
    result:='';
  end; // cut

  procedure minOrMax();
  var
    i: integer;
    r, v: real;
    min: boolean;
  begin
  min:=name='min';
  r:=parF(0);
  for i:=1 to pars.Count-1 do
    begin
    v:=parF(i);
    if (v < r) and min
    or (v > r) and not min then
      r:=v;
    end;
  result:=floatToStr(r);
  end; // minOrMax

  procedure getUri();
  var
    i, ex, eq: integer;
    vars: Tstrings;
    s: string;
  begin
  if not satisfied(md.cd) then
    exit;
  try
    result := md.cd.conn.httpRequest.url;
    if pars.count < 2 then exit;
    s:=result;
    result:=chop('?', s);
    vars:=TstringList.create();
    try
      vars.delimiter:='&';
      vars.quoteChar:=#0;
      vars.delimitedText:=s;
      if pars.count > 1 then
        for i:=1 to pars.count-1 do
          begin
          s:=par(i);
          if s = '' then continue;
          eq:=pos('=', s);
          if eq = 0 then
            begin
            if vars.indexOf(s) < 0 then
              vars.add(pars[i]);
            continue;
            end;
          ex:=vars.indexOfName(chop(eq,s));
          if ex < 0 then
            if s = '' then
              continue   // the parameter didn't exist, and we are trying to empty it
            else
              vars.add(par(i))  // didn't exist, put the whole
          else
            if s = '' then
              vars.delete(ex) //  exists, but we are trying to empty it
            else
              vars.valueFromIndex[ex]:=s; // exists, change the value
          end;
      if vars.count = 0 then exit;
      for i:=vars.Count-1 downto 0 do
        if vars[i] = '' then
          vars.delete(i);
      result:=result+'?'+vars.delimitedText;
    finally vars.free end;
  finally result:=macroQuote(result) end;
  end; // getUri

  procedure section(ofs:integer);
  var
    t: Ttpl;
    s: string;
  begin
  if not satisfied(md.tpl) then exit;
  s:=par(ofs);
  if (par('file') = '') and ((s = '') or (pos('=',s) > 0)) then
    begin // current template
    result:='';
    t:=md.tpl;
    ofs:=parI('back', 0);
    while ofs > 0 do
      begin
      dec(ofs);
      t:=t.over;
      if t = NIL then exit;
      end;
    try result:=t[p] except end;
    exit;
    end;
  // template in other file

  t:=Ttpl.create;
  try
    t.fullText := loadFile(par(ofs, 'file'));
    result:=t[p];
  finally t.free end;
  // templates outside hfs folder get quoted for security reasons
  if anyCharIn('\/', par(ofs)) then
    result:=macroQuote(result);
  end; // section

  function urlVar(const k: String): String;
  var
    s, v: string;
  begin
    if not satisfied(md.cd) then
      exit;
    s:=md.cd.urlvars.values[k];
    if (s = '') and (md.cd.urlvars.indexOf(k) >= 0) then
      s:='1';
    try
      result := noMacrosAllowed(s);
      if pars.parExistVal('var', v) then
       begin
         setVar(v, result); // if no var is specified, it will break here, and result will have the value
         result:='';
       end;
     except
    end;
  end; // urlVar

  function maybeUrlvar(const k: String): String;
  begin
    if (k = '') or (k[1] <> '?') then
      result := k
     else
      result := urlvar(copy(k,2,MAXINT));
  end; // maybeUrlvar

  function compare(op,p1,p2:string):boolean;
  var
    r1,r2: double;
    c: integer;
  begin
    if TryStrToFloat(p1, r1) and TryStrToFloat(p2, r2) then
      c := compare_(r1,r2)
     else
      c := ansiCompareText(p1,p2);
    if op = '=' then result:= c=0
    else if op = '>' then result:= c>0
    else if op = '<' then result:= c<0
    else if op = '>=' then result:= c>=0
    else if op = '<=' then result:= c<=0
    else if (op = '<>') or (op = '!=') then result:= c<>0
    else result:=FALSE;
  end; // compare

  procedure infixOperators(ops: array of String);
  var
    i, j: integer;
    s: string;
  begin
  if pars.count > 0 then exit;
  for i:=0 to length(ops)-1 do
    begin
    j:=pos(ops[i], name);
    if j = 0 then continue;
    s:=trim(chop(j, length(ops[i]), name));
    trueIf(compare(ops[i], maybeUrlvar(s), maybeUrlvar(trim(name))));
    exit;
    end;
  end; // infixOperators

  procedure call(const code: UnicodeString; ofs: Integer=0);
  var
    i: integer;
  begin
    result := code;
    if pars.count=0 then
      exit;
    // the inverted order is to avoid problems with $10 being replaced as it was '$1'.'0'
    for i:=pars.count+5 downto pars.count do
      result := xtpl(result, [UnicodeString(format(UnicodeString('$%d'),[i-ofs+1])), '']);
    for i:=pars.Count-1 downto ofs do
      result := xtpl(result, [UnicodeString(format('$%d',[i-ofs+1])), pars[i]]);
  end; // call

  procedure breadcrumbs();
  var
    e, d: string;
    ae, ad: TstringDynArray;
    i: integer;
    fld: Tfile;
    freeIt: boolean;
  begin
    freeIt:=FALSE;
    if md.f = NIL then
      fld:=md.folder
     else
      begin
        fld:=md.f.parent;
        if md.f.isTemp() then
          begin
            e:=extractFilePath(md.f.resource);
            if length(e) > 3 then
              e:=excludeTrailingPathDelimiter(e);
            if e <> fld.resource then
            begin
              fld := Tfile.createTemp(fs, e, md.f);
              freeIt:=TRUE;
            end
          end;
      end;

    if not satisfied(fld) then
      exit;
    e := htmlEncode(encodeMarkers(fs.url(fld, false)));
    d := htmlEncode(encodeMarkers(fld.getFolder()+fld.name+'/'));
    ae := split('/', e);
    ad := split('/', d);
    p:=macroDequote(p);
    result:='';
    e:='';
    i:=length(ae)-1;
    if ae[i] = '' then
      dec(i);
    for i:=parI('from',0) to i do
      begin
      e:=e+ae[i]+'/';
      result:=result+xtpl(p, [
        '%bread-url%', e,
        '%bread-name%', ad[i],
        '%bread-idx%', intToStr(i)
      ]);
      end;

    if freeIt then
      freeAndNIL(fld);
  end; // breadcrumbs

  procedure inc_(v:integer=+1);
  begin
  try
    setVar(p, intToStr(strToIntDef(getVar(p),0)+v*parI(1,1)));
    result:='';
  except
    end;
  end; // inc_

  procedure convert();
  var
    dst, s: string;
    c: ansichar;
  begin
    dst:=par(1);
    s:=par(2);
    if sameText(p, 'ansi') and sameText(dst, 'utf-8') then
      result:=string(ansiToUTF8(ansistring(s)))
     else if sameText(p, 'utf-8') then
      if sameText(dst, 'ansi') then
        result:=utf8ToAnsi(ansistring(s))
       else if dst='dec' then
        begin
         result:='';
         for c in UTF8encode(s) do
           result:=result+intToStr(ord(c))+',';
         setLength(result, length(result)-1);
        end
       else if dst='hex' then
        begin
         result:='';
         for c in UTF8encode(s) do
          result := result+intToHex(ord(c));
        end;
    if isFalse(par('macros')) then
      result := noMacrosAllowed(result);
  end; // convert

  procedure encodeuri();
  var
    i: integer;
    cs: TcharsetW;
  begin
    result:='';
    try
      cs:=[#0..#255]-strToCharset(pars.parEx('only'));
     except
      cs := ['a'..'z','A'..'Z','0'..'9',',','/','#','&','?',':','$','@','=','+']
            -strToCharset(par('add'))+strToCharset(par('not'));
    end;
    for i:=1 to length(p) do
      if p[i] in cs then
        result:=result+p[i]
       else
        result:=result+'%'+intToHex(ord(p[i]),2)
  end; // encodeuri

  procedure addFolder();
  var
    parent: TFileNode;
    f, old: Tfile;
    fn, fldr_name: UnicodeString;

    // extract the path from "fldr_name", if any, and assign it to "parent"
    function validateAndExtractParent(): Boolean;
    var
      i: integer;
      parentF: Tfile;
    begin
      result:=TRUE;
      i := lastDelimiter('/', fldr_name);
      if i = 0 then exit;
      result:=FALSE;
      parentf := fs.findFilebyURL(chop(i+1, 0, fldr_name), NIL, FALSE);
      if parentf = NIL then exit;
      parent:=parentf.node; // ok, this is where we'll add the folder
      result:=TRUE;
    end; // validateAndExtractParent

  begin
    result := '';
    if not stringExists(p, ['real','virtual']) then
      exit;

    parent := NIL;
    if assigned(md.folder) then
      parent := md.folder.node;

    if p = 'virtual' then
      begin
        fldr_name := par(1);
        if not validateAndExtractParent() then
          exit;
        f := Tfile.createVirtualFolder(fs, fldr_name);
      end
    else
      begin
        fn := fs.uri2diskMaybe(par(1));
        if not isAbsolutePath(fn) and assigned(md.folder) then
          fn := expandFileName(md.folder.resource+'\'+fn);
        if not directoryExists(fn) then
          exit; // the real folder must exists on disk

        // is a fldr_name specified in the third parameter, or should we deduce it from the disk path?
        fldr_name := par(2);
        if (fldr_name = '') or containsStr(fldr_name,'=') then
          fldr_name := extractFileName(fn);

        if not validateAndExtractParent() then
          exit;
        f := Tfile.create(fs, fn);
        f.name := fldr_name;
      end;

    if not validFilename(f.name) then
      begin
      f.free;
      exit;
      end;

    old := fs.findFilebyURL(f.name, nodeToFile(parent), FALSE);
    if assigned(old) then
      if not old.isRoot()
      and (not pars.parExist('overwrite') or isTrue(par('overwrite'))) then
        try
          old.deleteNode;
         except
        end // delete existing one
      else
        begin
        f.free;
        exit;
        end;

   {$IFDEF HFS_SERVICE}
    if fs.addFileRecur(f, parent) = NIL then
   {$ELSE ~HFS_SERVICE}
    if mainfrm.addFile(f, parent, TRUE) = NIL then
   {$ENDIF HFS_SERVICE}
      f.free
    else
      spaceIf(TRUE)
  end; // addFolder

  procedure setItem();
  var
    f: Tfile;
    act: TfileAction;

    function get(const prefix: String): TStringDynArray;
    begin
    result := onlyExistentAccounts(split(';', pars.parEx(prefix+FILEACTION2STR[act])));
    uniqueStrings(result);
    end;

    function getb(const prefix: String; val: TStringDynArray): Boolean;
    var
      s: String;
    begin
      Result := pars.parExistVal(prefix+FILEACTION2STR[act], s);
      if Result then
       begin
         val := onlyExistentAccounts(split(';', s));
         uniqueStrings(val);
       end;
    end;

    procedure setAttr(a: TfileAttribute; const parName: String);
    var
      v: String;
    begin
      if pars.parExistVal(parname, v) then
        try
          if isTrue(v) then
            include(f.flags, a)
          else
            exclude(f.flags, a);
        except end;
    end; // setAttr
  var
    v: String;
    valSA: TStringDynArray;
  begin
    result := '';
    f := fs.findFileByURL(p, md.folder);
    if f = NIL then exit; // doesn't exist

    if pars.parExistVal('comment', v) then
     try
       f.setDynamicComment(LP, macroDequote(v))
     except end;
    if pars.parExistVal('name', v) then
      f.name := v;
    if pars.parExistVal('resource', v) then
      f.resource := v;
    if pars.parExistVal('diff template', v) then
      f.diffTpl := v;
    if pars.parExistVal('files filter', v) then
      f.filesFilter := v;
    if pars.parExistVal('folders filter', v) then
      f.foldersFilter := v;

    // following commands make no sense on temporary items
    if freeIfTemp(f) then exit;

    setAttr(FA_HIDDEN, 'hide');
    setAttr(FA_HIDDENTREE, 'hide tree');
    setAttr(FA_DONT_LOG, 'no log');
    setAttr(FA_ARCHIVABLE, 'archivable');
    setAttr(FA_BROWSABLE, 'browsable');
    setAttr(FA_DL_FORBIDDEN, 'download forbidden');
    if f.isFolder() then
      try f.dontCountAsDownloadMask := pars.parEx('not as download') except end
    else
      setAttr(FA_DONT_COUNT_AS_DL, 'not as download');

    for act:=low(act) to high(act) do
      begin
        valSA := NIL;
        if getB('', valSA) then
          f.accounts[act] := valSA;
        if getB('add ', valSA) then
          addUniqueArray(f.accounts[act], valSA);
        if getB('remove ', valSA) then
          removeArray(f.accounts[act], valSA);
      end;
    VFSmodified:=TRUE;
   {$IFNDEF HFS_SERVICE}
    mainfrm.filesBox.repaint();
   {$ENDIF ~HFS_SERVICE}
  end; // setItem

  function getItemIcon(f: Tfile): string;
  begin
    if f = NIL then
      result:=''
    else if (f.icon >= 0) or ((spUseSysIcons in SP) and f.isFile() and f.gotSystemIcon()) then
      result:='/~img'+intToStr(f.getSystemIcon())
    else if ((spUseSysIcons in SP) and f.isFile()) and (spNoWaitSysIcons in SP) then
      result := f.relativeURL() + '?mode=icon'
    else if (f.icon >= 0) or ((spUseSysIcons in SP) and f.isFile()) then
      result:='/~img'+intToStr(f.getSystemIcon())
    else if f.isFile() then
      result:='/~img_file'
    else if f.isFolder() then
      if FA_UNIT in f.flags then
        result:=format('/~img%d', [md.f.getIconForTreeview(spUseSysIcons in SP)])
      else
        result:='/~img_folder'
    else if f.isLink() then
      result:='/~img_link'
    else
      result:='';
  end; // getItemIcon

  procedure deleteItem();
  var
    f: Tfile;
  begin
    f:= fs.findFileByURL(p);
    spaceIf(assigned(f)); // so you can know if something really has been deleted
    if f = NIL then
      exit; // doesn't exist
   {$IFDEF HFS_SERVICE}
   fs.removeFile(f);
   {$ELSE ~HFS_SERVICE}
    mainFrm.remove(f);
   {$ENDIF HFS_SERVICE}
    VFSmodified := TRUE;
  end; // deleteItem

  procedure getItem();
  var
    f: Tfile;
    act: TfileAction;
    w: string;

    function getAttr(name:string; a:TfileAttribute):boolean;
    begin
    result:= w = name;
    if result then
      trueIf(a in f.flags);
    end; // setAttr

  begin
  result:='';
  f := fs.findFileByURL(p, md.folder);
  if f = NIL then exit; // doesn't exist

  try
    w:=par(1);
    if w = 'exists' then
      result:='1'
    else if w = 'comment' then
      result:=f.getDynamicComment(LP)
    else if w = 'resource' then
      result:=f.resource
    else if w = 'icon' then
      result := getItemIcon(f)
    else if getAttr('hide', FA_HIDDEN)
      or getAttr('hide tree', FA_HIDDENTREE)
      or getAttr('no log', FA_DONT_LOG) then
      exit
    else if w = 'not as download' then
      if f.isFolder() then
        result:=f.dontCountAsDownloadMask
      else
        trueIf(FA_DONT_COUNT_AS_DL in f.flags);

    for act:=low(act) to high(act) do
      if compareText(w, FILEACTION2STR[act]) = 0 then
        begin
        result:=join(';', f.accounts[act]);
        exit;
        end;
  finally freeIfTemp(f) end;
  end; // getItem

  procedure foreach();
  var
    i, e: integer;
    s, code: UnicodeString;
  begin
    e := pars.count-2; // 3 parameters minimum (the check is outside)
    code := macroDequote(par(pars.count-1));
    with TfastUStringAppend.create do
    try
      for i:=1 to e do
       begin
        setVar(p, par(i));
        s := code;
        applyMacrosAndSymbols(fs, s, cbMacros, cbData);
        append(s);
       end;
      result:=reset();
     finally
      free
    end;
  end; // foreach

  procedure forLine();
  var
    lines: TStringList;
    line, code: string;
    run: UnicodeString;
    i: integer;
  begin
    code := macroDequote(par(pars.count-1));
    lines := TStringList.create();
    with TfastUStringAppend.create do
     try
        lines.text:= getVar(par('var'));
        for line in lines do
          begin
          i:=pos('=',line);
          if i > 0 then
            begin
            setVar('line-key', Copy(line, 1, i-1));
            setVar('line-value', Copy(line, i+1, MAXINT));
            end;
          setVar('line', line);
          run:=code;
          applyMacrosAndSymbols(fs, run, cbMacros, cbData);
          append(run);
          end;
        result:=reset();
      finally
        Free;
        lines.Free;
     end;
  end; //forLine

  procedure for_();
  var
    b, e, i, d: integer;
    code: string;
    s: UnicodeString;
  begin
  try
    b:=strToInt(par(1));
    e:=strToInt(par(2));
    try
      d:=strToInt(par(3));
      code:=par(4);
    except
      d:=1;
      code:=par(3);
      end;
    if d = 0 then exit;
    if (e < b) and (d > 0) then d:=-d; // we care
    code:=macroDequote(code);
    with TfastUStringAppend.create do
      try
        for i:=1 to (e-b) div d+1 do
          begin
          setVar(p, intToStr(b));
          s:=code;
          applyMacrosAndSymbols(fs, s, cbMacros, cbData);
          append(s);
          inc(b, d);
          end;
        result:=reset();
      finally free end;
  except end;
  end; // for_

  procedure while_();
  var
    bTest, bDo: string;
    s: UnicodeString;
    never: boolean;
    res: TFastUStringAppend;
    space: THashedStringList;
    start, timeout: Tdatetime;
  begin
    result:='';
    res := TfastUStringAppend.create;
    try
      never:=TRUE;
      bDo:=macroDequote(par(1)); // do-block

      bTest:='';
      // test-block
      space:=NIL;
      if anyMacroMarkerIn(p) then
          bTest:=macroDequote(p)
      else
        try // lets see if the test-block is just the name of a variable
          space:=getVarSpace(p);
          bTest:=p;
        except end;

      if bTest = '' then exit;

      timeout:=parF('timeout', 1)/SECONDS; // stay safe: 1 second timeout by default
      start:=now();
      repeat
        if (timeout > 0) and (now()-start > timeout) then break;
        if assigned(space) then
          s:=space.values[bTest]
         else
          begin
            s:=bTest;
            applyMacrosAndSymbols(fs, s, cbMacros, cbData);
          end;
        if isFalse(trim(s)) then
          break;
        s:=bDo;
        applyMacrosAndSymbols(fs, s, cbMacros, cbData);
        res.append(s);
        never:=FALSE;
      until false;
      if never then
        res.append(macroDequote(par('else'))); // else-block
     finally
      result := res.reset();
      try
        setVar(pars.parEx('var'), result);
        result:='';
       except
      end;
      res.free();
    end;
  end; // while_

  procedure setEncodedTable(varname, txt: string);
  var
    space, h: ThashedStringList;
    i: integer;
  begin
    chopLine(txt); // first line is just a useless header
    // search the variable in the varspace
    space := getVarSpace(varname);
    if not satisfied(space) then
      exit;
    i:=space.indexOfName(varname);
    // eventually destroy previous object
    if i >= 0 then
      begin
        h:=space.objects[i] as ThashedStringList;
        freeAndNIL(h);
        space.objects[i]:=NIL;
      end;
    // create the table object
    h := ThashedStringList.create();
    while txt > '' do
      h.add(unescapeNL(chopline(txt)));
    // assign the variable value
    txt := h.text;
    if i < 0 then
      i := space.add(varname+'='+txt)
    else
      space.valueFromIndex[i]:=txt;
    // link the object
    space.objects[i]:=h;
  end; // setEncodedTable

  procedure load(const fn: String; const varname: string='');
  var
    from, size: int64;
  begin
    result:='';
    from:=parI('from', 0);
    // 'size' has priority over 'to'
    size:=parI('size', -1);
    if size = -1 then
      begin
        size:=parI('to', -1);
        if size >= 0 then
          inc(size, 1-from);
      end;
    if size = 0 then
      exit;
    from := max(0,from);

    if reMatch(fn, '^https?://', 'i!') > 0 then
      try
        result:= UnUTF( httpGet(fn, from, size))
       except
        result:=''
      end
     else
      result := UnUTF(loadFile(fs.uri2diskMaybe(fn), from, size));

    if varname = '' then
      begin
        if anyCharIn('/\',fn) then
          result:=macroQuote(result);
        exit;
      end;
    if ansiStartsStr(UnicodeString(ENCODED_TABLE_HEADER), result) then
      setEncodedTable(varname, result)
     else
      setVar(varname, result);
    result:='';
  end; // load

  function uri2diskMaybeFolder(s: String): String; // like uri2diskMaybe, but limited to the path, excluding the filename
  var
    path: string;
  begin
  if ansiContainsStr(s, '/') then
    begin
    path := fs.uri2disk(chop(lastDelimiter('/\',s)+1, 0, s), md.folder);
    if path > '' then
      s:=path+'\'+trim(s); // mod by mars
    end;
  result:=s;
  end; // uri2diskMaybeFolder

  procedure save();
  var
    space, h: THashedStringList;
    s: string;
    i: integer;
    encode: boolean;
  begin
  result:='';
  if not pars.parExist('var') then // will we work with a variable?
    s:=pars[1]
  else
    begin
    s:=par('var');
    space:=getVarSpace(s);
    if not satisfied(space) then exit;

    i:=space.indexOfName(s);
    if i < 0 then exit; // this var doesn't exit. don't write.
    encode:=FALSE;
    // if this is used as table, and has newlines, we must encode it to preserve associations
    h:=space.objects[i] as THashedStringList;
    if assigned(h) then
      for i:=0 to h.count-1 do
        if anyCharIn([#13,#10], h.strings[i]) then
          begin
          encode:=TRUE;
          break;
          end;
    if not encode then
      s:=space.valueFromIndex[i]
    else
      with TfastUStringAppend.create do
        try // table must be codified, or they won't work at load-time
          append(ENCODED_TABLE_HEADER);
          for i:=0 to h.count-1 do
            append(escapeNL(h.strings[i])+CRLF);
          s:=get();
         finally
          free
        end;
    end;
  // now we have in 's' the content to be saved
  spaceIf(saveFileU(uri2diskMaybeFolder(p), s, name='append'));
  end; // save

  procedure replace();
  var
    i: integer;
    v: string;
  begin
    if pars.parExistVal('var', v) then
      try
        result := getVar(v);
       except
        result := pars[pars.count-1]
      end
     else
      begin
        v := '';
        result := pars[pars.count-1];
      end;

    i:=0;
    while i < pars.count-2 do
      begin
      result:=xtpl(result, [pars[i], pars[i+1]]);
      inc(i, 2);
      end;
    if v = '' then exit;
    setVar(v, result);
    result:='';
  end; // replace

  procedure dialog();
  type
      t_s2c = record s: String; val: byte; end;
  const
    STR2CODE: array [1..7] of t_s2c = (
      (s:'okcancel=1'; val: 1),
      (s:'yesno=4'; val: 4),
      (s:'yesnocancel=3'; val: 3),
      (s:'error=16'; val: 16),
      (s:'question=32'; val: 32),
      (s:'warning=48'; val: 48),
      (s:'information=64'; val: 64)
    );
  var
    code: integer;
    decode: TStringDynArray;
    d, d2: string;
    buttons, icon: boolean;
    s: t_s2c;
  begin
  decode:=split(' ',par(1));
  code:=0;
  for d in decode do
   begin
    d2 := d + '=';
    for s in STR2CODE do
      if ansiStartsStr(d2, s.s) then
        inc(code, s.val);
   end;
  buttons:=code AND 15 > 0;
  icon:=code SHR 4 > 0;
  if not icon and buttons then
    inc(code, MB_ICONQUESTION);
  case msgDlg(p, code, par(2)) of
    MRYES, MROK: result := if_(buttons, String('1')); // if only OK button is available, then return nothing
    MRCANCEL: result := if_(code and MB_YESNOCANCEL = MB_YESNOCANCEL, String('cancel')); // for the YESNOCANCEL, we return cancel to allow to tell NO from CANCEL
    else result:='';
    end;
  end; // dialog

  procedure setAccount();
  var
    a: Paccount;
    s: string;
  begin
  result:='';
  if p > '' then
    a:=getAccount(p, TRUE)
  else
    a:=md.cd.account;
  if a = NIL then exit;
  spaceIf(TRUE);

  try
    s := pars.parEx('password');
    if validUsername(s, TRUE) then
      a.pwd:=s;
  except end;

  try
    s := pars.parEx('newname');
    if validUsername(s) then
      a.user:=s;
  except end;

  try a.redir := pars.parEx('redirect') except end;
  try a.noLimits := isTrue(pars.parEx('no limits')) except end;
  try a.enabled := isTrue(pars.parEx('enabled')) except end;
  try a.group := isTrue(pars.parEx('is group')) except end;
  try a.link:=split(';', pars.parEx('member of')) except end;
  try addArray(a.link, split(';', pars.parEx('add member of'))) except end;
  try removeArray(a.link, split(';', pars.parEx('remove member of'))) except end;
  try a.notes := pars.parEx('notes') except end;
  try a.notes := setKeyInString(a.notes, pars.parEx('notes key')) except end;
  end; // setAccount

  procedure getterAccount();
  var
    a: Paccount;
    s: string;
  begin
  result:='';
  if p > '' then
    a:=getAccount(p, TRUE)
  else
    a:=md.cd.account;
  if a = NIL then exit;
  s:=lowercase(par(1));
  if s = 'redirect' then result:=a.redir
  else if s = 'no limits' then trueIf(a.nolimits)
  else if s = 'enabled' then trueIf(a.enabled)
  else if s = 'is group' then trueIf(a.group)
  else if s = 'member of' then result:=join(';',a.link)
  else if s = 'notes' then result:=a.notes
  else if s = 'password' then result:=a.pwd
  else if s = 'password is' then trueIf((a.pwd=pars[2]) or (trim(a.pwd)=par(2)))  //add by mars
  else if s = 'exists' then result:='1';
  try result := getKeyFromString(a.notes, pars.parEx('notes key')) except end;
  end; // getterAccount

  procedure newAccount();
  var
    a: Taccount;
  begin
    result:='';
    if accountExists(p, TRUE) then
      exit; // username already in use
    if not validUsername(p) then
      exit;
    ZeroMemory(@a, sizeof(a)); // the account is disabled by default
    a.user:=p;
    setLength(accounts, length(accounts)+1);
    accounts[length(accounts)-1]:=a;
    setAccount();
  end; // newAccount

  function fromTable(tbl, k:string):string;
  var
    i: integer;
    space, h: THashedStringList;
    s: string;
  begin
  result:='';
  if tbl = 'ini' then deprecatedMacro('from table|ini','from table|#ini');
  try space:=getVarSpace(tbl);
  except exit end;
  if not satisfied(space) then exit;
  i:=space.indexOfName(tbl);
  if (i < 0) and ansiStartsStr('$', tbl) then
    begin
    s:=md.tpl[copy(tbl,2,MAXINT)];
    if s = '' then exit;
    i:=space.add(tbl+'='+s);
    end;
  if i < 0 then exit;
  // the text of the table is converted to a hashed structure, and cached through the objects[] property
  h:=space.objects[i] as THashedStringList;
  if h = NIL then
    begin
    h:=ThashedStringList.create();
    h.text:=space.valueFromIndex[i];
    space.objects[i]:=h;
    end;
  result:=h.values[k];
  // we are reading a value from the ini, so we convert the 'no' to a valid false value (the empty string)
  if stringExists(tbl, ['ini','#ini']) and (result = 'no') then result:='';
  end; // fromTable

  procedure setTable();
  var
    i: integer;
    k, v: string;
    space, h: THashedStringList;
  begin
  result:='';
  space:=getVarSpace(p);
  if not satisfied(space) then exit;
  // set the table variable as text
  v:=par(1);
  // access the table object
  i:=space.indexOfName(p);
  if i < 0 then
    begin
    h:=ThashedStringList.create();
    space.AddPair(p, v, h);
    end
  else
    h:=space.objects[i] as THashedStringList;
  // fill the object
  k:=chop('=',v);
  v:=macroDequote(v);
  h.values[k]:=v;
  space.values[p]:=h.text;
  end; // setTable

  procedure disconnect();
  var
    i: integer;
    ipmask, portmask: string;
  begin
    if pars.count = 0 then
      begin
      if satisfied(md.cd) then
        md.cd.conn.disconnect();
      exit;
      end;
    ipmask:=par(0,'ip');
    portmask:=par(1,'port');
    if ipmask = '' then exit;
    for i:=0 to srv.conns.count-1 do
      with fs.conn2data(i) do
        if addressmatch(ipmask, address)
        and ((portmask = '') or filematch(portmask, conn.port)) then
          conn.disconnect();
    result:='';
  end; // disconnect

  procedure vardomain();
  var
    space: ThashedStringList;
    sep: string;
    i: integer;
    fs: TfastUStringAppend;
    values: boolean;
  begin
    fs:=TfastUStringAppend.create;
    try
      values:=sameText(par('get'), 'values');
      sep:=par('separator', FALSE, '|');
      space:=getVarSpace(p);
      for i:=0 to space.count-1 do
        if ansiStartsText(p, space.names[i]) then
          begin
          if fs.length > 0 then
            fs.append(sep);
          if values then
            fs.append(space.valueFromIndex[i])
          else
            fs.append(space.names[i]);
          end;
      result:=fs.get();
     finally
      fs.free
    end;
  end; // vardomain

  procedure exec_();
  var
    s: string;
    code: cardinal;
  begin
  s:=macroDequote(par(1));
  if fileOrDirExists(s) then
    s:=quoteIfAnyChar(' ', s)
  else
    if unnamedPars < 2 then
      s:='';
  if pars.parExist('out') or pars.parExist('timeout') or pars.parExist('exit code') then
    try
      spaceIf(captureExec(macroDequote(p)+nonEmptyConcat(' ', s), s, code, parF('timeout',2)));
      try setVar(pars.parEx('exit code'), intToStr(code)) except end;
      setVar(pars.parEx('out'), s);
    except end
  else
    spaceIf(exec(macroDequote(p), s))
  end; // exec_

  procedure memberOf();
  var
    a: Paccount;
    s: string;
  begin
  result:='';
  s:=par(1, 'user');
  if s > '' then
    a:=getAccount(s, TRUE)
  else if assigned(md.cd) then
    a:=md.cd.account
  else
    exit;
  s:=par(0,'group');
  if s = '' then // you don't tell me the group, i'll tell you the groups
    begin
    result:=join(';',expandLinkedAccounts(md.cd.account));
    exit;
    end;
  a:=findEnabledLinkedAccount(a, split(';',s));
  if assigned(a) then
    result:=a.user;
  end; // memberOf

  procedure canArchive(f:Tfile);
  begin trueIf(assigned(f) and f.hasRecursive(FA_ARCHIVABLE) or (f = NIL) and md.archiveAvailable) end;

  procedure actionAllowed(action:TfileAction);
  var
    f: Tfile;
    s: String;
    local: boolean;
  begin // note: "delete" is meant for files inside the folder bearing the permission
    local := FALSE;
    result := '';
    try
      s := pars.parExNE('path');
      if s = '' then
        begin
          if action = FA_ACCESS then
            f := md.f
           else
            f := md.folder;
        end
       else
        begin
          f := fs.findFileByURL(s, md.folder);
          if f = NIL then
            exit;
          local:=TRUE;
        end;
     except
        if action = FA_ACCESS then
          f := md.f
         else
          f := md.folder;
    end;
    trueIf(accountAllowed(action, md.cd, f));
    if local then
      freeIfTemp(f);
  end; // actionAllowed

  procedure cookie();

    function timeForCookies(v:string):string;
    var
      t: Tdatetime;
    begin
    try
      if getFirstChar(v) in ['+','-'] then
        t:=now()+strToFloat(v)
      else
        try
          t := maybeUnixTime(strToFloat(v));
         except
          t := strToDateTime(v)
        end;
      result:=dateToHTTP(localToGMT(t));
    except result:=v end;
    end; // timeForCookies

    function getPairs():TStringDynArray;
    var
      i: integer;
      k, v: string;
    begin
    result:=NIL;
    for i:=1 to pars.count-1 do
      begin
      v:=pars[i];
      k:=trim(chop('=', v));
      v:=trim(v);
      if k = 'value' then // this is handled below
        continue
      else if k = 'expires' then
        v:=timeForCookies(v);
      addArray(result, [k, v]);
      end;
    end; // getPairs
  var
    v: String;
  begin
    if not satisfied(md.cd) then
      exit;
    result:='';
    if pars.parExistVal('value', v) then
      try md.cd.conn.setCookie(p, v, getPairs());
      except result:=noMacrosAllowed(md.cd.conn.getCookie(p)) end // there was no "value" to set, so just read
     else
      result := noMacrosAllowed(md.cd.conn.getCookie(p)); // there was no "value" to set, so just read
  end; // cookie

  procedure regexp();
  var
    subs: TStringDynArray;
    subj, s, mods: string;
    i: integer;
  begin
    // input from variable or text
    try
      subj := getVar(pars.parEx('var'));
     except
      subj:=par(1)
    end;
    // check
    mods := 'm'+if_(isFalse(par('case')), String('i'));
    p:=macroDequote(p);
    i:=reMatch(subj, p, mods, 1, @subs);
    if i <= 0 then
      begin
      result:='';
      exit;
      end;
    // return first match, or position
    if assigned(subs) then
      result:=subs[min(length(subs)-1,1)]
     else
      result:=intToStr(i);
    // eventually communicate matched substrings
    try
      pars.parEx('sub');
      s:='';
      for i:=0 to length(subs)-1 do
        s:=s+format('%d=%s'+CRLF, [i, subs[i]]);
      setVar(pars.parEx('sub'), s);
     except
    end;

    try
      result := reReplace(subj, p, pars.parEx('replace'), mods);
      setVar(pars.parEx('var'), result); // we put the output where we got the input
      result:='';
     except
    end;
  end; // regexp

  procedure dir();
  var
    sr: TSearchRec;
    fs: TfastUStringAppend;
    sep, s: string;
  begin
  result:='';
  // user can specify a file mask, or a folder path
  s:=excludeTrailingPathDelimiter(p);
  if directoryExists(s) then
    s:=s+'\*';
  if findfirst(s, faAnyFile, sr) <> 0 then exit;

  sep:=par('separator', FALSE, '|');
  try
    fs:=TfastUStringAppend.create();
      repeat
      if (sr.name = '.') or (sr.name = '..') then continue;
      if fs.length > 0 then
        fs.append(sep);
      fs.append(sr.name);
      until findNext(sr) <> 0;
    result:=fs.get();
  finally
    findClose(sr);
    freeAndNIL(fs);
    end;
  end; // dir

  procedure handleSymbol();
  var
    s, usr: string;
    i: integer;
  begin
  // search for the symbol in the translation table
    if Assigned(md.table) then
      begin
        if md.table.ContainsKey(name) then
         begin
          Result := md.table.Items[name];
          Exit;
         end
      end;
    result:=name; // by default, an unrecognized symbol remains the same (just as the song)

    // most symbols here, are here because they can be heavy to calculate, so we ensure we do
    // it only upon request. others are for centralization.

    if ansiStartsText('%sym-', name) then // legacy: surpassed by {.section.}
      result := fs.tpl[substr(name,2,-1)]
    else if name = '%item-icon%' then
      result := first(getItemIcon(md.f), name)
    else if name = '%item-archive%' then
      if assigned(md.f) and assigned(md.tpl) and md.f.hasRecursive(FA_ARCHIVABLE) then result:=md.tpl['item-archive']
      else result:=''
    else if name = '%item-dl-count%' then
      if md.f = NIL then result:=''
      else result:=intToStr(md.f.DLcount)
    else if name = '%connections%' then
      result:=intToStr(srv.conns.count)
    else if name = '%style%' then
      result := fs.tpl['style']
    else if name = '%timestamp%' then
      result:= dateTimeToStr(now())
    else if name = '%date%' then
      result:= dateToStr(now())
    else if name = '%time%' then
      result:= timeToStr(now())
    else if name = '%now%' then
      result:=floatToStr(now())
    else if name = '%version%' then
      result:= srvConst.VERSION
    else if name = '%build%' then
      result:=VERSION_BUILD
    else if name = '%uptime%' then
      result:= fs.uptimestr()
    else if name = '%speed-out%' then
      result:=floatToStrF(srv.speedOut/1000, ffFixed, 7,2)
    else if name = '%speed-in%' then
      result:=floatToStrF(srv.speedIn/1000, ffFixed, 7,2)
    else if name = '%total-out%' then
      result:=smartSize(outTotalOfs + srv.bytesSent)
    else if name = '%total-in%' then
      result:=smartSize(inTotalOfs + srv.bytesReceived)
    else if name = '%total-downloads%' then
      result:=intToStr(downloadsLogged)
    else if name = '%total-hits%' then
      result:=intToStr(hitsLogged)
    else if name = '%total-uploads%' then
      result:=intToStr(uploadsLogged)
    else if name = '%number-addresses%' then
      result:=intToStr(fs.countIPs())
    else if name = '%number-addresses-ever%' then
      result:=intToStr(ipsEverConnected.count)
    else if name = '%number-addresses-downloading%' then
      result:=intToStr(fs.countIPs(TRUE))
    else if name = '%number-users%' then
      result:=intToStr(fs.countIPs(FALSE, TRUE))
    else if name = '%number-users-downloading%' then
      result:=intToStr(fs.countIPs(TRUE, TRUE))
    else if name = '%cwd%' then
      result:=getCurrentDir()
    else if name = '%port%' then
      result := srv.port;

    if assigned(md.cd) then
      begin
      usr:=md.cd.usr;
      if name = '%host%' then
        result:=md.cd.getSafeHost(md.cd)
      else if name = '%ip%' then
        result:=md.cd.address
      else if name = '%ip-to-name%' then
        result:=localDNSget(md.cd.address)
      else if name = '%lang%' then
        result:=stripChars(copy(md.cd.conn.getHeader('Accept-Language'),1,2), ['a'..'z','A'..'Z'], TRUE)
      else if name = '%url%' then
        result:=macroQuote(md.cd.conn.httpRequest.url)
      else if name = '%user%' then
        result:= macroQuote(usr)
      else if name = '%password%' then
        result := macroQuote(md.cd.conn.httpRequest.pwd)
      else if name = '%loggedin%' then
        result := if_(usr>'', fs.tpl['loggedin'])
      else if name = '%login-link%' then
        result := if_(usr='', fs.tpl['login-link'])
      else if name = '%user-notes%' then
        if md.cd.account = NIL then result:=''
        else result:=md.cd.account.notes
      else if name = '%stream-size%' then
        result:=intToStr(md.cd.conn.bytesFullBody)
      else if name = '%is-archive%' then
        trueIf(md.cd.downloadingWhat=DW_ARCHIVE)
      end;


    if assigned(md.folder) then
      if name = '%folder-item-comment%' then
        result:= md.folder.getDynamicComment(LP)
      else if name = '%folder-comment%' then
        begin
        result:=md.folder.getDynamicComment(LP);
        if result > '' then
          result := xtpl(fs.tpl['folder-comment'], [ '%item-comment%', result ]);
        end
      else if name = '%diskfree%' then
        result:=smartSize(diskSpaceAt(md.folder.resource)-minDiskSpace*MEGA)
      else if name = '%up%' then
        result:=if_(assigned(md.tpl) and not md.folder.isRoot(), md.tpl['up'])
      else if name = '%encoded-folder%' then
        result := fs.url(md.folder, TRUE)
      else if name = '%parent-folder%' then
        result := fs.parentURL(md.folder)
      else if name = '%folder-name%' then
        result:= md.folder.name
      else if name = '%folder-resource%' then
        result:=md.folder.resource
      else if name = '%folder%' then
        with md.folder do
          result:= if_(isRoot(), '/', getFolder()+name+'/')
    ;

    if assigned(md.f) then
      if name = '%item-name%' then
        begin
        s:=md.f.name;
        if md.hideExt and md.f.isFile() then
          setLength(s, length(s)-length(extractFileExt(s)) );
        result:=htmlEncode(macroQuote(s))
        end
      else if name = '%item-type%' then
        if md.f.isLink() then
          result:='link'
        else if md.f.isFolder() then
          result:='folder'
        else
          result:='file'
      else if name = '%item-size-b%' then
        result:=intToStr(md.f.size)
      else if name = '%item-size-kb%' then
        result:=intToStr(md.f.size div KILO)
      else if name = '%item-size%' then
        result:=smartsize(md.f.size)
      else if name = '%item-resource%' then
        result:=macroQuote(md.f.resource)
      else if name = '%item-ext%' then
        result:=macroQuote(copy(extractFileExt(md.f.name), 2, MAXINT))
      else if name = '%item-added-dt%' then
        result:=floatToStr(md.f.atime)
      else if name = '%item-modified-dt%' then
        result:=floatToStr(md.f.mtime)
      // these twos are actually redundant, {.time||when=%item-added-dt%.}
      else if name = '%item-added%' then
        result:= datetimeToStr(md.f.atime)
      else if name = '%item-modified%' then
        result:=if_(md.f.mtime=0, 'error', datetimeToStr(md.f.mtime))
      else if name = '%item-comment%' then
        result:= md.f.getDynamicComment(LP, TRUE)
      else if name = '%item-url%' then
        result:=macroQuote(fs.url(md.f))
    ;

    if assigned(md.f) and assigned(md.tpl) then
      if name = '%new%' then
        result:=if_(md.f.isNew(), md.tpl['newfile'])
      else if name = '%comment%' then
        result:=if_(md.f.getDynamicComment(LP, TRUE) > '', md.tpl['comment'])
    ;

    if assigned(md.tpl) then
      if name = '%archive%' then
        result:=if_(md.archiveAvailable, md.tpl['archive']);

    if ansiContainsText(name, 'folder') and not ansiContainsText(name, 'comment') then
      result:=macroQuote(result);
  end; // handleSymbol


   {$IFNDEF HFS_SERVICE}
  function stringToTrayMessageType(const s: String): TBalloonIconType;
  begin
    if compareText(s,'warning') = 0 then
      result:= bitWarning
    else if compareText(s,'error') = 0 then
      result:= bitError
    else if compareText(s,'info') = 0 then
      result:= bitInfo
    else
      result:= bitNone
  end; // stringTotrayMessageType
   {$ENDIF ~HFS_SERVICE}

  function renameIt(const src, dst: String): Boolean;
  var
    srcReal, dstReal: string;
  begin
    srcReal := fs.uri2diskMaybe(src,NIL,FALSE);
    dstReal := uri2diskMaybeFolder(dst);
    if isExtension(srcReal, '.lnk')
    and not isExtension(src, '.lnk') then
      dstReal:=dstReal+'.lnk';
    if extractFilePath(dstReal)='' then
      dstReal:=extractFilePath(srcReal)+dstReal;
    result := renameFile(srcReal, dstReal)
  end; // renameIt

var
  i64: int64;
  i: integer;
  r: Tdatetime;
  s: UnicodeString;
  s1, v1: String;
  c1: Char;
begin
  try
    assert(assigned(cbData), 'cbMacros: cbData=NIL');
    md := cbData;
    if md.breaking then
      exit;

    LP := fs.LP;
    SP := fs.SP;

    try

      name := fullmacro;
      if (name[1] = '%') and (name[length(name)] = '%') then
        begin
        handleSymbol();
        exit;
        end;

     {$IFDEF FMX}
      if not mainfrm.enableMacrosChk.isChecked then
     {$ELSE ~FMX}
      if not mainfrm.enableMacrosChk.Checked then
     {$ENDIF FMX}
        exit(fullMacro);

      if pars.count = 0 then
        exit;
      // extract first parameter as 'name'
      name := trim(pars[0]);
      pars.delete(0);    // this operation is done with a memory move over pointers. Having few parameters normally, it's fast. We may eventually avoid this deletion and consider parameters starting from 1.
      if name = '' then
        exit;
      macroError('not supported or illegal parameters');
      // eventually remove trailing
      if pars.Count > 0 then
        begin
          p := pars[pars.count-1];
          if ansiEndsText('/'+name, p) then
           begin
            setLength(p, length(p)-length(name)-1);
            pars[pars.count-1] := p;
           end;
        end;

      unnamedPars := 0;
      if pars.count > 0 then
        for i:=0 to pars.count-1 do
          begin
            pars[i] := xtpl(pars[i], ['{:|:}','|']);
            if (i = unnamedPars) and (pos('=',pars[i]) = 0) then
              inc(unnamedPars);
          end;

      // handle aliases
      if assigned(md.aliases) then
       begin
        s := md.aliases.values[name];
        if s > '' then
         begin
          if not ansiStartsStr(MARKER_OPEN, s) then
            s:=MARKER_OPEN+s+MARKER_CLOSE;
          call(s);
          exit;
         end;
       end;

      // here we try to handle some shortcuts.
      // it's a special starting character that identifies the macro, and the rest of the name is a parameter.
      c1 := name[1];
      if c1 in ['$', '!', '^', '?'] then
       begin
        p := copy(name,2,MAXINT);
        if c1 = '$' then
          section(0)
         else
        if c1 = '!' then
          // we look for they key (p) in {.^special:strings.} then in [special:strings]. If no luck, we try to output an eventual parameter, or the key itself.
          try
            //result := first([fromTable('special:strings',p), md.tpl.getStrByID(p), par(0), p])
            Result := fromTable('special:strings', p);
            if Result = '' then
              Result := md.tpl.getStrByID(p);
            if Result = '' then
              Result := par(0);
            if Result = '' then
              Result := p;
           except
          end
         else
        if c1 = '^' then
          try
            call(getVar(p), 0)
           except
          end
         else
        if c1 = '?' then  // shortcut for 'urlvar'
          result := urlvar(p);
        Exit;
       end;

      if pars.count > 0 then
        p := par(0) // a handy shortcut for the first parameter
       else
        p := '';

      // comment is for comments, or if you just want to trash the output of a macro.
      // Careful: the comment itself (the parameter of this command) is executed as anything else, unless it's {:quoted:}
      if name = 'comment' then
       begin
        result:='';
        exit;
       end;

      // infix operators are macros in the form PARAMETER NAME PARAMETER. it's handy for comparisons.
      infixOperators(['>=','<=','<>','!=','=','>','<']); // the order is important, because >= would be confused with =

      // ok, fom here we have macros in the straight form NAME|PARAM|PARAM
      name := ansiLowercase(name);

      if name = 'count' then
        begin
          if satisfied(md.cd) then
            result := intToStr(md.cd.tplCounters.incInt(p)-1); // it can work even with no parameters
        end
       else
      if name = 'time' then
        begin
          s:=par(0,'format');
          r:=parF('when',now())+parF('offset',0);
          if s = 'y' then
            result := floatToStr(r)
           else
            begin
              datetimeToString(s1, first(s,'c'), r );
              Result := s1;
            end;
        end
       else
      if name = 'disconnect' then
        disconnect()
       else
      if name = 'stop server' then
        begin
        stopServer();
        exit('');
        end
       else
      if name = 'start server' then
        begin
        startServer();
        exit('');
        end
       else
      if name = 'focus' then
        begin
     {$IFDEF FMX}
     {$ELSE ~FMX}
        application.restore();
        application.bringToFront();
     {$ENDIF FMX}
        result:='';
        end
       else
      if name = 'current downloads' then
        result := intToStr(fs.countDownloads( par('ip'), par('user'), if_(sameText(par('file'), 'this'), md.f) as Tfile) )
       else
      if name = 'disconnection reason' then
        begin
          try
            if isFalse(pars.parEx('if')) then
              begin
              result:='';
              exit;
              end;
          except end;
          result:=md.cd.disconnectReason; // return the previous state
          if pars.count > 0 then md.cd.disconnectReason:=p;
        end
       else
      if name = 'clipboard' then
        begin
          if p = '' then
            begin
             {$IFDEF FMX}
              begin
                var
                  ClipService: IFMXExtendedClipboardService;
                if TPlatformServices.Current.SupportsPlatformService(IFMXExtendedClipboardService, ClipService) then
                  result := clipService.GetText
                 else
                  result := '';
              end;
             {$ELSE ~FMX}
              result := clipboard.asText
             {$ENDIF FMX}
            end
           else
            begin
              try
                setClip(getVar(pars.parEx('var')))
               except
                setClip(p)
              end;
              result:='';
            end;
        end
       else
      if name = 'save vfs' then
        begin
        mainfrm.saveVFS(first(p,lastFileOpen));
        result:='';
        end
       else
      if name = 'save cfg' then
        begin
          if p = 'file' then savemode:=SM_FILE
          else if p = 'registry' then savemode:=SM_USER
          else if p = 'global registry' then savemode:=SM_SYSTEM;
          mainFrm.saveCFG();
          result:='';
        end
       else
      if name = 'js encode' then
        result := jsEncode(p, first(par(1),'''"'))
       else
      if name = 'base64' then
        result := b64utf8(p)
       else
      if name = 'base64decode' then
        begin
          result := decodeB64utf8(RawByteString(p));
          if isFalse(par('macros')) then
            result:=noMacrosAllowed(result);
        end
       else
      if name = 'md5' then
        result := MD5PassHS(AnsiString(p))
       else
      if name = 'sha1' then
        result := SHA1toHex(SHA1Pass(p))
       else
      if name = 'sha256' then
        result := strSHA256(p)
       else
     {$IFNDEF HFS_SERVICE}
      if name = 'vfs select' then
        begin
          if pars.count = 0 then
            try
              result:= fs.url(mainFrm.selectedFile)
             except
              result := ''
            end
          else if p = 'next' then
            if mainFrm.selectedFile = NIL then
              spaceIf(FALSE)
            else
              begin
   {$IFDEF USE_VTV}
                var n2: TFileNode;
                n2 := mainFrm.filesBox.GetNext(mainFrm.selectedFile.node);
                mainFrm.filesBox.ClearSelection;
                if n2 <> NIL then
                  mainFrm.filesBox.Selected[n2] := True;
   {$ELSE ~USE_VTV}
              {$IFNDEF FMX}
              with mainFrm.filesBox do
                selected := selected.getNext();
              {$ENDIF FMX}
   {$ENDIF ~USE_VTV}
              spaceIf(TRUE);
              end
          else
            try
              s := pars.parEx('path');
              spaceIf(FALSE);
   {$IFDEF USE_VTV}
              var f2: Tfile;
              f2 := fs.findFilebyURL(s, NIL, FALSE);
              var n2: TFileNode;
              n2 := f2.node;
                if n2 <> NIL then
                  mainFrm.filesBox.Selected[n2] := True;
   {$ELSE ~USE_VTV}
              mainFrm.filesBox.selected := fs.findFilebyURL(s, NIL, FALSE).node;
   {$ENDIF ~USE_VTV}
              spaceIf(TRUE);
            except end;
        end
       else
     {$ENDIF ~HFS_SERVICE}
      if name = 'break' then
        begin
          result:='';
          try
            if isFalse(pars.parEx('if')) then
              exit;
          except end;
          try result := pars.parEx('result') except end;
          md.breaking := TRUE;
          exit;
        end;

      if pars.Count < 1 then exit; // from here, only macros with parameters

      if name = 'var domain' then
        vardomain()
       else
      if name = 'dir' then
        dir()
       else
      if name = 'no pipe' then
        result := xtpl(substr(fullMacro, '|'), ['|','{:|:}'])
       else
      if name = 'pipe' then
        result:=xtpl(substr(fullMacro, '|'), ['{:|:}','|'])
       else
      if name = 'add to log' then
        begin
        try s := getVar(pars.parEx('var'))
        except s:=p end;
        add2log(s, md.cd, stringToColorEx(par(1,'color'){$IFNDEF FMX}, clDefault {$ENDIF}));
        result:='';
        end
       else
      if name = 'mkdir' then
        begin
        s:=trim(uri2diskMaybeFolder(p));
        spaceIf(not directoryExists(s) and forceDirectory(s));
        end
       else
      if name = 'chdir' then
        begin
        IOresult;
        setCurrentDir(p);
        spaceIf(IOresult=0);
        end
       else
      if name = 'encodeuri' then
        encodeuri()
       else
      if name = 'decodeuri' then
        result:=noMacrosAllowed(decodeURL(p))
       else
      if name = 'set cfg' then
        trueIf(mainfrm.setcfg(p))
       else
      if name = 'dialog' then
        dialog()
       else
      if name = 'any macro marker' then
        trueIf(anyMacroMarkerIn(first(loadfile(fs.uri2diskMaybe(p)), p)))
       else
      if name = 'random' then
        result := randomFrom(pars.ToArray)
       else
      if name = 'random number' then
       begin
        if pars.count = 1 then
          result := intToStr(random(1+parI(0)))
        else
          result := intToStr(parI(0)+random(1+parI(1)-parI(0)));
       end else
      if name = 'force ansi' then
       begin
        if satisfied(md.tpl) then //and md.tpl.utf8 then
  //        result:=noMacrosAllowed(UTF8toAnsi(p))
          result := noMacrosAllowed(AnsiString(p))
        else
          result := p;
       end else
      if name = 'maybe utf8' then
       begin
        if satisfied(md.tpl) then
          result:= p;
       end else
      if name = 'after the list' then
       begin
        if md.afterTheList then
          result:=macroDequote(p)
        else
          result:=MARKER_OPEN+fullMacro+MARKER_CLOSE;
       end else
      if name = 'breadcrumbs' then
        breadcrumbs()
       else
      if name = 'filename' then
        result:=substr(p, lastDelimiter('\/:',p)+1)
       else
      if name = 'filepath' then
        begin
        i:=lastDelimiter('\/:',p);
        if i = 0 then
          result:=''
        else
          result:=substr(p, 1, i);
        end
       else
      if name = 'not' then
        trueIf(isFalse(p))
       else
      if name = 'length' then
        begin // don't trim
          if pars.parExistVal('var', v1, False) then
           try
             s := getVar(v1)
            except
             s := pars[0]
           end
           else
            s := pars[0];
          result := intToStr(length(s));
        end
       else
      if name = 'load' then
        load(p, par(1,'var'))
       else
      if name = 'load tpl' then
       begin
        if satisfied(md.cd) then
          begin
          md.cd.tpl:=cachedTpls.getTplFor(p);
          result:='';
          end;
       end else
      if name = 'filesize' then
        begin
          if reMatch(p, '^https?://', 'i!') > 0 then
            i64 := httpFileSize(p)
           else
            i64 := sizeOfFile(fs.uri2diskMaybe(p));
          result := intToStr(max(0,i64)); // we return 0 instead of -1 for non-existent files, t
        end
       else
      if name = 'filetime' then
        result:=floatToStr(getMtime(p))
       else
      if name = 'header' then
       begin
        if satisfied(md.cd) then
          try result:=noMacrosAllowed(md.cd.conn.getHeader(p)) except end;
       end else
      if name = 'urlvar' then
        result:=urlvar(p)
       else
      if name = 'postvar' then
       begin
        if satisfied(md.cd) then
          try
            result:=noMacrosAllowed(md.cd.postVars.values[p]);
            setVar(pars.parEx('var'), result); // if no var is specified, it will break here, and result will have the value
            result:='';
           except
          end;
       end else
      if name = 'section' then
        section(1)
       else
      if name = 'trim' then
        result:=p
       else
      if name = 'lower' then
        result:=ansiLowercase(p)
       else
      if name = 'upper' then
        result:=ansiUppercase(p)
       else
      if name = 'abs' then
        result:=floatToStr(abs(parF(0)))
       else
      if name = 'upload failed' then
        begin
          md.cd.uploadFailed:=p;
          result:='';
        end
       else
      if name = 'is file protected' then
        result := if_(filematch(PROTECTED_FILES_MASK, parVar('var',0)), String('1'))
       else
      if name = 'get' then
        try
          if p = 'can recur' then trueIf(lpRecurListing in lp)// mainFrm.recursiveListingChk.Checked)
          else if p = 'can upload' then actionAllowed(FA_UPLOAD)
          else if p = 'can delete' then actionAllowed(FA_DELETE)
          else if p = 'can access' then actionAllowed(FA_ACCESS)
          else if p = 'can archive' then canArchive(md.folder)
          else if p = 'can archive item' then canArchive(md.f)
          else if p = 'url' then getUri()
          else if p = 'stop spiders' then
                               {$IFDEF FMX}
                                trueIf(mainFrm.stopSpidersChk.isChecked)
                               {$ELSE ~FMX}
                                trueIf(mainFrm.stopSpidersChk.checked)
                               {$ENDIF FMX}
          else if p = 'is new' then trueIf(md.f.isNew())
          else if p = 'agent' then result:=md.cd.agent
          else if p = 'tpl file' then result:=tplFilename
          else if p = 'protocolon' then result := protoColon(fs)
          else if p = 'speed limit' then result:=intToStr(round(speedLimit))
          else if p = 'external address' then
            begin
              if externalIP = '' then
                getExternalAddress(externalIP);
              result := externalIP;
            end
          else if p = 'accounts' then
            result := join(';', getAccountList(
              stringExists(par(1),['','users']),
              stringExists(par(1),['','groups'])
            ))
          ;
         except
          unsatisfied()
        end
       else
      if name = 'call' then
        try call(getVar(p), 1) except end
       else
      if name = 'inc' then
        inc_()
       else
      if name = 'dec' then
        inc_(-1)
       else
      if name = 'chr' then
        begin
          result:='';
          for i:=0 to pars.count-1 do
            try
              result:=result+chr(strToInt(replaceStr(pars[i],'x','$')))
             except
            end;
        end
       else
      if name = 'dequote' then
        result:=macroDequote(p)
       else
      if name ='quote' then
        begin
          pU := macroDequote(p);
          applyMacrosAndSymbols(fs, pU, cbMacros, cbData);
          result := macroQuote(pU);
          p := pU;
        end
       else
      if name = 'encode html' then
        result:=htmlEncode(p)
       else
      if name = 'play' then
        begin
          result:='';
         {$IFNDEF FMX}
          playSound(Pchar(p), 0, SND_ALIAS or SND_ASYNC or SND_NOWAIT);
         {$ENDIF ~FMX}
        end
       else
      if name = 'delete' then
        begin
          s := fs.uri2diskMaybe(p, NIL, FALSE);
          if isTrue(par('bin',TRUE,'1')) then
            spaceIf(moveToBin(s, isTrue(par('forced'))))
           else
            spaceIf(deltree(s));
        end
       else
      if name = 'disk free' then
        result := intToStr(diskSpaceAt(fs.uri2diskMaybe(p)))
       else
      if name = 'vfs to disk' then
        begin
          if isAbsolutePath(p) then
            result:=p
           else if dirCrossing(p) and not ansiStartsStr('/', p) then
            result:=expandFileName(includeTrailingPathDelimiter(md.folder.resource)+p)
           else
            result := fs.uri2disk(p, md.folder);
        end
       else
      if name = 'exists' then
        if ansiContainsStr(p, '/') then
          trueIf(fs.fileExistsByURL(p))
        else
          trueIf(fileOrDirExists(p))
       else
      if name = 'is file' then
        trueIf(fileExists(p))
       else
      if name = 'mime' then
        begin
          result:='';
          if satisfied(md.cd) then md.cd.conn.reply.contentType:=p;
        end
       else
      if name = 'calc' then
        result:=floatToStr(evalFormula(p))
       else
      if name = 'smart size' then
        result:=smartsize(strToInt64(p))
       else
      if name = 'round' then
        result:=floatToStr(roundTo(parF(0), -parI(1, 0)))
       else
      if name = 'md5 file' then
        result:=createFingerprint(p)
       else
      if name = 'exec' then
        exec_()
       else
      if name = 'set speed limit for address' then
        begin
          if pars.count = 1 then
            setSpeedLimitIP(parF(0))
          else
            with objByIp(p) do
              begin
              limiter.maxSpeed:=round(parF(1)*1000);
              customizedLimiter:=TRUE;
              end;
          result:='';
        end
       else
      if name = 'set speed limit for connection' then
        begin
          if satisfied(md.cd) then
            try
              if assigned(md.cd.limiter) then
                begin
                md.cd.limiter.maxSpeed:=round(parF(0)*1000);
                exit;
                end;
              md.cd.limiter:=TspeedLimiter.create(round(parF(0)*1000));
              md.cd.conn.limiters.add(md.cd.limiter);
              srv.limiters.add(md.cd.limiter);
              result:='';
             except
              md.cd.conn.limiters.remove(md.cd.limiter);
              srv.limiters.remove(md.cd.limiter);
              freeAndNIL(md.cd.limiter);
              result:='';
            end;
        end
       else
      if name = 'member of' then
        memberOf()
       else
      if name = 'add header' then
        begin
          if satisfied(md.cd) then
           begin
            result:='';
            // macro 'mime' should be used for content-type, but this test will save precious time to those who will be fooled by the presence this macro
            if ansiStartsText('Content-Type:', p) then
              md.cd.conn.reply.contentType:=trim(substr(p, ':'))
            else if ansiStartsText('Location:', p) then
              with md.cd.conn.reply do
                begin
                mode:=HRM_REDIRECT;
                url:=trim(substr(p, ':'))
                end
            else
              md.cd.conn.addHeader(p, isTrue(par('overwrite',true,'1')));
           end;
        end
       else
      if name = 'remove header' then
        begin
          if satisfied(md.cd) then
            begin
            result:='';
            md.cd.conn.removeHeader(p);
            end;
        end
       else
      if name = 'get ini' then
        result := getKeyFromString(mainFrm.getCfg(), p)
       else
      if name = 'set ini' then
        begin
        result:='';
        mainfrm.setCfg(p);
        end
       else
      if name = 'set' then
        begin
          try s := getVar(pars.parEx('var'));
           except
            if pars.count < 2 then s:=''
            else s:=macroDequote(pars[1]);
          end;
          if par('mode') = 'append' then
            s:=getVar(p)+s
          else if par('mode') = 'prepend' then
            s:=s+getVar(p);
          spaceIf(setVar(p, s));
        end
       else
      if name = 'notify' then
        begin
        tray.balloon(p, parF('timeout',3), stringTotrayMessageType(par('type')), par('title'));
        result:='';
        end
       else
      if name = 'cookie' then
        cookie()
       else
      if name = 'new account' then
        newAccount()
       else
      if name = 'delete account' then
        begin
        deleteAccount(p);
        result:='';
        end
       else
      if name = 'delete item' then
        deleteItem();

      if pars.count < 2 then exit; // from here, only macros with at least 2 parameters

      if name = 'set item' then
        setItem()
       else
      if name = 'get item' then
        getItem()
       else
      if name = 'while' then
        while_()
       else
      if name = 'set table' then
        setTable()
       else
      if name = 'add folder' then
        addFolder()
       else
      if (name = 'save') or (name = 'append') then
        save()
       else
      if name = 'rename' then
        begin
          spaceIf( not isExtension(par(1), '.lnk') and // security matters (by mars)
            renameIt(p, par(1)) );
          if (result > '') and not stopOnMacroRename then // should we stop recursion?
            try
              // by default, we'll stop after first stacked [on macro rename], but recursive=1 will remove this limit
              stopOnMacroRename:=isFalse(par('recursive'));
              runEventScript(fs, 'on macro rename', toSA(['%old-name%',p,'%new-name%',par(1)]), md.cd);
             finally
              stopOnMacroRename:=FALSE;
            end;
        end
       else
      if name = 'move' then
        begin
        s:=uri2diskMaybeFolder(par(1));
        spaceIf((s>'') and movefile(fs.uri2diskMaybe(p,NIL,FALSE), s));
        end
       else
      if name = 'copy' then
        spaceIf(copyfile(fs.uri2diskMaybe(p), uri2diskMaybeFolder(par(1))))
       else
      if name = 'from table' then
        result:=fromTable(p, par(1))
       else
      if name = 'match' then
        trueIf(filematch(p, par(1)))
       else
      if name = 'match address' then
        trueIf(addressmatch(p, par(1)))
       else
      if name = 'regexp' then
        regexp()
       else
      if name = 'pos' then
        result:=intToStr(pos_(isTrue(par('case')), parVar('what', 0), parVar('var', 1), strToIntDef(par('from'), 1)))
       else
      if name = 'repeat' then
        result:=dupeString(macroDequote(par(1)), strToIntDef(p,1))
       else
      if name = 'count substring' then
        result:=intToStr(countSubstr(pars[0], par(1)))
       else
      if name = 'and' then
        allLogic(TRUE)
       else
      if name = 'or' then
        allLogic(FALSE)
       else
      if name = 'xor' then
        trueIf(isTrue(p) xor isTrue(par(1)))
       else
      if name = 'add' then
        result:=floatToStr(parF(0)+parF(1))
       else
      if name = 'sub' then
        result:=floatToStr(parF(0)-parF(1))
       else
      if name = 'mul' then
        result:=floatToStr(parF(0)*parF(1))
       else
      if name = 'div' then
        result:=floatToStr(safeDiv(parF(0),parF(1)))
       else
      if name = 'mod' then
        result:=intToStr(safeMod(parI(0),parI(1)))
       else

      if stringExists(name, ['min','max']) then
        minOrMax()
       else
      if stringExists(name, ['if','if not']) then
        begin
          if pars.parExistVal('var', v1) then
            try
              p := getVar(v1);
             except
            end;
          if isTrue(p) xor (length(name) = 2) then
            result := macroDequote(par(2))
           else
            result := macroDequote(par(1));
        end
       else
      if stringExists(name, ['=','>','>=','<','<=','<>','!=']) then
        trueIf(compare(name, p, par(1)))
       else
      if name = 'switch' then
        switch()
       else
      if name = 'set account' then
        setAccount()
       else
      if name = 'get account' then
        getterAccount()
       else
      if name = 'cut' then
        cut()
       else
      if name ='for line' then
        forLine();

      if pars.count < 3 then exit; // from here, only macros with at least 3 parameters

      if name ='for each' then
        foreach()
       else
      if name = 'substring' then
        substring()
       else
      if name = 'replace' then
        replace()
       else
      if name = 'convert' then
        convert();

      if pars.count < 4 then exit;

      if name = 'for' then
        for_();
    finally
     {$IFDEF FMX}
      if mainfrm.macrosLogChk.isChecked then
     {$ELSE ~FMX}
      if mainfrm.macrosLogChk.checked then
     {$ENDIF FMX}
        begin
        if not fileExists(MACROS_LOG_FILE) then
          saveFile2(MACROS_LOG_FILE, HEADER);
        macrosLog(fullMacro, result, md.logTS);
        md.logTS := FALSE;
        end;
      end;
   except
   {$IFDEF FMX}
    if mainfrm.macrosLogChk.isChecked then
   {$ELSE ~FMX}
    if mainfrm.macrosLogChk.checked then
   {$ENDIF FMX}
      macrosLog(fullMacro, 'Exception, please report this bug on www.rejetto.com/forum/');
    result:='';
  end;
end; // cbMacros

function tryApplyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; var md:TmacroData; removeQuotings:boolean=true):boolean;
var
  s: string;
begin
  result := FALSE;

  try
    md.aliases := defaultAlias; // we don't even create a new object if not necessary
    if assigned(md.tpl) then
      begin
      s := md.tpl['special:alias'];
      if s > '' then
        begin
        md.aliases := THashedStringList.create;
        md.aliases.text:=s;
        md.aliases.addStrings(defaultAlias);
        end;
      end;

    if md.cd = NIL then
      begin
      md.tempVars := THashedStringList.create;
      end;

    md.logTS := TRUE;
    md.breaking := FALSE;

    try
      applyMacrosAndSymbols(fs, txt, cbMacros, @md, removeQuotings);
      result := TRUE;
     except
      on e:EtplError do
        mainFrm.setStatusBarText(format('Template error at %d,%d: %s: %s ...', [e.row,e.col,e.message,e.code]), 1000);
      on Exception do
        raise;
    end;
  finally
    if md.aliases <> defaultAlias then
      freeAndNIL(md.aliases);
    freeAndNIL(md.tempVars);
  end;
end; // tryApplyMacrosAndSymbols

function runScript(fs: TFileServer; const script: UnicodeString; table: TUnicodeStringDynArray=NIL; tpl_:Ttpl=NIL; f:Tfile=NIL; folder:Tfile=NIL; cd:TconnDataMain=NIL): UnicodeString;
var
  md: TmacroData;
begin
  result := trim(script);
  if result = '' then
    exit;
  ZeroMemory(@md, sizeOf(md));
  md.tpl := first(tpl_, fs.tpl);
  md.f:=f;
  md.folder:=folder;
  md.cd:=cd;
  md.table := toMSA(table);
  tryApplyMacrosAndSymbols(fs, result, md);
end; // runScript

function runEventScript(fs: TFileServer; const event:string; table: TUnicodeStringDynArray=NIL; cd:TconnDataMain=NIL):string;
begin
  addArray(table, ['%event%', event]);
  result := runScript(fs, eventScripts[event], table, eventScripts, NIL, NIL, cd);
end; // runEventScript

procedure runTimedEvents(fs: TFileServer);
var
  i: integer;
  sections: TStringDynArray;
  re: TRegExpr;
  t, last: Tdatetime;
  section: string;

  procedure handleAtCase();
  begin
    t := now();
    // we must convert the format, because our structure stores integers
    last := unixToDatetime(eventsLastRun.getInt(section));
    if (strToInt(re.match[9]) = hourOf(t))
    and (strtoInt(re.match[10]) = minuteOf(t))
    and (t-last > 0.9) then // approximately 1 day should have been passed
      begin
       eventsLastRun.setInt(section, datetimeToUnix(t));
       runEventScript(fs, section);
      end;
  end; // handleAtCase

  procedure handleEveryCase();
  begin
  // get the XX:YY:ZZ
  t:=strToFloat(re.match[2]);
  if re.match[4] > '' then
    t:=t*60+strToInt(re.match[4]);
  if re.match[6] > '' then
    t:=t*60+strToInt(re.match[6]);
  // apply optional time unit
  case upcase(getFirstChar(re.match[7])) of
    'M': t:=t*60;
    'H': t:=t*60*60;
    end;
  // now "t" is in seconds
  if (t > 0) and ((clock div 10) mod round(t) = 0) then
    runEventScript(fs, section);
  end; // handleEveryCase

begin
  if timedEventsRE = NIL then
   begin
    timedEventsRE:=TRegExpr.create; // yes, i know, this is never freed, but we need it for the whole time
    timedEventsRE.expression:='(every +([0-9.]+)(:(\d+)(:(\d+))?)? *([a-z]*))|(at (\d+):(\d+))';
    timedEventsRE.modifierI:=TRUE;
    timedEventsRE.compile();
   end;

  if eventsLastRun = NIL then
    eventsLastRun:=TstringToIntHash.create; // yes, i know, this is never freed, but we need it for the whole time

  re := timedEventsRE; // a shortcut
  sections := eventScripts.getSections();
  if length(sections) > 0 then
   for i:=0 to length(sections)-1 do
    begin
     section := sections[i]; // a shortcut
     if not re.exec(section) then
       continue;

      try
        if re.match[1] > '' then
          handleEveryCase()
         else
          handleAtCase();
       except
      end; // ignore exceptions
    end;
end; // runTimedEvents

procedure runTplImport(fs: TFileServer);
var
  f, fld: Tfile;
begin
  f := Tfile.create(fs, tplFilename);
  fld := Tfile.create(fs, extractFilePath(tplFilename));
  try
    runScript(fs, fs.tpl['special:import'], NIL, fs.tpl, f, fld);
   finally
    freeAndNIL(f);
    freeAndNIL(fld);
  end;
end; // runTplImport


initialization
  cachedTpls:=TcachedTpls.create();
  eventScripts:=Ttpl.create();
  defaultAlias := THashedStringList.create();
  defaultAlias.caseSensitive := FALSE;
  defaultAlias.text := UnUTF(getRes('alias'));
  staticVars := THashedStringList.create;
  currentCFGhashed:=THashedStringList.create();
  with staticVars do
    objects[add('ini='+currentCFG)]:=currentCFGhashed;

finalization
  freeAndNIL(cachedTpls);
  freeAndNIL(eventScripts);
  freeAndNIL(defaultAlias);
  freeAndNIL(currentCFGhashed);
  staticVars.free;

end.
