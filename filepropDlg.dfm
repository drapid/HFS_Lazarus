object filepropFrm: TfilepropFrm
  Left = 318
  Height = 401
  Top = 320
  Width = 393
  Caption = 'filepropFrm'
  ClientHeight = 401
  ClientWidth = 393
  Color = clBtnFace
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  KeyPreview = True
  Position = poMainFormCenter
  ShowHint = True
  OnClose = FormClose
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  object pages: TPageControl
    Left = 0
    Height = 366
    Top = 0
    Width = 393
    ActivePage = otherTab
    Align = alClient
    ParentShowHint = False
    RaggedRight = True
    ShowHint = True
    TabIndex = 5
    TabOrder = 0
    object permTab: TTabSheet
      Caption = 'Permissions'
      ClientHeight = 340
      ClientWidth = 385
      ImageIndex = 1
      object actionTabs: TTabControl
        Left = 0
        Height = 340
        Top = 0
        Width = 385
        MultiLine = True
        OnChange = actionTabsChange
        Align = alClient
        TabOrder = 0
        object newaccBtn: TButton
          Left = 278
          Height = 25
          Top = 56
          Width = 92
          Anchors = [akTop, akRight]
          Caption = 'New account'
          TabOrder = 0
          OnClick = newaccBtnClick
        end
        object anyAccChk: TCheckBox
          Left = 297
          Height = 17
          Top = 151
          Width = 78
          Anchors = [akTop, akRight]
          Caption = 'Any account'
          TabOrder = 1
          OnClick = anonChkClick
        end
        object anonChk: TCheckBox
          Left = 301
          Height = 17
          Top = 183
          Width = 74
          Anchors = [akTop, akRight]
          Caption = 'Anonymous'
          TabOrder = 2
          OnClick = anonChkClick
        end
        object allBtn: TButton
          Left = 278
          Height = 25
          Top = 95
          Width = 92
          Anchors = [akTop, akRight]
          Caption = 'All / None'
          TabOrder = 3
          OnClick = allBtnClick
        end
        object accountsBox: TListView
          Left = 16
          Height = 287
          Top = 40
          Width = 247
          Anchors = [akTop, akLeft, akRight, akBottom]
          Checkboxes = True
          Columns = <>
          TabOrder = 4
          OnChange = accountsBoxChange
        end
        object anyoneChk: TCheckBox
          Left = 320
          Height = 17
          Top = 216
          Width = 55
          Anchors = [akTop, akRight]
          Caption = 'Anyone'
          TabOrder = 5
          OnClick = anonChkClick
        end
        object goToAccountsBtn: TButton
          Left = 278
          Height = 33
          Top = 288
          Width = 92
          Anchors = [akTop, akRight]
          Caption = 'Manage  accounts'
          TabOrder = 6
          OnClick = goToAccountsBtnClick
        end
      end
    end
    object flagsTab: TTabSheet
      Caption = 'Flags'
      ClientHeight = 340
      ClientWidth = 385
      ImageIndex = 2
      object hiddenChk: TCheckBox
        Left = 32
        Height = 17
        Hint = 'Test'
        Top = 24
        Width = 51
        Caption = 'Hidden'
        Enabled = False
        TabOrder = 0
      end
      object hidetreeChk: TCheckBox
        Left = 32
        Height = 17
        Top = 56
        Width = 111
        Caption = 'Recursively  hidden'
        Enabled = False
        TabOrder = 1
      end
      object archivableChk: TCheckBox
        Left = 32
        Height = 17
        Top = 121
        Width = 68
        Caption = 'Archivable'
        Enabled = False
        TabOrder = 2
      end
      object browsableChk: TCheckBox
        Left = 32
        Height = 17
        Top = 88
        Width = 67
        Caption = 'Browsable'
        Enabled = False
        TabOrder = 3
      end
      object dontlogChk: TCheckBox
        Left = 32
        Height = 17
        Top = 184
        Width = 60
        Caption = 'Don''t log'
        Enabled = False
        TabOrder = 4
      end
      object nodlChk: TCheckBox
        Left = 32
        Height = 17
        Top = 152
        Width = 80
        Caption = 'No download'
        Enabled = False
        TabOrder = 5
      end
      object dontconsiderChk: TCheckBox
        Left = 32
        Height = 17
        Top = 216
        Width = 149
        Caption = 'Don''t consider as download'
        Enabled = False
        TabOrder = 6
      end
      object hideemptyChk: TCheckBox
        Left = 32
        Height = 17
        Top = 249
        Width = 134
        Caption = 'Auto-hide empty folders'
        Enabled = False
        TabOrder = 7
      end
      object hideextChk: TCheckBox
        Left = 32
        Height = 17
        Top = 280
        Width = 147
        Caption = 'Hide file extension in listing'
        Enabled = False
        TabOrder = 8
      end
    end
    object diffTab: TTabSheet
      Caption = 'Diff template'
      ClientHeight = 340
      ClientWidth = 385
      ImageIndex = 3
      object difftplBox: TMemo
        Left = 0
        Height = 340
        Hint = 'Here you can put a partial template that will overlap the main one.'
        Top = 0
        Width = 385
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
        OnEnter = textinputEnter
      end
    end
    object commentTab: TTabSheet
      Caption = 'Comment'
      ClientHeight = 340
      ClientWidth = 385
      ImageIndex = 4
      object commentBox: TMemo
        Left = 0
        Height = 340
        Top = 0
        Width = 385
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
        OnEnter = textinputEnter
      end
    end
    object maskTab: TTabSheet
      Caption = 'File masks'
      ClientHeight = 340
      ClientWidth = 385
      ImageIndex = 5
      object filesfilterBox: TLabeledEdit
        Left = 10
        Height = 21
        Top = 32
        Width = 357
        Anchors = [akTop, akLeft, akRight]
        EditLabel.Height = 13
        EditLabel.Width = 357
        EditLabel.Caption = 'Files filter'
        Enabled = False
        TabOrder = 0
        OnEnter = textinputEnter
      end
      object foldersfilterBox: TLabeledEdit
        Left = 10
        Height = 21
        Top = 78
        Width = 357
        Anchors = [akTop, akLeft, akRight]
        EditLabel.Height = 13
        EditLabel.Width = 357
        EditLabel.Caption = 'Folders filter'
        Enabled = False
        TabOrder = 1
        OnEnter = textinputEnter
      end
      object deffileBox: TLabeledEdit
        Left = 10
        Height = 21
        Hint = 'When a folder is browsed, the default file mask is used to find a file to serve in place of the folder page. If no file is found, the folder page is served.'
        Top = 125
        Width = 357
        Anchors = [akTop, akLeft, akRight]
        EditLabel.Height = 13
        EditLabel.Width = 357
        EditLabel.Caption = 'Default file mask'
        Enabled = False
        TabOrder = 2
        OnEnter = textinputEnter
      end
      object uploadfilterBox: TLabeledEdit
        Left = 10
        Height = 21
        Hint = 'Uploaded files are allowed only complying with this file mask'
        Top = 171
        Width = 357
        Anchors = [akTop, akLeft, akRight]
        EditLabel.Height = 13
        EditLabel.Width = 357
        EditLabel.Caption = 'Upload filter mask'
        Enabled = False
        TabOrder = 3
        OnEnter = textinputEnter
      end
      object dontconsiderBox: TLabeledEdit
        Left = 10
        Height = 21
        Hint = 'Files matching this filemask are not considered for global downloads counter. Moreover they never get tray icon.'
        Top = 218
        Width = 357
        Anchors = [akTop, akLeft, akRight]
        EditLabel.Height = 13
        EditLabel.Width = 357
        EditLabel.Caption = 'Don''t consider as download (mask)'
        Enabled = False
        TabOrder = 4
        OnEnter = textinputEnter
      end
    end
    object otherTab: TTabSheet
      Caption = 'Other'
      ClientHeight = 340
      ClientWidth = 385
      ImageIndex = 5
      object Label1: TLabel
        Left = 10
        Height = 13
        Top = 72
        Width = 21
        Caption = 'Icon'
      end
      object realmBox: TLabeledEdit
        Left = 10
        Height = 21
        Hint = 'The realm string is shown on the user/pass dialog of the browser. This realm will be used for selected files and their descendants.'
        Top = 32
        Width = 357
        Anchors = [akTop, akLeft, akRight]
        EditLabel.Height = 13
        EditLabel.Width = 357
        EditLabel.Caption = 'Realm'
        Enabled = False
        TabOrder = 0
        OnEnter = textinputEnter
      end
      object iconBox: TComboBoxEx
        Left = 10
        Height = 22
        Top = 91
        Width = 127
        ItemHeight = 16
        ItemsEx = <>
        Style = csExDropDownList
        TabOrder = 2
      end
      object addiconBtn: TButton
        Left = 152
        Height = 22
        Top = 91
        Width = 75
        Caption = 'Add new...'
        TabOrder = 1
        OnClick = addiconBtnClick
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Height = 35
    Top = 366
    Width = 393
    Align = alBottom
    BevelOuter = bvNone
    ClientHeight = 35
    ClientWidth = 393
    ParentBackground = False
    TabOrder = 1
    object okBtn: TButton
      Left = 152
      Height = 25
      Top = 6
      Width = 75
      Anchors = [akTop, akRight]
      Caption = '&OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object cancelBtn: TButton
      Left = 313
      Height = 25
      Top = 6
      Width = 75
      Anchors = [akTop, akRight]
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object applyBtn: TButton
      Left = 232
      Height = 25
      Top = 6
      Width = 75
      Anchors = [akTop, akRight]
      Caption = '&Apply'
      TabOrder = 2
      OnClick = applyBtnClick
    end
  end
end
