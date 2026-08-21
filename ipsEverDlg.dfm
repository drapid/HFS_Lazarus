object ipsEverFrm: TipsEverFrm
  Left = 0
  Height = 300
  Top = 0
  Width = 286
  BorderStyle = bsDialog
  Caption = 'Addresses ever connected'
  ClientHeight = 300
  ClientWidth = 286
  Color = clBtnFace
  Constraints.MaxHeight = 300
  Constraints.MinHeight = 300
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Position = poMainFormCenter
  LCLVersion = '4.8.0.0'
  OnShow = FormShow
  object totalLbl: TLabel
    Left = 197
    Height = 13
    Top = 246
    Width = 61
    Anchors = [akLeft]
    Caption = 'Total label...'
  end
  object ipsBox: TMemo
    Left = 0
    Height = 236
    Top = 0
    Width = 286
    Align = alTop
    Anchors = [akTop, akLeft, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object resetBtn: TButton
    Left = 114
    Height = 25
    Top = 241
    Width = 75
    Anchors = [akLeft]
    Caption = '&Reset'
    TabOrder = 1
    OnClick = resetBtnClick
  end
  object editBtn: TButton
    Left = 8
    Height = 25
    Top = 241
    Width = 95
    Anchors = [akLeft]
    Caption = '&Open in editor'
    TabOrder = 2
    OnClick = editBtnClick
  end
end
