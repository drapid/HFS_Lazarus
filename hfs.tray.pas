unit HFS.Tray;
{$I NoRTTI.inc}

interface

uses
  Windows,
 {$IFDEF FPC}
  RnQGraphics32,
  SysUtils, Classes, Graphics,
  ImgList,
  IntfGraphics,
 {$ELSE}
  System.SysUtils, System.Classes, System.ImageList,
 {$IFDEF FMX}
  FMX.Graphics, System.UITypes, System.Types,
  FMX.ImgList, FMX.Types
 {$ELSE ~FMX}
  Graphics, Vcl.ImgList,
  Vcl.BaseImageCollection, Vcl.ImageCollection,
  Vcl.Imaging.pngImage,
  Vcl.VirtualImageList,
 {$ENDIF FMX}
 {$ENDIF FPC}
  Controls, CommCtrl
  ;
const
  iconsBaseSize = 16;
type
  TIconParams = record
    isActive: Boolean;
    perc: real;
    size: Integer;
    str: String;
  end;

  procedure drawTrayIconNumber(cnv: TCanvas; const s: String; size: Integer = iconsBaseSize); OverLoad;
  procedure drawTrayIconNumber(cnv: TCanvas; const n: Integer; size: Integer = iconsBaseSize); OverLoad;
  function  getBaseTrayIcon(isSrvActive: Boolean; perc: real=0; size: Integer = iconsBaseSize): TBitmap;
  function  setTrayIcon(var ti: TIcon; const prevParams: TIconParams; params: TIconParams): Boolean; OverLoad;
  procedure setTrayIcon(var ti: TIcon; isSrvActive: Boolean; perc: real=0; size: Integer = iconsBaseSize; str: String = ''); OverLoad;

var
  {$IFDEF FMX}
  tray_ico: TBitmap;           // the actual icon shown in tray
  {$ELSE ~FMX}
  tray_ico: Ticon;             // the actual icon shown in tray
  {$ENDIF FMX}
  main_ico_params: TIconParams;

implementation

uses
 {$IFDEF UNICODE}
   AnsiClasses, ansiStrings,
 {$ENDIF UNICODE}
 {$IFDEF FPC}
   LazCanvas, GraphType,
 {$ELSE ~FPC}
   WinApi.ShellAPI,
 {$ENDIF ~FPC}
//   utilLib,
  RDUtils,
 {$IFDEF FMX}
   iconsFMXLib,
 {$ELSE ~FMX}
   iconsLib,
 {$ENDIF FMX}
   srvVars, srvUtils;

{$IFNDEF FPC}
var
  numbers: TBitmap;
{$ENDIF ~FPC}

function getBaseTrayIcon(isSrvActive: Boolean; perc: real=0; size: Integer = iconsBaseSize): TBitmap;
var
  x: integer;
  h, h2: Integer;
begin
 {$IFDEF FMX}
  Result := IconsDM.Images.Bitmap(tsizef.Create(size, size), if_(isSrvActive, 24, 30));
 {$ELSE ~FMX}
  Result := IconsDM.GetBitmap( if_(isSrvActive, 24, 30), size);
 {$ENDIF ~FMX}
  if perc > 0 then
    begin
      h := Result.Height;
      x := round((h-2)*perc);
      h2 := h div 2 + 1;
 {$IFDEF FMX}
      result.canvas.fill.Color := TColorRec.Yellow;
      result.Canvas.FillRect(TRectF.Create(1, h2, x+1, h-1), 1);
      result.canvas.fill.Color := TColorRec.Green;
      result.Canvas.FillRect(TRectF.Create(x+1,h2,h-1, h-1), 1);
 {$ELSE ~FMX}
      result.canvas.Brush.color := clYellow;
      result.Canvas.FillRect(rect(1, h2, x+1, h-1));
      result.canvas.Brush.color := clGreen;
      result.Canvas.FillRect(rect(x+1,h2,h-1, h-1));
 {$ENDIF ~FMX}
    end;
end; // getBaseTrayIcon

procedure drawTrayIconNumber(cnv: TCanvas; const n: Integer; size: Integer = iconsBaseSize);
begin
  drawTrayIconNumber(cnv, intToStr(n), size);
end;

{$IFNDEF FPC}
procedure drawTrayIconNumber(cnv: TCanvas; const s: String; size: Integer = iconsBaseSize);

var
  w, h, idx: integer;
  dx, dy, dw, dh: Integer;
 {$IFNDEF FMX}
  blend: BLENDFUNCTION;
  MaskDC: HDC;
  Save: THandle;
 {$ENDIF ~FMX}
begin
  if length(s) > 0 then
   begin
    dx := 10;
    dy := 8;
    w := numbers.Width div 11;
    h := numbers.Height;
    dx := MulDiv(dx, size, iconsBaseSize);
    dy := MulDiv(dy, size, iconsBaseSize);
    dw := MulDiv(4, size, iconsBaseSize);
    dh := MulDiv(6, size, iconsBaseSize);
    for var i:=length(s) downto 1 do
     begin
      if s[i] = '%' then
        idx:=10
       else
        idx:=ord(s[i])-ord('0');
 {$IFDEF FMX}
      cnv.DrawBitmap(numbers, TRectF.Create(TPointF.Create(idx*w, 0), w, h),
             TRectF.Create(TPointF.Create(dx, dy), dw, dh), 1);
 {$ELSE ~FMX}
      if numbers.Transparent then
      begin
        Save := 0;
        MaskDC := 0;
        try
          MaskDC := CreateCompatibleDC(0);
          Save := SelectObject(MaskDC, numbers.MaskHandle);
          TransparentStretchBlt(cnv.Handle, dx, dy, dw, dh, numbers.Canvas.Handle, idx*w, 0, w, h, MaskDC, idx*w, 0);
        finally
          if Save <> 0 then SelectObject(MaskDC, Save);
          if MaskDC <> 0 then DeleteDC(MaskDC);
        end;
      end
      else
    {$IFDEF FPC}
        if numbers.PixelFormat = pf32bit then
    {$ELSE ~FPC}
        if numbers.SupportsPartialTransparency then
    {$ENDIF FPC}
        begin
          blend.AlphaFormat         := AC_SRC_ALPHA
  //       else
  //        blend.AlphaFormat         := AC_SRC_OVER
          ;
           blend.BlendOp             := AC_SRC_OVER;
           blend.BlendFlags          := 0;
           blend.SourceConstantAlpha := $FF;
          AlphaBlend(cnv.Handle, dx, dy, dw, dh, numbers.Canvas.Handle,
                     idx*w, 0, w, h, blend);
        end
       else
      TransparentBlt(cnv.Handle, dx, dy, dw, dh, numbers.Canvas.Handle, idx*w, 0, w, h, $FF00FF);
 {$ENDIF ~FMX}
      dec(dx, dw);
     end;
   end;
end; // drawTrayIconString

{$ELSE FPC}
(*
procedure drawTrayIconNumber(img: TLazIntfImage; const s: String; size: Integer = iconsBaseSize);

var
  cnv: TLazCanvas;
  ni: TLazIntfImage;
  w, h, idx: integer;
  dx, dy, dw, dh: Integer;
  rin: TRawImage;
  i: Integer;
begin
  if length(s) > 0 then
   begin
    dx := 10;
    dy := 8;
    w := numbers.Width div 11;
    h := numbers.Height;
    dx := MulDiv(dx, size, iconsBaseSize);
    dy := MulDiv(dy, size, iconsBaseSize);
    dw := MulDiv(4, size, iconsBaseSize);
    dh := MulDiv(6, size, iconsBaseSize);
    cnv := TLazCanvas.create(img);
    for i:=length(s) downto 1 do
     begin
      if s[i] = '%' then
        idx:=10
       else
        idx:=ord(s[i])-ord('0');
      numbers.RawImage.ExtractRect(TRect.Create(Point(idx*w, 0), w, h), rin);
      ni := TLazIntfImage.Create(rin, True);
      cnv.StretchDraw(dx, dy, dw, dh, ni);
      ni.free;
      dec(dx, dw);
     end;
    cnv.free;
   end;
end; // drawTrayIconString
*)
procedure drawTrayIconNumber(cnv: TCanvas; const s: String; size: Integer = iconsBaseSize);

var
  w, h, idx: integer;
  dx, dy, dw, dh: Integer;
  i: Integer;
begin
  if length(s) > 0 then
   begin
    dx := 10;
    dy := 8;
    w := iconsLib.IconsDM.numbers.Width div 11;
    h := iconsLib.IconsDM.numbers.Height;
    dx := MulDiv(dx, size, iconsBaseSize);
    dy := MulDiv(dy, size, iconsBaseSize);
    dw := MulDiv(4, size, iconsBaseSize);
    dh := MulDiv(6, size, iconsBaseSize);
    for i:=length(s) downto 1 do
     begin
      if s[i] = '%' then
        idx:=10
       else
        idx:=ord(s[i])-ord('0');
      if size = iconsBaseSize then
        iconsLib.IconsDM.numbers.Draw(cnv, dx, dy, idx)
       else
        iconsLib.IconsDM.numbers.StretchDraw(cnv, idx, TRect.Create(Point(dx, dy), dw, dh));
      dec(dx, dw);
     end;
   end;
end; // drawTrayIconString
{$ENDIF FPC}

procedure setTrayIcon(var ti: TIcon; isSrvActive: Boolean; perc: real=0; size: Integer = iconsBaseSize; str: String = '');
var
  bmp: Tbitmap;
  xx: Integer;
begin
 {$IFDEF FPC}
  ti.Clear;
  for xx in [16, 32] do
 {$ELSE ~FPC}
  xx := size;
 {$ENDIF FPC}
  begin
    bmp := getBaseTrayIcon(isSrvActive, perc, xx);
    if str <> '' then
     begin
      drawTrayIconNumber(bmp.canvas, str, size);
     end;
  //  data.tray_ico.Handle := bmpToHico(bmp);
    //ti.Handle := bmp2ico32(bmp);
    {$IFDEF FPC}
    ti.Add(bmp.PixelFormat, xx, xx);
    //tray_ico.Add(pf32bit, bmp.Height, bmp.Width);
    ti.Current := ti.Count-1;
    ti.AssignImage(bmp);
    {$ELSE ~FPC}
    ti.Handle := bmp2ico32(bmp);
    //tray_ico.Handle := bmp2ico4M(bmp);
    {$ENDIF FPC}
    bmp.free;
  end;
 {$IFDEF FPC}
  ti.Current := ti.GetBestIndexForSize(TSize.Create(Size, Size));
 {$ENDIF FPC}
end;

function setTrayIcon(var ti: TIcon; const prevParams: TIconParams; params: TIconParams): Boolean;
begin
  if (prevParams.isActive = params.isActive) and
     (prevParams.perc = params.perc) and
     (prevParams.size = params.size) and
     (prevParams.str = params.str)
   then
   Exit(false);

   setTrayIcon(ti, params.isActive, params.perc, params.size, params.str);
//  prevParams.isActive := params.isActive;
//  prevParams.perc := params.perc;
//  prevParams.size := params.size;
//  prevParams.str  := params.str;
  Result := True;
end;

{$IFNDEF FPC}

INITIALIZATION
var
  snum: RawByteString;
begin
  snum := getRes('NUMBERS32', 'IMAGE');
  if snum = '' then
    snum := getRes('NUMBERS', 'IMAGE');
  numbers := stringPNG2BMP(snum);
  snum := '';
end;
{$ENDIF ~FPC}

end.
