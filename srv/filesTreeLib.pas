{$INCLUDE defs.inc }
unit filesTreeLib;
{$I NoRTTI.inc}

interface
uses
  Windows, SysUtils, Graphics, SyncObjs,
//  hsLib,
 {$IFDEF FMX}
  FMX.TreeView,
 {$ELSE ~FMX}
 {$IFDEF USE_VTV}
  VirtualTrees.Types, VirtualTrees.DrawTree,
 {$ELSE ~USE_VTV}
  ComCtrls,
 {$ENDIF ~USE_VTV}
 {$ENDIF FMX}
  //fileLib,
  srvConst;

type
 {$IFDEF FMX}
  TFileTree = TTreeView;
  TFileNode = TTreeViewItem;
 {$ELSE ~FMX}
 {$IFDEF USE_VTV}
  TFileTree = TVirtualDrawTree;
  TFileNode = PVirtualNode;
 {$ELSE ~USE_VTV}
  TFileTree = TTreeView;
  TFileNode = TTreeNode;
 {$ENDIF ~USE_VTV}
 {$ENDIF FMX}
  TFileNodeDynArray = array of TFileNode;


  TFileNodeHelper = class helper for TFileNode
    procedure clearNode;
    function  getParentNode: TFileNode;
    function  hasChildren: Boolean;
    function  firstChild: TFileNode;
    function  nextSibling: TFileNode;
    function  findSubNode(nText: String): TFileNode;
    function  hasFile: Boolean;
    function  nodeText: String;
    function  nodeToFile: TObject; inline;
    procedure DoImageChanged(pImageIndex: Integer);
    procedure changeName(pName: String);
    procedure DeleteNode;
    procedure ExpandNode;
  end;

  TFileTreeHelper = class helper for TFileTree
    procedure Clear;
    procedure ClearRoot;
    function  itemsCount: Integer;
    function  GetFirstNode: TFileNode;
    function  findFilesNode(pFile: TObject): TFileNode;
  end;

implementation
uses
  DateUtils
//  srvUtils, RDUtils, srvVars
  ;

procedure TFileTreeHelper.Clear();
begin
  Self.Items.Clear;
end;


procedure TFileTreeHelper.ClearRoot();
begin
  Self.Items.Clear;
end;

function TFileTreeHelper.itemsCount: Integer;
begin
  Result := Self.Items.Count;
end;

function TFileTreeHelper.GetFirstNode: TFileNode;
begin
  if Items.Count > 0 then
    Result := Items[0]
   else
    Result := NIL;
end;

function TFileTreeHelper.findFilesNode(pFile: TObject): TFileNode;
var
  n: TFileNode;
begin
  {$IFDEF FMX}
   for var i := 0 to Self.Count-1 do
    begin
     n := Self.Items[i];
     if n.Data.AsObject = pFile then
       Exit(n);
    end;
  {$ELSE ~FMX}
   {$IFDEF USE_VTV}
   for var n in Self.Nodes() do
     if n.GetData<Tfile> = pFile then
       Exit(n);
   {$ELSE ~USE_VTV}
   if Self.Items.Count > 0 then
     for n in Self.Items do
       if n.Data = pFile then
         Exit(n);
   {$ENDIF ~USE_VTV}
  {$ENDIF FMX}
   Result := NIL;
end;

procedure TFileNodeHelper.clearNode;
begin
  {$IFDEF FMX}
     Self.Free;
  {$ELSE ~FMX}
    begin
    {$IFDEF USE_VTV}
      fMainTree.DeleteNode(n);
    {$ELSE ~USE_VTV}
      Self.Data := NIL;
      Self.Delete();
    {$ENDIF ~USE_VTV}
    end;
  {$ENDIF FMX}
end;

function TFileNodeHelper.getParentNode: TFileNode;
begin
  {$IFDEF FMX}
   Result := Self.ParentItem;
  {$ELSE ~FMX}
   {$IFDEF USE_VTV}
    Result := Self.parent;
   {$ELSE ~USE_VTV}
    Result := Self.parent;
   {$ENDIF ~USE_VTV}
  {$ENDIF FMX}
end;

function TFileNodeHelper.hasChildren: Boolean;
begin
  {$IFDEF USE_VTV}
  Result := Self.ChildCount > 0;
  {$ELSE ~USE_VTV}
  Result := Self.Count > 0;
  {$ENDIF ~USE_VTV}
end;


function TFileNodeHelper.firstChild: TFileNode;
begin
  {$IFDEF FMX}
   begin
     if Self.Count > 0 then
       Result := Self.Items[0]
      else
       Result := NIL;
   end
  {$ELSE ~FMX}
    {$IFDEF USE_VTV}
         Result := Self.FirstChild
    {$ELSE ~USE_VTV}
         Result := Self.getFirstChild
    {$ENDIF ~USE_VTV}
  {$ENDIF FMX}
end;

function TFileNodeHelper.nextSibling: TFileNode;
{$IFDEF FMX}
var
  p, next: TFileNode;
  i: Integer;
{$ENDIF FMX}
begin
 {$IFDEF FMX}
  p := Self.ParentItem;
  i := Self.Index + 1;
  next := p.ItemByIndex(i);
  while Assigned(next) and not next.Visible do
    begin
      inc(i);
      next := p.ItemByIndex(i);
    end;
  Result := next
 {$ELSE ~FMX}
  {$IFDEF USE_VTV}
  Result := Self.NextSibling;
  {$ELSE ~USE_VTV}
  Result := Self.getNextSibling();
  {$ENDIF ~USE_VTV}
 {$ENDIF FMX}
end;

function TFileNodeHelper.nodeToFile: TObject; inline;
begin
  if Self = NIL then
   result := NIL
  else
  {$IFDEF FMX}
    if not Self.Data.IsEmpty then
      result := Tfile(Self.data.AsObject)
     else
      result := NIL;
  {$ELSE ~FMX}
     {$IFDEF USE_VTV}
        result := Self.GetData<TFile>
     {$ELSE ~USE_VTV}
        result := Self.data
     {$ENDIF ~USE_VTV}
  {$ENDIF FMX}
end;

function TFileNodeHelper.hasFile: Boolean;
begin
  {$IFDEF FMX}
  Result := Assigned(Self) and Self.data.IsObject;
  {$ELSE ~FMX}
   {$IFDEF USE_VTV}
   Result := Assigned(Self) and (Self.GetData <> NIL);
   {$ELSE ~USE_VTV}
   Result := Assigned(Self) and assigned(Self.Data);
   {$ENDIF ~USE_VTV}
  {$ENDIF FMX}
end;

function TFileNodeHelper.nodeText: String;
begin
  if Self = NIL then
   result := ''
  else
  {$IFDEF FMX}
   result := Tfile(Self.data.AsObject).name;
  {$ELSE ~FMX}
     {$IFDEF USE_VTV}
   result := Self.GetData<TFile>.name
     {$ELSE ~USE_VTV}
   result := Self.Text
     {$ENDIF ~USE_VTV}
  {$ENDIF FMX}
end;

function TFileNodeHelper.findSubNode(nText: String): TFileNode;
var
  n: TFileNode;
  found: Boolean;
begin
  found := False;
  {$IFDEF FMX}
   if Self.Count > 0 then
    for var ii in [0..(Self.count-1)] do
     begin
       n := Self.Items[ii];
 //    found:=stringExists(n.text, s) or sameText(n.text, UTF8toAnsi(s));
 //        found := stringExists(n.text, s) or sameText(n.text, s);
       found := sameText(n.text, nText);
       if found then
         break;
     end;
  {$ELSE ~FMX}
   n := Self.firstChild();
   while assigned(n) do
   begin
//    found := stringExists(n.text, s) or sameText(n.text, UTF8toAnsi(s));
//        found := stringExists(n.text, s) or sameText(n.text, s);
     found := sameText(n.nodetext, nText);
   if found then
     break;
   n := n.NextSibling;
   end;
  {$ENDIF FMX}
  if found then
    Result := n
   else
    Result := NIL;
end;

procedure TFileNodeHelper.DoImageChanged(pImageIndex: Integer);
begin
{$IFNDEF NO_GUI}
  {$IFNDEF FMX}
  if Assigned(Self) then
  {$IFDEF USE_VTV}
    fMainTree.InvalidateNode(Self);
  {$ELSE ~USE_VTV}
  Self.Imageindex := pImageIndex;
  Self.SelectedIndex := pImageIndex;
  {$ENDIF ~USE_VTV}
  {$ENDIF ~FMX}
{$ENDIF NO_GUI}
end;

procedure TFileNodeHelper.changeName(pName: String);
begin
  if Assigned(Self) then
    begin
  {$IFDEF USE_VTV}
      fMainTree.InvalidateNode(Self);
  {$ELSE ~USE_VTV}
      Self.Text := pName;
  {$ENDIF ~USE_VTV}
    end;
end;

procedure TFileNodeHelper.DeleteNode;
begin
  {$IFDEF FMX}
     Self.Free;
  {$ELSE ~FMX}
    {$IFDEF USE_VTV}
     mainTree.DeleteNode(Self);
    {$ELSE ~USE_VTV}
     Self.Delete();
    {$ENDIF ~USE_VTV}
  {$ENDIF FMX}
end;

procedure TFileNodeHelper.ExpandNode;
begin
  if Assigned(Self) then
  {$IFDEF USE_VTV}
    mainTree.Expanded[Self] := true;
  {$ELSE ~USE_VTV}
    {$IFDEF FMX}
     Self.Expand;
    {$ELSE ~FMX}
     Self.expanded := TRUE;
    {$ENDIF ~FMX}
  {$ENDIF ~USE_VTV}
end;

end.
