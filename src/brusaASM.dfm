object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'BHyP ASM Layer Editer - V1.0.0'
  BorderStyle = bsSingle
  BorderIcons = [biSystemMenu]
  ClientHeight = 510
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
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object SourceGroupBox: TGroupBox
    Left = 15
    Top = 15
    Width = 410
    Height = 180
    Caption = 'Source Library'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    object BrusaHyPowerAG: TRadioButton
      Left = 33
      Top = 28
      Width = 250
      Height = 17
      Caption = 'Brusa HyPower AG'
      Font.Style = []
      ParentFont = False
      Checked = True
      TabOrder = 1
      OnClick = BrusaHyPowerAGClick
    end
    object LibSourceSelection_HyPower_Prod: TCheckBox
      Left = 58
      Top = 52
      Width = 220
      Height = 17
      Caption = 'BRUSA HYPOWER PROD'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = LibSourceSelection_HyPower_ProdClick
    end
    object LibSourceSelection_HyPower_DBLIB: TCheckBox
      Left = 58
      Top = 76
      Width = 250
      Height = 17
      Caption = 'BRUSA_AltiumLib_Database'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = LibSourceSelection_HyPower_DBLIBClick
    end
    object LibSelection_Custom: TRadioButton
      Left = 33
      Top = 104
      Width = 113
      Height = 17
      Caption = 'Custom'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnClick = LibSelection_CustomClick
    end
    object sourceLibrary_Save: TButton
      Left = 167
      Top = 140
      Width = 75
      Height = 25
      Caption = 'Start'
      Enabled = False
      TabOrder = 0
      OnClick = sourceLibrary_SaveClick
    end
  end
  object LayerGroupBox: TGroupBox
    Left = 15
    Top = 205
    Width = 410
    Height = 160
    Caption = 'Layer Assignments'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    object TOP_DES: TLabel
      Left = 12
      Top = 34
      Width = 125
      Height = 13
      Caption = 'Top Designator:'
      Font.Style = []
      ParentFont = False
    end
    object TOP_ASM: TLabel
      Left = 12
      Top = 58
      Width = 125
      Height = 13
      Caption = 'Top Assembly:'
      Font.Style = []
      ParentFont = False
    end
    object BOT_DES: TLabel
      Left = 12
      Top = 82
      Width = 125
      Height = 13
      Caption = 'Bottom Designator:'
      Font.Style = []
      ParentFont = False
    end
    object BOT_ASM: TLabel
      Left = 12
      Top = 106
      Width = 125
      Height = 13
      Caption = 'Bottom Assembly:'
      Font.Style = []
      ParentFont = False
    end
    object topDesignatorSelection_ComboBox: TComboBox
      Left = 145
      Top = 30
      Width = 250
      Height = 21
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      Text = 'Select the relevant layer'
    end
    object topAssemblySelection_ComboBox: TComboBox
      Left = 145
      Top = 54
      Width = 250
      Height = 21
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      Text = 'Select the relevant layer'
    end
    object bottomDesignatorSelection_ComboBox: TComboBox
      Left = 145
      Top = 78
      Width = 250
      Height = 21
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      Text = 'Select the relevant layer'
    end
    object bottomAssemblySelection_ComboBox: TComboBox
      Left = 145
      Top = 102
      Width = 250
      Height = 21
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      Text = 'Select the relevant layer'
    end
    object BottomDesignatorMirrorCheckBox: TCheckBox
      Left = 12
      Top = 137
      Width = 370
      Height = 17
      Caption = 'Mirror bottom designator text'
      Checked = True
      State = cbChecked
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
  end
  object BoardStatusGroupBox: TGroupBox
    Left = 15
    Top = 370
    Width = 410
    Height = 45
    Caption = 'Active PCB'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    object RefreshButton: TButton
      Left = 315
      Top = 14
      Width = 80
      Height = 24
      Caption = 'Refresh'
      Font.Style = []
      ParentFont = False
      OnClick = RefreshButtonClick
    end
    object BoardStatusLabel: TLabel
      Left = 8
      Top = 17
      Width = 300
      Height = 17
      Caption = 'Open a PCB document, then click Refresh.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object BoardFileNameLabel: TLabel
      Left = 8
      Top = 17
      Width = 300
      Height = 17
      Caption = ''
      AutoSize = False
      Alignment = taCenter
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
  object HelpGroupBox: TGroupBox
    Left = 15
    Top = 474
    Width = 410
    Height = 34
    Caption = 'Help - Add to Altium'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    object HelpToggleButton: TButton
      Left = 290
      Top = 4
      Width = 105
      Height = 23
      Caption = 'Help: Open'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = HelpToggleButtonClick
    end
    object HelpMemo: TMemo
      Left = 8
      Top = 30
      Width = 390
      Height = 172
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Lines.Strings = (
        '1. Open the PCB editor and right-click a menu or toolbar area.'
        '2. Select Customize, then create a new command.'
        '3. Set Process to:'
        'ScriptingSystem:RunScript'
        '4. Set Parameters to:'
        'ProjectName=C:\Users\ata01\source\repos\ahmediemre\AltiumAssemblyLayer\src\brusaASM.PrjScr|ProcName=brusaASM.pas>RunBrusaASM'
        '5. Set a caption, then drag the command to a menu or toolbar.'
        '6. Click the new command to open this form; click Start to process.'
        'Select and copy these lines with Ctrl+C. Update the path if moved.')
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 1
      Visible = False
      WordWrap = False
    end
  end
  object AboutGroupBox: TGroupBox
    Left = 15
    Top = 420
    Width = 410
    Height = 50
    Caption = 'About'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    object AboutLabel: TLabel
      Left = 8
      Top = 23
      Width = 390
      Height = 18
      Caption = 'V1.0.0  |  Ahmet Emre TALANCI  |  ahmet.talanci@brusahypower.com'
      AutoSize = False
      Alignment = taCenter
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
end
