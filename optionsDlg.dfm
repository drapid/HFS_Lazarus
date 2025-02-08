object optionsFrm: ToptionsFrm
  Left = 287
  Height = 449
  Top = 162
  Width = 805
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Options'
  ClientHeight = 449
  ClientWidth = 805
  Color = clBtnFace
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  Position = poMainFormCenter
  LCLVersion = '3.0.0.3'
  object pageCtrl: TPageControl
    Left = 0
    Height = 414
    Top = 0
    Width = 805
    ActivePage = bansPage
    Align = alClient
    MultiLine = True
    TabIndex = 0
    TabOrder = 0
    Options = [nboMultiLine]
    object bansPage: TTabSheet
      Caption = 'Bans'
      ClientHeight = 388
      ClientWidth = 797
      ImageIndex = 25
      object Panel1: TPanel
        Left = 0
        Height = 30
        Top = 0
        Width = 797
        Align = alTop
        BevelOuter = bvNone
        ClientHeight = 30
        ClientWidth = 797
        ParentBackground = False
        TabOrder = 0
        object addBtn: TButton
          Left = 4
          Height = 21
          Top = 5
          Width = 73
          Caption = 'Add row'
          TabOrder = 0
          OnClick = addBtnClick
        end
        object deleteBtn: TButton
          Left = 86
          Height = 21
          Top = 5
          Width = 73
          Caption = 'Delete row'
          TabOrder = 1
          OnClick = deleteBtnClick
        end
        object sortBanBtn: TButton
          Left = 168
          Height = 21
          Top = 5
          Width = 73
          Caption = 'Sort'
          TabOrder = 2
          OnClick = sortBanBtnClick
        end
      end
      object bansBox: TValueListEditor
        Left = 0
        Height = 332
        Top = 30
        Width = 797
        Align = alClient
        FixedCols = 0
        RowCount = 2
        TabOrder = 1
        KeyOptions = [keyEdit, keyAdd, keyDelete]
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goAutoAddRows, goAlwaysShowEditor, goThumbTracking]
        Strings.Strings = (
          '='
        )
        TitleCaptions.Strings = (
          'IP address mask'
          'Comment'
        )
        ColWidths = (
          108
          685
        )
      end
      object Panel3: TPanel
        Left = 0
        Height = 26
        Top = 362
        Width = 797
        Align = alBottom
        BevelOuter = bvNone
        ClientHeight = 26
        ClientWidth = 797
        ParentBackground = False
        TabOrder = 2
        object noreplybanChk: TCheckBox
          Left = 5
          Height = 17
          Top = 5
          Width = 134
          Caption = 'Disconnect with no reply'
          TabOrder = 0
        end
        object Button1: TButton
          Left = 176
          Height = 19
          Top = 4
          Width = 141
          Caption = 'How to invert the logic?'
          TabOrder = 1
          OnClick = Button1Click
        end
      end
    end
    object accountsPage: TTabSheet
      Caption = 'Accounts'
      ClientHeight = 388
      ClientWidth = 797
      ImageIndex = 29
      object Label1: TLabel
        Left = 9
        Height = 13
        Top = 16
        Width = 55
        Caption = 'Account list'
        FocusControl = accountsBox
      end
      object Label7: TLabel
        Left = 251
        Height = 13
        Hint = 'You also need to right click on the folder, then restrict access'
        Top = 323
        Width = 325
        Anchors = [akLeft, akBottom]
        Caption = 'WARNING: creating an account is not enough to protect  your files...'
        ParentShowHint = False
        ShowHint = True
        WordWrap = True
      end
      object accountpropGrp: TGroupBox
        Left = 163
        Height = 291
        Top = 26
        Width = 611
        Anchors = [akTop, akLeft, akRight, akBottom]
        Caption = 'Account properties'
        ClientHeight = 273
        ClientWidth = 607
        ParentBackground = False
        TabOrder = 7
        object Label3: TLabel
          Left = 11
          Height = 13
          Top = 173
          Width = 290
          Caption = 'Here you can see protected resources this user can access...'
          FocusControl = accountAccessBox
          WordWrap = True
        end
        object Label8: TLabel
          Left = 336
          Height = 13
          Top = 20
          Width = 28
          Caption = 'Notes'
          FocusControl = notesBox
          WordWrap = True
        end
        object accountenabledChk: TCheckBox
          Left = 11
          Height = 17
          Top = 20
          Width = 57
          Caption = '&Enabled'
          TabOrder = 0
          OnClick = accountenabledChkClick
        end
        object accountAccessBox: TTreeView
          Left = 11
          Height = 72
          Top = 192
          Width = 302
          Anchors = [akTop, akLeft, akBottom]
          Indent = 19
          ParentShowHint = False
          ReadOnly = True
          ShowRoot = False
          TabOrder = 7
          OnContextPopup = accountAccessBoxContextPopup
          OnDblClick = accountAccessBoxDblClick
          Options = [tvoAutoItemHeight, tvoHideSelection, tvoKeepCollapsedNodes, tvoReadOnly, tvoShowButtons, tvoShowLines, tvoToolTips, tvoThemedDraw]
        end
        object ignoreLimitsChk: TCheckBox
          Left = 226
          Height = 17
          Top = 20
          Width = 73
          Caption = '&Ignore limits'
          TabOrder = 2
        end
        object pwdBox: TLabeledEdit
          Left = 11
          Height = 21
          Top = 63
          Width = 198
          EchoMode = emPassword
          EditLabel.Height = 13
          EditLabel.Width = 198
          EditLabel.Caption = '&Password'
          PasswordChar = '*'
          TabOrder = 3
          OnEnter = pwdBoxEnter
          OnExit = pwdBoxExit
        end
        object redirBox: TLabeledEdit
          Left = 11
          Height = 21
          Top = 106
          Width = 198
          EditLabel.Height = 13
          EditLabel.Width = 198
          EditLabel.Caption = 'After login, redirect to'
          TabOrder = 4
          OnChange = redirBoxChange
        end
        object accountLinkBox: TLabeledEdit
          Left = 11
          Height = 21
          Top = 146
          Width = 198
          EditLabel.Height = 13
          EditLabel.Width = 198
          EditLabel.Caption = 'Member of'
          TabOrder = 5
          OnExit = accountLinkBoxExit
        end
        object groupChk: TCheckBox
          Left = 114
          Height = 17
          Top = 20
          Width = 47
          Caption = '&Group'
          TabOrder = 1
          OnClick = groupChkClick
        end
        object groupsBtn: TButton
          Left = 215
          Height = 21
          Top = 146
          Width = 90
          Caption = 'Choose...'
          TabOrder = 6
          OnClick = groupsBtnClick
        end
        object notesBox: TMemo
          Left = 345
          Height = 225
          Top = 39
          Width = 259
          Anchors = [akTop, akLeft, akRight, akBottom]
          ParentShowHint = False
          ScrollBars = ssVertical
          TabOrder = 8
        end
        object notesWrapChk: TCheckBox
          Left = 537
          Height = 17
          Top = 21
          Width = 44
          Anchors = [akTop, akRight]
          Caption = 'Wrap'
          Checked = True
          State = cbChecked
          TabOrder = 9
          OnClick = notesWrapChkClick
        end
      end
      object deleteaccountBtn: TButton
        Left = 3
        Height = 17
        Top = 325
        Width = 45
        Anchors = [akLeft, akBottom]
        Caption = 'de&lete'
        Enabled = False
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 2
        OnClick = deleteaccountBtnClick
      end
      object renaccountBtn: TButton
        Left = 53
        Height = 17
        Top = 302
        Width = 49
        Anchors = [akLeft, akBottom]
        Caption = '&rename'
        Enabled = False
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 3
        OnClick = renaccountBtnClick
      end
      object addaccountBtn: TButton
        Left = 3
        Height = 17
        Top = 302
        Width = 45
        Anchors = [akLeft, akBottom]
        Caption = 'ad&d'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 1
        OnClick = addaccountBtnClick
      end
      object upBtn: TButton
        Left = 107
        Height = 17
        Top = 302
        Width = 45
        Anchors = [akLeft, akBottom]
        Caption = '&up'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 5
        OnClick = upBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object downBtn: TButton
        Left = 107
        Height = 17
        Top = 325
        Width = 45
        Anchors = [akLeft, akBottom]
        Caption = 'do&wn'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 6
        OnClick = upBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object sortBtn: TButton
        Left = 53
        Height = 17
        Top = 325
        Width = 49
        Anchors = [akLeft, akBottom]
        Caption = 'sort'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 4
        OnClick = sortBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object accountsBox: TListView
        Left = 3
        Height = 261
        Top = 35
        Width = 149
        Anchors = [akTop, akLeft, akBottom]
        Columns = <>
        DragMode = dmAutomatic
        HideSelection = False
        OwnerData = True
        ParentShowHint = False
        RowSelect = True
        TabOrder = 0
        OnChange = accountsBoxChange
        OnClick = accountsBoxClick
        OnData = accountsBoxData
        OnDblClick = accountsBoxDblClick
        OnDragDrop = accountsBoxDragDrop
        OnDragOver = accountsBoxDragOver
        OnEdited = accountsBoxEdited
        OnEditing = accountsBoxEditing
        OnKeyDown = accountsBoxKeyDown
        OnKeyPress = accountsBoxKeyPress
      end
    end
    object mimePage: TTabSheet
      Caption = 'MIME types'
      ClientHeight = 388
      ClientWidth = 797
      ImageIndex = 7
      object mimeBox: TValueListEditor
        Left = 0
        Height = 358
        Top = 30
        Width = 797
        Align = alClient
        FixedCols = 0
        RowCount = 2
        TabOrder = 0
        KeyOptions = [keyEdit, keyAdd, keyDelete]
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goAutoAddRows, goAlwaysShowEditor, goThumbTracking]
        Strings.Strings = (
          '='
        )
        TitleCaptions.Strings = (
          'File Mask'
          'MIME Description'
        )
        ColWidths = (
          108
          685
        )
      end
      object Panel5: TPanel
        Left = 0
        Height = 30
        Top = 0
        Width = 797
        Align = alTop
        BevelOuter = bvNone
        ClientHeight = 30
        ClientWidth = 797
        ParentBackground = False
        TabOrder = 1
        object addMimeBtn: TButton
          Left = 4
          Height = 21
          Top = 5
          Width = 73
          Caption = 'Add row'
          TabOrder = 0
          OnClick = addMimeBtnClick
        end
        object deleteMimeBtn: TButton
          Left = 86
          Height = 21
          Top = 5
          Width = 73
          Caption = 'Delete row'
          TabOrder = 1
          OnClick = deleteMimeBtnClick
        end
        object inBrowserIfMIMEchk: TCheckBox
          Left = 184
          Height = 17
          Top = 7
          Width = 262
          Caption = 'Open directly in browser when MIME type is defined'
          TabOrder = 2
        end
      end
    end
    object trayPage: TTabSheet
      Caption = 'Tray Message'
      ClientHeight = 388
      ClientWidth = 797
      ImageIndex = 10
      object Label2: TLabel
        Left = 8
        Height = 156
        Top = 16
        Width = 282
        Caption = 'You can customize the message in the tray icon tip. '#13#10'The message length is determined by your Windows version'#13#10'(in XP the limit is 127 characters including spaces).'#13#10'Available symbols:'#13#10#13#10'  %uptime% - server uptime'#13#10'  %url% - server main URL'#13#10'  %ip% - IP address set as default'#13#10'  %port% - Port on which the server is listening'#13#10'  %hits% - number of requests made to the server'#13#10'  %downloads% - number of files downloaded'#13#10'  %version% - HFS version'
      end
      object Label10: TLabel
        Left = 264
        Height = 13
        Top = 157
        Width = 38
        Caption = 'Preview'
      end
      object traymsgBox: TMemo
        Left = 16
        Height = 121
        Top = 176
        Width = 233
        Lines.Strings = (
          'traymsgBox'
        )
        TabOrder = 0
        OnChange = traymsgBoxChange
      end
      object traypreviewBox: TMemo
        Left = 264
        Height = 121
        Top = 176
        Width = 233
        Color = clInfoBk
        ReadOnly = True
        TabOrder = 1
      end
    end
    object a2nPage: TTabSheet
      Caption = 'Address2name'
      ClientHeight = 388
      ClientWidth = 797
      object Panel4: TPanel
        Left = 0
        Height = 67
        Top = 0
        Width = 797
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        ClientHeight = 67
        ClientWidth = 797
        ParentBackground = False
        TabOrder = 0
        object Label4: TLabel
          Left = 8
          Height = 13
          Top = 8
          Width = 405
          Caption = 'You can associate a label to an address (or many addresses). It will be used in the log.'
          WordWrap = True
        end
        object deleteA2Nbtn: TButton
          Left = 83
          Height = 21
          Top = 40
          Width = 73
          Caption = '&Delete row'
          TabOrder = 0
          OnClick = deleteA2NbtnClick
        end
        object addA2Nbtn: TButton
          Left = 4
          Height = 21
          Top = 41
          Width = 73
          Caption = 'Add &row'
          TabOrder = 1
          OnClick = addA2NbtnClick
        end
      end
      object a2nBox: TValueListEditor
        Left = 0
        Height = 321
        Top = 67
        Width = 797
        Align = alClient
        FixedCols = 0
        RowCount = 2
        TabOrder = 1
        KeyOptions = [keyEdit, keyAdd, keyDelete]
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goAutoAddRows, goAlwaysShowEditor, goThumbTracking]
        Strings.Strings = (
          '='
        )
        TitleCaptions.Strings = (
          'Name'
          'IP Mask'
        )
        ColWidths = (
          108
          685
        )
      end
    end
    object iconsPage: TTabSheet
      Caption = 'Icon masks'
      ClientHeight = 388
      ClientWidth = 797
      object Label5: TLabel
        Left = 8
        Height = 13
        Top = 32
        Width = 221
        Caption = 'Each line is a file-mask associated with an icon'
        WordWrap = True
      end
      object Label6: TLabel
        Left = 272
        Height = 13
        Top = 128
        Width = 75
        Caption = 'Icon associated'
      end
      object iconMasksBox: TMemo
        Left = 8
        Height = 219
        Top = 48
        Width = 225
        Anchors = [akTop, akLeft, akBottom]
        TabOrder = 0
        OnChange = iconMasksBoxChange
      end
      object iconsBox: TComboBox
        Left = 272
        Height = 24
        Top = 144
        Width = 76
        ItemHeight = 16
        Style = csOwnerDrawFixed
        TabOrder = 1
        OnChange = iconsBoxChange
        OnDrawItem = iconsBoxDrawItem
        OnDropDown = iconsBoxDropDown
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Height = 35
    Top = 414
    Width = 805
    Align = alBottom
    BevelOuter = bvNone
    ClientHeight = 35
    ClientWidth = 805
    ParentBackground = False
    TabOrder = 1
    object okBtn: TButton
      Left = 561
      Height = 25
      Top = 6
      Width = 75
      Anchors = [akRight, akBottom]
      Caption = '&OK'
      TabOrder = 0
      OnClick = okBtnClick
    end
    object applyBtn: TButton
      Left = 725
      Height = 25
      Top = 6
      Width = 75
      Anchors = [akRight, akBottom]
      Caption = '&Apply'
      TabOrder = 1
      OnClick = applyBtnClick
    end
    object cancelBtn: TButton
      Left = 643
      Height = 25
      Top = 6
      Width = 75
      Anchors = [akRight, akBottom]
      Caption = '&Cancel'
      TabOrder = 2
      OnClick = cancelBtnClick
    end
  end
end
