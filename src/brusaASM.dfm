object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'ASMGerberLayerCreation'
  ClientHeight = 470
  ClientWidth = 340
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  WindowState = wsNormal
  PixelsPerInch = 96
  TextHeight = 14
  object TOP_DES: TLabel
    Left = 11
    Top = 345
    Width = 77
    Height = 13
    Caption = 'Top Designator:'
  end
  object TOP_ASM: TLabel
    Left = 11
    Top = 371
    Width = 70
    Height = 13
    Caption = 'Top Assembly:'
  end
  object BOT_DES: TLabel
    Left = 11
    Top = 394
    Width = 93
    Height = 13
    Caption = 'Bottom Designator:'
  end
  object BOT_ASM: TLabel
    Left = 11
    Top = 417
    Width = 86
    Height = 13
    Caption = 'Bottom Assembly:'
  end
  object LayerNumbers: TLabel
    Left = 154
    Top = 317
    Width = 76
    Height = 13
    Caption = 'Layer Numbers:'
  end
  object sourceLib: TLabel
    Left = 96
    Top = 29
    Width = 148
    Height = 24
    Caption = 'Source Library'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -20
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object sourceLibrary_Save: TButton
    Left = 115
    Top = 249
    Width = 75
    Height = 25
    Caption = 'Run!'
    TabOrder = 0
    OnClick = sourceLibrary_SaveClick
  end
  object BrusaHyPowerAG: TRadioButton
    Left = 48
    Top = 61
    Width = 113
    Height = 17
    Caption = 'BrusaHyPowerAG'
    TabOrder = 1
    OnClick = BrusaHyPowerAGClick
  end
  object topDesignatorSelection_ComboBox: TComboBox
    Left = 107
    Top = 343
    Width = 145
    Height = 21
    TabOrder = 2
    Text = 'Select the relevant layer'
  end
  object topAssemblySelection_ComboBox: TComboBox
    Left = 107
    Top = 367
    Width = 145
    Height = 21
    TabOrder = 3
    Text = 'Select the relevant layer'
  end
  object bottomDesignatorSelection_ComboBox: TComboBox
    Left = 107
    Top = 391
    Width = 145
    Height = 21
    TabOrder = 4
    Text = 'Select the relevant layer'
  end
  object bottomAssemblySelection_ComboBox: TComboBox
    Left = 107
    Top = 415
    Width = 145
    Height = 21
    TabOrder = 5
    Text = 'Select the relevant layer'
  end
  object LibSourceSelection_HyPower_Prod: TCheckBox
    Left = 73
    Top = 83
    Width = 159
    Height = 17
    Caption = 'BRUSA HYPOWER PROD'
    TabOrder = 6
    OnClick = LibSourceSelection_HyPower_ProdClick
  end
  object LibSourceSelection_HyPower_DBLIB: TCheckBox
    Left = 73
    Top = 107
    Width = 151
    Height = 17
    Caption = 'BRUSA_AltiumLib_Database'
    TabOrder = 7
    OnClick = LibSourceSelection_HyPower_DBLIBClick
  end
  object LibSelection_BrusaElectronics: TRadioButton
    Left = 48
    Top = 130
    Width = 113
    Height = 17
    Caption = 'Brusa Electronics AG'
    Enabled = False
    TabOrder = 8
  end
  object LibSourceSelection_BrusaElectronics: TCheckBox
    Left = 73
    Top = 155
    Width = 199
    Height = 17
    Caption = 'TBD'
    Enabled = False
    TabOrder = 9
  end
  object LibSelection_BrusaICS: TRadioButton
    Left = 48
    Top = 179
    Width = 113
    Height = 17
    Caption = 'Brusa ICS AG'
    Enabled = False
    TabOrder = 10
  end
  object LibSourceSelection_BrusaICS: TCheckBox
    Left = 73
    Top = 203
    Width = 97
    Height = 17
    Caption = 'TBD'
    Enabled = False
    TabOrder = 11
  end
  object LibSelection_Custom: TRadioButton
    Left = 48
    Top = 227
    Width = 113
    Height = 17
    Caption = 'Custom'
    TabOrder = 12
    OnClick = LibSelection_CustomClick
  end
end
