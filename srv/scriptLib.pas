unit scriptLib;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}

interface

uses
  strutils, sysutils, classes, windows,
  srvClassesLib, srvConst,
  serverLib, fileLib, srvUtils;

type


  TPars = TPars2;

  EtplError = class(Exception)
    pos, row, col: integer;
    code: string;
    constructor Create(const msg, code: String; row, col: Integer);
   end;


const
  MARKER_OPEN = UnicodeString('{.');
  MARKER_CLOSE = UnicodeString('.}');
  MARKER_SEP = UnicodeString('|');
  MARKER_QUOTE = UnicodeString('{:');
  MARKER_UNQUOTE = UnicodeString(':}');
  MARKERS: array [0..4] of UnicodeString = ( MARKER_OPEN, MARKER_CLOSE, MARKER_SEP, MARKER_QUOTE, MARKER_UNQUOTE );
  ID2TAG_1Chars = [WideChar('{'), '.', ':'];

  AMARKER_OPEN = RawByteString('{.');
  AMARKER_CLOSE = RawByteString('.}');
  AMARKER_SEP = RawByteString('|');
  AMARKER_QUOTE = RawByteString('{:');
  AMARKER_UNQUOTE = RawByteString(':}');
  AMARKERS: array [0..4] of RawByteString = ( MARKER_OPEN, MARKER_CLOSE, MARKER_SEP, MARKER_QUOTE, MARKER_UNQUOTE );

function isAnyMacroIn(const s: RawByteString): Boolean; inline;
function anyMacroMarkerIn(const s: String): Boolean;
function findMacroMarker(const s: string; ofs:integer=1): integer;
procedure applyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; cb: TmacroCB; cbData: PMacroData; removeQuotings: Boolean=TRUE);

function macroQuote(s: UnicodeString): UnicodeString;
function macroDequote(s: UnicodeString): UnicodeString; OverLoad;
 {$IFNDEF UNICODE}
function macroDequote(s: String): String; OverLoad;
 {$ENDIF UNICODE}
function validUsername(const s: String; acceptEmpty: Boolean=FALSE): Boolean;

function tryApplyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; var md: TmacroData; removeQuotings: Boolean=true): Boolean;
function runScript(fs: TFileServer; const script: UnicodeString; table: TUnicodeStringDynArray=NIL; tpl_: Ttpl=NIL; f: Tfile=NIL; folder: Tfile=NIL; cd: TconnDataMain=NIL): UnicodeString;

const
  MAX_RECUR_LEVEL = 50;
type
  TparserIdsStack = array [1..MAX_RECUR_LEVEL] of UnicodeString;


procedure applyMacrosAndSymbols2(fs: TFileServer; var txt: UnicodeString; cb: TmacroCB; cbData: Pointer; var idsStack: TparserIdsStack; recurLevel: integer=0); Overload;
procedure applyMacrosAndSymbols2(fs: TFileServer; var pTxt: TFastUStringAppend; cb: TmacroCB; cbData: Pointer; var idsStack: TparserIdsStack; recurLevel: integer=0); OverLoad;

implementation
uses
  iniFiles, RDUtils,
  HSUtils;

var
  defaultAlias: THashedStringList;

constructor EtplError.create(const msg, code: String; row, col: Integer);
begin
  inherited create(msg);
  self.row := row;
  self.col := col;
  self.code := code;
end;

//procedure applyMacrosAndSymbols2(fs: TFileServer; var pTxt: UnicodeString; cb: TmacroCB; cbData: Pointer; var idsStack: TparserIdsStack; recurLevel: integer=0);
procedure applyMacrosAndSymbols2(fs: TFileServer; var pTxt: TFastUStringAppend; cb: TmacroCB; cbData: Pointer; var idsStack: TparserIdsStack; recurLevel: integer=0); OverLoad;
const
  // we don't track SEPs, they are handled just before the callback
  QUOTE_ID = 0;   // QUOTE must come before OPEN because it is a substring
  UNQUOTE_ID = 1;
  OPEN_ID = 2;
  CLOSE_ID = 3;
  MAX_MARKER_ID = 3;
 {$IFDEF FPC}
  function alreadyRecurredOn(const s: UnicodeString): Boolean; OverLoad;
  var
    i: integer;
  begin
    //result := TRUE;
    if recurLevel > 1 then
      for i:=recurLevel downto 1 do
        if UnicodeSameText(s, idsStack[i]) then
          exit(True);
    result:=FALSE;
  end; // alreadyRecurredOn
 {$ENDIF FPC}

  function alreadyRecurredOn(const s: String): Boolean; OverLoad;
  var
    i: integer;
  begin
    //result := TRUE;
    if recurLevel > 1 then
      for i:=recurLevel downto 1 do
        if sameText(s, idsStack[i]) then
          exit(True);
    result:=FALSE;
  end; // alreadyRecurredOn

  procedure handleSymbols();
  var
    b, e, l : integer;
    s, newS: UnicodeString;
    ch1: UnicodeChar;
  begin
    e := 0;
    l := pTxt.Length;
    while e < l do
    begin
    // search for next symbol
      b := pTxt.posex(UnicodeString('%'), e+1);
      if b = 0 then
        break;
      e := b+1;
      ch1 := pTxt[e];
      if ch1 = '%' then
      begin    // we don't accept %% as a symbol. so, restart parsing from the second %
        e := b;
        continue;
      end;
      //if not (ch1 in ['_','a'..'z','A'..'Z']) then
      if not CharInSet(ch1, ['_','a'..'z','A'..'Z']) then
        continue; // first valid character
      //while (e < l) and (pTxt[e] in ['0'..'9','a'..'z','A'..'Z','-','_']) do
      while (e < l) and CharInSet(pTxt[e], ['0'..'9','a'..'z','A'..'Z','-','_']) do
        inc(e);
      if pTxt[e] <> '%' then
        continue;
      // found!
//      s := substr(pTxt, b, e);
      s := pTxt.substr(b, e);
      if alreadyRecurredOn(s) then
        continue; // the user probably didn't meant to create an infinite loop

      newS := cb(fs, s, NIL, cbData);
      if s = newS then
        continue;

      idsStack[recurLevel] := s; // keep track of what we recur on
      // apply translation, and eventually recur
      try
        applyMacrosAndSymbols2(fs, newS, cb, cbData, idsStack, recurLevel);
       except
      end;
      idsStack[recurLevel] := '';
      inc(e, pTxt.replace(newS, b, e));
      l := pTxt.Length;
    end;
  end; // handleSymbols

  procedure handleMacros();
  var
    pars: TPars;

    function expand(from, to_: Integer): Integer;
    var
      s, eFullMacro: UnicodeString;
      i, o, q, u: integer;
    begin
      result:=0;
      eFullMacro := pTxt.substr(from+length(MARKER_OPEN), to_-length(MARKER_CLOSE));
      if alreadyRecurredOn(eFullMacro) then
        exit; // the user probably didn't meant to create an infinite loop

    // let's find the SEPs to build 'pars'
      pars.clear();
      i := 1; // char pointer from where we shall copy the macro parameter
      o := 0;
      q := posEx(MARKER_QUOTE, eFullMacro); // q points to _QUOTE
      repeat
        o := posEx(MARKER_SEP, eFullMacro, o+1);
        if o = 0 then
          break;
        if (q > 0) and (q < o) then // this SEP is possibly quoted
        begin
        // update 'q' and 'u'
          repeat
          u := posEx(MARKER_UNQUOTE, eFullMacro, q);
          if u = 0 then
            exit; // macro quoting not properly closed
          q:=posEx(MARKER_QUOTE, eFullMacro, q+1); // update q for next cycle
          // if we find other _QUOTEs before _UNQUOTE, then they are stacked, and we must go through the same number of both markers
          while (q > 0) and (q < u) do
            begin
              u := posEx(MARKER_UNQUOTE, eFullMacro, u+1);
              if u = 0 then
                exit; // macro quoting not properly closed
              q := posEx(MARKER_QUOTE, eFullMacro, q+1);
            end;
          until (q = 0) or (o < q);
        // eventually skip this chunk of string
        if o < u then
          begin // yes, this SEP is quoted
          o:=u;
          continue;
          end;
        end;
        // ok, that's a valid SEP, so we collect this as a parameter
        pars.add(substr(eFullMacro, i, o-1));
        i:=o+length(MARKER_SEP);
      until false;
      pars.add(substr(eFullMacro, i, length(eFullMacro))); // last piece
      // ok, 'pars' has now been built

      // do the call, recur, and replace with the result
      s := cb(fs, eFullMacro, pars, cbData);
      idsStack[recurLevel] := eFullMacro; // keep track of what we recur on
      if s > '' then
      try
        try
          applyMacrosAndSymbols2(fs, s, cb, cbData, idsStack, recurLevel)
         except
        end;
       finally
        idsStack[recurLevel]:=''
      end;
      result := pTxt.replace(s, from, to_);
    end; // expand

  const
    //ID2TAG: array [0..MAX_MARKER_ID] of string = (MARKER_QUOTE, MARKER_UNQUOTE, MARKER_OPEN, MARKER_CLOSE);
    ID2TAGU: array [0..MAX_MARKER_ID] of UnicodeString = (MARKER_QUOTE, MARKER_UNQUOTE, MARKER_OPEN, MARKER_CLOSE);
  type
    TstackItem = record
      pos: integer;
      row, col: word;
      quote: boolean;
     end;
  var
    i, lastNL, row, m, t: integer;
    stack: array of TstackItem;
    Nstack: integer;
   {$IFDEF FPC}
    ch: UnicodeChar;
   {$ELSE}
    ch: Char;
   {$ENDIF FPC}
   i2: Integer;
  begin
    if pTxt.Length > 0 then
    begin
      setLength(stack, pTxt.Length div length(MARKER_OPEN)); // it will never need more than this
      Nstack:=0;
      pars := TPars.Create;
      try
        i:=1;
        row:=1;
        lastNL:=0;
        while i <= pTxt.Length do
          begin
            ch := pTxt[i];
            if ch = #10 then
             begin
              inc(row);
              lastNL := i;
             end;
            //if not (ch in ID2TAG_1Chars) then
            if not CharInSet(ch, ID2TAG_1Chars) then
              begin
                Inc(i);
                Continue;
              end;
            i2 := 0;
            for m:=0 to MAX_MARKER_ID do
              begin
              if not pTxt.strAt(ID2TAGU[m], i) then
                continue;
              i2 := Length(ID2TAGU[m]) - 1;
              case m of
                QUOTE_ID,
                OPEN_ID:
                  begin
                    if (m = OPEN_ID) and (Nstack > 0) and stack[Nstack-1].quote then
                      continue; // don't consider quoted OPEN markers
                    stack[Nstack].pos := i;
                    stack[Nstack].quote := m=QUOTE_ID;
                    stack[Nstack].row := row;
                    stack[Nstack].col := i-lastNL;
                    inc(Nstack);
                  end;
                CLOSE_ID:
                  begin
                    if Nstack = 0 then
                      raise EtplError.create('unmatched marker', pTxt.SubStr(i, i+30), row, i-lastNL);
                    if (Nstack > 0) and stack[Nstack-1].quote then
                      continue; // don't consider quoted CLOSE markers
                    t := length(MARKER_CLOSE);
                    i2 := 0;
                    inc(i, t-1+expand(stack[Nstack-1].pos, i+t-1));
                    dec(Nstack);
                  end;
                UNQUOTE_ID:
                  begin
                    if (Nstack = 0) or not stack[Nstack-1].quote then
                      continue;
                    dec(Nstack);
                  end;
                end;
              end;//for
            inc(i);
            inc(i, i2);
          end;
       finally
        pars.free
      end;
      if Nstack > 0 then
        with stack[Nstack-1] do
          raise EtplError.create('unmatched marker', pTxt.SubStr(pos, pos+30), row, col)
    end;
  end; // handleMacros

begin
  if recurLevel > MAX_RECUR_LEVEL then
    exit;
  inc(recurLevel);
  handleSymbols();
  handleMacros();
end; //applyMacrosAndSymbols2


procedure applyMacrosAndSymbols2(fs: TFileServer; var txt: UnicodeString; cb: TmacroCB; cbData: Pointer; var idsStack: TparserIdsStack; recurLevel: integer=0); OverLoad;
var
  tb: TFastUStringAppend;
begin
  tb := TFastUStringAppend.Create(txt);
  try
    applyMacrosAndSymbols2(fs, tb, cb, cbData, idsStack, recurLevel);
   finally
    txt := tb.get(True);
    tb.Free;
    tb := NIL;
  end;
end;


procedure applyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; cb: TmacroCB; cbData: PMacroData; removeQuotings: Boolean=TRUE);
var
  idsStack: TparserIdsStack;
begin
  enforceNUL(txt);
  applyMacrosAndSymbols2(fs, txt, cb, cbData, idsStack);
  if removeQuotings then
    txt := xtpl(txt, [MARKER_QUOTE, '', MARKER_UNQUOTE, ''])
end;

function findMacroMarker(const s: String; ofs: Integer=1): Integer;
begin
  result := reMatch(s, '\{[.:]|[.:]\}|\|', 'm!', ofs)
end;

function isAnyMacroIn(const s: RawByteString): Boolean; inline;
begin
  result := pos(AMARKER_OPEN, s) > 0
end;

function anyMacroMarkerIn(const s: String): Boolean;
begin
  result:=findMacroMarker(s) > 0
end;
 {$IFDEF FPC}
function isMacroQuoted(const s: UnicodeString): Boolean; OverLoad;
begin
  result := AnsiStartsStr(MARKER_QUOTE, s) and ansiEndsStr(MARKER_UNQUOTE, s)
end; //?????
 {$ENDIF FPC}

function isMacroQuoted(const s: String): Boolean; OverLoad;
begin
  result:=ansiStartsStr(MARKER_QUOTE, s) and ansiEndsStr(MARKER_UNQUOTE, s)
end;

function macroQuote(s: UnicodeString): UnicodeString;
var
  t: UnicodeString;
begin
  if s='' then
    Exit('');
  enforceNUL(s);
  if not anyMacroMarkerIn(s) then
   begin
    result := s;
    exit;
   end;
// an UNQUOTE would invalidate our quoting, so let's encode any of it
  t := MARKER_UNQUOTE;
  replace(t, '&#'+intToStr(charToUnicode(t[1]))+';', 1,1);
  result := MARKER_QUOTE+xtpl(s, [MARKER_UNQUOTE, t])+MARKER_UNQUOTE
end; // macroQuote

function macroDequote(s: UnicodeString): UnicodeString;
begin
  result := s;
  s := trim(s);
  if isMacroQuoted(s) then
    result := copy(s, length(MARKER_QUOTE)+1, length(s)-length(MARKER_QUOTE)-length(MARKER_UNQUOTE) );
end; // macroDequote

 {$IFNDEF UNICODE}
function macroDequote(s: String): String;
begin
  result:=s;
  s:=trim(s);
  if isMacroQuoted(s) then
    result:=copy(s, length(MARKER_QUOTE)+1, length(s)-length(MARKER_QUOTE)-length(MARKER_UNQUOTE) );
end; // macroDequote
 {$ENDIF UNICODE}

function validUsername(const s: String; acceptEmpty: Boolean=FALSE): Boolean;
begin
  result := (s = '') and acceptEmpty
    or (s > '') and not anyCharIn('/\:?*"<>|;&',s) and (length(s) <= 40)
    and not anyMacroMarkerIn(s) // mod by mars
end;

function tryApplyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; var md: TmacroData; removeQuotings: Boolean=true): Boolean;
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
      applyMacrosAndSymbols(fs, txt, fs.MainMacroFunc, @md, removeQuotings);
      result := TRUE;
     except
      on e:EtplError do
        fs.setStatusBarText(format('Template error at %d,%d: %s: %s ...', [e.row,e.col,e.message,e.code]), 1000);
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

initialization
  defaultAlias := THashedStringList.create();
  defaultAlias.caseSensitive := FALSE;
  defaultAlias.text := UnUTF(getRes('alias'));


finalization
  freeAndNIL(defaultAlias);

end.
