object optionsFrm: ToptionsFrm
  Left = 287
  Height = 561
  Top = 162
  Width = 1006
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Options'
  ClientHeight = 561
  ClientWidth = 1006
  Color = clBtnFace
  DesignTimePPI = 120
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Position = poMainFormCenter
  LCLVersion = '4.8.0.0'
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  object pageCtrl: TPageControl
    Left = 0
    Height = 517
    Top = 0
    Width = 1006
    ActivePage = bansPage
    Align = alClient
    MultiLine = True
    Options = [nboMultiLine]
    TabIndex = 0
    TabOrder = 0
    object bansPage: TTabSheet
      Caption = 'Bans'
      ClientHeight = 488
      ClientWidth = 998
      ImageIndex = 25
      object Panel1: TPanel
        Left = 0
        Height = 38
        Top = 0
        Width = 998
        Align = alTop
        BevelOuter = bvNone
        ClientHeight = 38
        ClientWidth = 998
        ParentBackground = False
        TabOrder = 0
        object addBtn: TButton
          Left = 5
          Height = 26
          Top = 6
          Width = 91
          Caption = 'Add row'
          TabOrder = 0
          OnClick = addBtnClick
        end
        object deleteBtn: TButton
          Left = 108
          Height = 26
          Top = 6
          Width = 91
          Caption = 'Delete row'
          TabOrder = 1
          OnClick = deleteBtnClick
        end
        object sortBanBtn: TButton
          Left = 210
          Height = 26
          Top = 6
          Width = 91
          Caption = 'Sort'
          TabOrder = 2
          OnClick = sortBanBtnClick
        end
      end
      object bansBox: TValueListEditor
        Left = 0
        Height = 418
        Top = 38
        Width = 998
        Align = alClient
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
          135
          859
        )
      end
      object Panel3: TPanel
        Left = 0
        Height = 32
        Top = 456
        Width = 998
        Align = alBottom
        BevelOuter = bvNone
        ClientHeight = 32
        ClientWidth = 998
        ParentBackground = False
        TabOrder = 2
        object noreplybanChk: TCheckBox
          Left = 6
          Height = 20
          Top = 6
          Width = 164
          Caption = 'Disconnect with no reply'
          TabOrder = 0
        end
        object Button1: TButton
          Left = 220
          Height = 24
          Top = 5
          Width = 176
          Caption = 'How to invert the logic?'
          TabOrder = 1
          OnClick = Button1Click
        end
      end
    end
    object accountsPage: TTabSheet
      Caption = 'Accounts'
      ClientHeight = 488
      ClientWidth = 998
      ImageIndex = 29
      object Label1: TLabel
        Left = 11
        Height = 16
        Top = 20
        Width = 67
        Caption = 'Account list'
        FocusControl = accountsBox
      end
      object Label7: TLabel
        Left = 314
        Height = 16
        Hint = 'You also need to right click on the folder, then restrict access'
        Top = 407
        Width = 395
        Anchors = [akLeft, akBottom]
        Caption = 'WARNING: creating an account is not enough to protect  your files...'
        ParentShowHint = False
        ShowHint = True
        WordWrap = True
      end
      object accountpropGrp: TGroupBox
        Left = 204
        Height = 367
        Top = 32
        Width = 765
        Anchors = [akTop, akLeft, akRight, akBottom]
        Caption = 'Account properties'
        ClientHeight = 346
        ClientWidth = 761
        ParentBackground = False
        TabOrder = 7
        object Label3: TLabel
          Left = 14
          Height = 16
          Top = 216
          Width = 362
          Caption = 'Here you can see protected resources this user can access...'
          FocusControl = accountAccessBox
          WordWrap = True
        end
        object Label8: TLabel
          Left = 420
          Height = 16
          Top = 25
          Width = 36
          Caption = 'Notes'
          FocusControl = notesBox
          WordWrap = True
        end
        object accountenabledChk: TCheckBox
          Left = 14
          Height = 20
          Top = 25
          Width = 72
          Caption = '&Enabled'
          TabOrder = 0
          OnClick = accountenabledChkClick
        end
        object accountAccessBox: TTreeView
          Left = 14
          Height = 95
          Top = 240
          Width = 378
          Anchors = [akTop, akLeft, akBottom]
          ParentShowHint = False
          ReadOnly = True
          ShowRoot = False
          TabOrder = 7
          Options = [tvoAutoItemHeight, tvoHideSelection, tvoKeepCollapsedNodes, tvoReadOnly, tvoShowButtons, tvoShowLines, tvoToolTips, tvoThemedDraw]
          OnContextPopup = accountAccessBoxContextPopup
          OnDblClick = accountAccessBoxDblClick
        end
        object ignoreLimitsChk: TCheckBox
          Left = 282
          Height = 20
          Top = 25
          Width = 92
          Caption = '&Ignore limits'
          TabOrder = 2
        end
        object pwdBox: TLabeledEdit
          Left = 14
          Height = 24
          Top = 79
          Width = 248
          EchoMode = emPassword
          EditLabel.Height = 16
          EditLabel.Width = 248
          EditLabel.Caption = '&Password'
          PasswordChar = '*'
          TabOrder = 3
          OnEnter = pwdBoxEnter
          OnExit = pwdBoxExit
        end
        object redirBox: TLabeledEdit
          Left = 14
          Height = 24
          Top = 132
          Width = 248
          EditLabel.Height = 16
          EditLabel.Width = 248
          EditLabel.Caption = 'After login, redirect to'
          TabOrder = 4
          OnChange = redirBoxChange
        end
        object accountLinkBox: TLabeledEdit
          Left = 14
          Height = 24
          Top = 182
          Width = 248
          EditLabel.Height = 16
          EditLabel.Width = 248
          EditLabel.Caption = 'Member of'
          TabOrder = 5
          OnExit = accountLinkBoxExit
        end
        object groupChk: TCheckBox
          Left = 142
          Height = 20
          Top = 25
          Width = 58
          Caption = '&Group'
          TabOrder = 1
          OnClick = groupChkClick
        end
        object groupsBtn: TButton
          Left = 269
          Height = 26
          Top = 182
          Width = 112
          Caption = 'Choose...'
          TabOrder = 6
          OnClick = groupsBtnClick
        end
        object notesBox: TMemo
          Left = 431
          Height = 286
          Top = 49
          Width = 326
          Anchors = [akTop, akLeft, akRight, akBottom]
          ParentShowHint = False
          ScrollBars = ssVertical
          TabOrder = 8
        end
        object notesWrapChk: TCheckBox
          Left = 675
          Height = 20
          Top = 26
          Width = 54
          Anchors = [akTop, akRight]
          Caption = 'Wrap'
          Checked = True
          State = cbChecked
          TabOrder = 9
          OnClick = notesWrapChkClick
        end
      end
      object deleteaccountBtn: TButton
        Left = 4
        Height = 21
        Top = 409
        Width = 56
        Anchors = [akLeft, akBottom]
        Caption = 'de&lete'
        Enabled = False
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 2
        OnClick = deleteaccountBtnClick
      end
      object renaccountBtn: TButton
        Left = 66
        Height = 21
        Top = 381
        Width = 61
        Anchors = [akLeft, akBottom]
        Caption = '&rename'
        Enabled = False
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 3
        OnClick = renaccountBtnClick
      end
      object addaccountBtn: TButton
        Left = 4
        Height = 21
        Top = 381
        Width = 56
        Anchors = [akLeft, akBottom]
        Caption = 'ad&d'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 1
        OnClick = addaccountBtnClick
      end
      object upBtn: TButton
        Left = 134
        Height = 21
        Top = 381
        Width = 56
        Anchors = [akLeft, akBottom]
        Caption = '&up'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 5
        OnClick = upBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object downBtn: TButton
        Left = 134
        Height = 21
        Top = 409
        Width = 56
        Anchors = [akLeft, akBottom]
        Caption = 'do&wn'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 6
        OnClick = upBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object sortBtn: TButton
        Left = 66
        Height = 21
        Top = 409
        Width = 61
        Anchors = [akLeft, akBottom]
        Caption = 'sort'
        Font.CharSet = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = 'Tahoma'
        ParentFont = False
        TabOrder = 4
        OnClick = sortBtnClick
        OnMouseUp = upBtnMouseUp
      end
      object accountsBox: TListView
        Left = 4
        Height = 329
        Top = 44
        Width = 186
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
      ClientHeight = 488
      ClientWidth = 998
      ImageIndex = 7
      object mimeBox: TValueListEditor
        Left = 0
        Height = 450
        Top = 38
        Width = 998
        Align = alClient
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
          135
          859
        )
      end
      object Panel5: TPanel
        Left = 0
        Height = 38
        Top = 0
        Width = 998
        Align = alTop
        BevelOuter = bvNone
        ClientHeight = 38
        ClientWidth = 998
        ParentBackground = False
        TabOrder = 1
        object addMimeBtn: TButton
          Left = 5
          Height = 26
          Top = 6
          Width = 91
          Caption = 'Add row'
          TabOrder = 0
          OnClick = addMimeBtnClick
        end
        object deleteMimeBtn: TButton
          Left = 108
          Height = 26
          Top = 6
          Width = 91
          Caption = 'Delete row'
          TabOrder = 1
          OnClick = deleteMimeBtnClick
        end
        object inBrowserIfMIMEchk: TCheckBox
          Left = 230
          Height = 20
          Top = 9
          Width = 325
          Caption = 'Open directly in browser when MIME type is defined'
          TabOrder = 2
        end
      end
    end
    object trayPage: TTabSheet
      Caption = 'Tray Message'
      ClientHeight = 488
      ClientWidth = 998
      ImageIndex = 10
      object Label2: TLabel
        Left = 10
        Height = 192
        Top = 20
        Width = 359
        Caption = 'You can customize the message in the tray icon tip. '#13#10'The message length is determined by your Windows version'#13#10'(in XP the limit is 127 characters including spaces).'#13#10'Available symbols:'#13#10#13#10'  %uptime% - server uptime'#13#10'  %url% - server main URL'#13#10'  %ip% - IP address set as default'#13#10'  %port% - Port on which the server is listening'#13#10'  %hits% - number of requests made to the server'#13#10'  %downloads% - number of files downloaded'#13#10'  %version% - HFS version'
      end
      object Label10: TLabel
        Left = 330
        Height = 16
        Top = 196
        Width = 48
        Caption = 'Preview'
      end
      object traymsgBox: TMemo
        Left = 20
        Height = 151
        Top = 220
        Width = 291
        Lines.Strings = (
          'traymsgBox'
        )
        TabOrder = 0
        OnChange = traymsgBoxChange
      end
      object traypreviewBox: TMemo
        Left = 330
        Height = 151
        Top = 220
        Width = 291
        Color = clInfoBk
        ReadOnly = True
        TabOrder = 1
      end
    end
    object a2nPage: TTabSheet
      Caption = 'Address2name'
      ClientHeight = 488
      ClientWidth = 998
      object Panel4: TPanel
        Left = 0
        Height = 84
        Top = 0
        Width = 998
        Align = alTop
        Alignment = taLeftJustify
        BevelOuter = bvNone
        ClientHeight = 84
        ClientWidth = 998
        ParentBackground = False
        TabOrder = 0
        object Label4: TLabel
          Left = 10
          Height = 16
          Top = 10
          Width = 511
          Caption = 'You can associate a label to an address (or many addresses). It will be used in the log.'
          WordWrap = True
        end
        object deleteA2Nbtn: TButton
          Left = 104
          Height = 26
          Top = 50
          Width = 91
          Caption = '&Delete row'
          TabOrder = 0
          OnClick = deleteA2NbtnClick
        end
        object addA2Nbtn: TButton
          Left = 5
          Height = 26
          Top = 51
          Width = 91
          Caption = 'Add &row'
          TabOrder = 1
          OnClick = addA2NbtnClick
        end
      end
      object a2nBox: TValueListEditor
        Left = 0
        Height = 404
        Top = 84
        Width = 998
        Align = alClient
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
          135
          859
        )
      end
    end
    object iconsPage: TTabSheet
      Caption = 'Icon masks'
      ClientHeight = 488
      ClientWidth = 998
      object Label5: TLabel
        Left = 10
        Height = 16
        Top = 40
        Width = 277
        Caption = 'Each line is a file-mask associated with an icon'
        WordWrap = True
      end
      object Label6: TLabel
        Left = 340
        Height = 16
        Top = 160
        Width = 95
        Caption = 'Icon associated'
      end
      object iconMasksBox: TMemo
        Left = 10
        Height = 277
        Top = 60
        Width = 281
        Anchors = [akTop, akLeft, akBottom]
        TabOrder = 0
        OnChange = iconMasksBoxChange
      end
      object iconsBox: TComboBox
        Left = 340
        Height = 26
        Top = 180
        Width = 95
        ItemHeight = 20
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
    Height = 44
    Top = 517
    Width = 1006
    Align = alBottom
    BevelOuter = bvNone
    ClientHeight = 44
    ClientWidth = 1006
    ParentBackground = False
    TabOrder = 1
    object okBtn: TButton
      Left = 701
      Height = 31
      Top = 8
      Width = 94
      Anchors = [akRight, akBottom]
      Caption = '&OK'
      TabOrder = 0
      OnClick = okBtnClick
    end
    object applyBtn: TButton
      Left = 906
      Height = 31
      Top = 8
      Width = 94
      Anchors = [akRight, akBottom]
      Caption = '&Apply'
      TabOrder = 1
      OnClick = applyBtnClick
    end
    object cancelBtn: TButton
      Left = 803
      Height = 31
      Top = 8
      Width = 94
      Anchors = [akRight, akBottom]
      Caption = '&Cancel'
      TabOrder = 2
      OnClick = cancelBtnClick
    end
  end
end
