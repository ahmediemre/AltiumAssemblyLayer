object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'BHyP ASM Layer Editer'
  ClientHeight = 500
  ClientWidth = 440
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
    Left = 15
    Top = 345
    Width = 125
    Height = 13
    Caption = 'Top Designator:'
  end
  object TOP_ASM: TLabel
    Left = 15
    Top = 371
    Width = 125
    Height = 13
    Caption = 'Top Assembly:'
  end
  object BOT_DES: TLabel
    Left = 15
    Top = 394
    Width = 125
    Height = 13
    Caption = 'Bottom Designator:'
  end
  object BOT_ASM: TLabel
    Left = 15
    Top = 417
    Width = 125
    Height = 13
    Caption = 'Bottom Assembly:'
  end
  object LayerNumbers: TLabel
    Left = 215
    Top = 317
    Width = 120
    Height = 13
    Caption = 'Layer Assignments:'
  end
  object sourceLib: TLabel
    Left = 146
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
    Left = 182
    Top = 249
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 0
    OnClick = sourceLibrary_SaveClick
  end
  object BrusaHyPowerAG: TRadioButton
    Left = 48
    Top = 61
    Width = 113
    Height = 17
    Caption = 'Brusa HyPower AG'
    TabOrder = 1
    OnClick = BrusaHyPowerAGClick
  end
  object topDesignatorSelection_ComboBox: TComboBox
    Left = 145
    Top = 343
    Width = 275
    Height = 21
    TabOrder = 2
    Text = 'Select the relevant layer'
  end
  object topAssemblySelection_ComboBox: TComboBox
    Left = 145
    Top = 367
    Width = 275
    Height = 21
    TabOrder = 3
    Text = 'Select the relevant layer'
  end
  object bottomDesignatorSelection_ComboBox: TComboBox
    Left = 145
    Top = 391
    Width = 275
    Height = 21
    TabOrder = 4
    Text = 'Select the relevant layer'
  end
  object bottomAssemblySelection_ComboBox: TComboBox
    Left = 145
    Top = 415
    Width = 275
    Height = 21
    TabOrder = 5
    Text = 'Select the relevant layer'
  end
  object LibSourceSelection_HyPower_Prod: TCheckBox
    Left = 73
    Top = 83
    Width = 220
    Height = 17
    Caption = 'BRUSA HYPOWER PROD'
    TabOrder = 6
    OnClick = LibSourceSelection_HyPower_ProdClick
  end
  object LibSourceSelection_HyPower_DBLIB: TCheckBox
    Left = 73
    Top = 107
    Width = 250
    Height = 17
    Caption = 'BRUSA_AltiumLib_Database'
    TabOrder = 7
    OnClick = LibSourceSelection_HyPower_DBLIBClick
  end
  object LibSelection_Custom: TRadioButton
    Left = 48
    Top = 227
    Width = 113
    Height = 17
    Caption = 'Custom'
    TabOrder = 8
    OnClick = LibSelection_CustomClick
  end
  object ContactInfo: TLabel
    Left = 15
    Top = 465
    Width = 410
    Height = 18
    Caption = 'Contact: ahmet.talanci@brusahypower.com'
  end
end
