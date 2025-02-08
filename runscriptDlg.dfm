object runScriptFrm: TrunScriptFrm
  Left = 0
  Height = 312
  Top = 0
  Width = 544
  Caption = 'Run script'
  ClientHeight = 312
  ClientWidth = 544
  Color = clBtnFace
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  LCLVersion = '3.0.0.3'
  object resultBox: TMemo
    Left = 0
    Height = 271
    Top = 41
    Width = 544
    Align = alClient
    Lines.Strings = (
      'Write your script in the external editor, then click Run.'
      'In this box will see the result of the script you run.'
    )
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Height = 41
    Top = 0
    Width = 544
    Align = alTop
    BevelOuter = bvNone
    ClientHeight = 41
    ClientWidth = 544
    ParentBackground = False
    TabOrder = 1
    object sizeLbl: TLabel
      Left = 503
      Height = 13
      Top = 24
      Width = 32
      Alignment = taRightJustify
      Caption = 'Size: 0'
    end
    object runBtn: TButton
      Left = 16
      Height = 25
      Top = 10
      Width = 75
      Caption = '&Run'
      TabOrder = 0
      OnClick = runBtnClick
    end
    object autorunChk: TCheckBox
      Left = 104
      Height = 17
      Top = 16
      Width = 138
      Caption = '&Auto run at every saving'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
  end
end
