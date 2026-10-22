unit brusaASM;

interface

uses
  System.SysUtils, System.Classes, Forms, Controls, StdCtrls, Dialogs,
  PCB, PCBConst;

type
  TForm1 = class(TForm)
   // Form UI Components
    BrusaHyPowerAG: TRadioButton;               					// Toggles HyPower library selection
    LibSourceSelection_HyPower_Prod: TCheckBox; 					// Selects production library source
    LibSourceSelection_HyPower_DBLIB: TCheckBox;					// Selects database library source
    LibSelection_Custom: TRadioButton;          					// Enables custom library configuration
    sourceLibrary_Save: TButton;                					// Triggers the main processing
    BOT_DES: TLabel;                           						// Bottom designator layer label
    BOT_ASM: TLabel;                           						// Bottom assembly layer label
    TOP_DES: TLabel;                           						// Top designator layer label
    TOP_ASM: TLabel;                           						// Top assembly layer label
    ContactLabel: TLabel;
    ContactInfo: TLabel;
    topDesignatorSelection_ComboBox: TComboBox; 					// Top designator layer selection
    topAssemblySelection_ComboBox: TComboBox;   					// Top assembly layer selection
    bottomDesignatorSelection_ComboBox: TComboBox; 					// Bottom designator layer selection
    bottomAssemblySelection_ComboBox: TComboBox; 					// Bottom assembly layer selection
    SourceGroupBox: TGroupBox;
    RefreshButton: TButton;
     ContactGroupBox: TGroupBox;
     BoardStatusGroupBox: TGroupBox;
    BoardStatusLabel: TLabel;
     BoardFileNameLabel: TLabel;

    // Event Handlers
    procedure FormCreate(Sender: TObject);      					  // Initializes form
    procedure BrusaHyPowerAGClick(Sender: TObject); 				  // Handles HyPower selection
    procedure LibSelection_CustomClick(Sender: TObject); 			  // Handles custom selection
    procedure LibSourceSelection_HyPower_ProdClick(Sender: TObject);  // Handles production source selection
    procedure LibSourceSelection_HyPower_DBLIBClick(Sender: TObject); // Handles DB library source selection
    procedure RefreshButtonClick(Sender: TObject);
    procedure sourceLibrary_SaveClick(Sender: TObject); 			  // Main processing trigger
  private
    // Helper Methods
    FUpdatingLibrarySource: Boolean;
    FBoardReady: Boolean;
    FProcessing: Boolean;
    procedure UpdateLibraryCheckboxes;          					// Updates UI based on selections
    procedure SetBoardReady(Ready: Boolean);
    procedure SetLayerAssignmentsVisible(Visible: Boolean);
    procedure SelectLayerInCombo(Combo: TComboBox; Layer: Integer; FallbackName: string);
    procedure SetDefaultLayerAssignments;
    procedure Toggle_HyPowerLibrary(Selected: string); 				// Manages HyPower library options
    procedure FillAllLayerCombos;              						// Populates layer selection comboboxes
    procedure UnlockAllComponents;             						// Unlocks all PCB components
    procedure DeleteOnlyComponentDesignators(TopLayer, BottomLayer: Integer); // Removes existing designators
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const
  SOURCE_TOP_LAYER = 61;
  SOURCE_BOTTOM_LAYER = 62;
  ASSEMBLY_TOP_LAYER = 66;
  ASSEMBLY_BOTTOM_LAYER = 67;
  DESIGNATOR_TOP_LAYER = 68;
  DESIGNATOR_BOTTOM_LAYER = 69;
  FIRST_SUPPORTED_LAYER_INDEX = 0;
  FIRST_MECHANICAL_LAYER_INDEX = 32;
  LAST_SUPPORTED_LAYER_INDEX = 150;
  DESIGNATOR_INITIAL_HEIGHT_MILS = 60;
  DESIGNATOR_MIN_HEIGHT_MILS = 10;
  DESIGNATOR_SHRINK_FACTOR = 0.9;
  ASSEMBLY_TRACK_WIDTH_MM = 0.1;

var
  StopRequested: Boolean;

function ContinueProcessing: Boolean;
begin
  Application.ProcessMessages;
  Result := not StopRequested;
end;

procedure TForm1.SelectLayerInCombo(Combo: TComboBox; Layer: Integer; FallbackName: string);
var
  i: Integer;
  LayerPrefix: string;
begin
  LayerPrefix := IntToStr(Layer) + ' - ';
  for i := 0 to Combo.Items.Count - 1 do
  begin
    if Copy(Combo.Items[i], 1, Length(LayerPrefix)) = LayerPrefix then
    begin
      Combo.ItemIndex := i;
      Exit;
    end;
  end;
  Combo.Items.Add(LayerPrefix + FallbackName);
  Combo.ItemIndex := Combo.Items.Count - 1;
end;

procedure TForm1.SetDefaultLayerAssignments;
begin
  SelectLayerInCombo(topDesignatorSelection_ComboBox, DESIGNATOR_TOP_LAYER, 'Top Designator');
  SelectLayerInCombo(topAssemblySelection_ComboBox, ASSEMBLY_TOP_LAYER, 'Top Assembly');
  SelectLayerInCombo(bottomDesignatorSelection_ComboBox, DESIGNATOR_BOTTOM_LAYER, 'Bottom Designator');
  SelectLayerInCombo(bottomAssemblySelection_ComboBox, ASSEMBLY_BOTTOM_LAYER, 'Bottom Assembly');
end;

function TryGetSelectedLayer(Combo: TComboBox; var Layer: Integer): Boolean;
var
  SeparatorPosition: Integer;
begin
  Result := False;
  if (Combo = nil) or (Combo.ItemIndex < 0) then Exit;
  SeparatorPosition := Pos('-', Combo.Text);
  if SeparatorPosition <= 1 then Exit;
  try
    Layer := StrToInt(Trim(Copy(Combo.Text, 1, SeparatorPosition - 1)));
    Result := True;
  except
    Result := False;
  end;
end;

procedure ProcessTracksOnLayer(Layer: TLayer; NewWidth: TCoord);
var
  Board    : IPCB_Board;
  Iterator : IPCB_BoardIterator;
  Track    : IPCB_Track;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;

  Iterator := nil;
  PCBServer.PreProcess;

  try
    Iterator := Board.BoardIterator_Create;
    try
      Iterator.AddFilter_ObjectSet(MkSet(eTrackObject));
      Iterator.AddFilter_LayerSet(MkSet(Layer));
      Iterator.AddFilter_Method(eProcessAll);

      Track := Iterator.FirstPCBObject;
      while Track <> nil do
      begin
        if not ContinueProcessing then Break;
        Track.BeginModify;
        try
          Track.Width := NewWidth;
        finally
          Track.EndModify;
        end;
        Track.GraphicallyInvalidate;
        Track := Iterator.NextPCBObject;
      end;
    finally
      if Iterator <> nil then
        Board.BoardIterator_Destroy(Iterator);
    end;
  finally
    PCBServer.PostProcess;
  end;
end;

//  Only select & modify arcs
procedure ProcessArcsOnLayer(Layer: TLayer; NewWidth: TCoord);
var
  Board    : IPCB_Board;
  Iterator : IPCB_BoardIterator;
  Arc      : IPCB_Arc;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;

  Iterator := nil;
  PCBServer.PreProcess;

  try
    Iterator := Board.BoardIterator_Create;
    try
      Iterator.AddFilter_ObjectSet(MkSet(eArcObject));
      Iterator.AddFilter_LayerSet(MkSet(Layer));
      Iterator.AddFilter_Method(eProcessAll);

      Arc := Iterator.FirstPCBObject;
      while Arc <> nil do
      begin
        if not ContinueProcessing then Break;
        Arc.BeginModify;
        try
          Arc.LineWidth := NewWidth;
        finally
          Arc.EndModify;
        end;
        Arc.GraphicallyInvalidate;
        Arc := Iterator.NextPCBObject;
      end;
    finally
      if Iterator <> nil then
        Board.BoardIterator_Destroy(Iterator);
    end;
  finally
    PCBServer.PostProcess;
  end;
end;

function SaveCurrentPCB: Boolean;
Var
    PCB_Board     : IPCB_Board;
    Workspace     : IWorkspace;
    PCB_FileName  : String;
Begin
    Result := False;
    // Access to Altium workspace
    Workspace := GetWorkspace;
    If Workspace = Nil Then
    Begin
        ShowMessage('Cannot access the workspace.');
        Exit;
    End;

    // Get active PCB document
    PCB_Board := PCBServer.GetCurrentPCBBoard;
    If PCB_Board = Nil Then
    Begin
        ShowMessage('No active PCB document.');
        Exit;
    End;

    // Get name of the board
    PCB_FileName := PCB_Board.FileName;
    If PCB_FileName = '' Then
    Begin
        ShowMessage('Save the PCB file before continuing.');
        Exit;
    End;

    // Save the PCB
    ResetParameters;
    AddStringParameter('ObjectKind', 'Document');
    RunProcess('WorkspaceManager:SaveObject');
    Result := True;
End;
// Initializes the form and disables certain UI elements by default
procedure TForm1.FormCreate(Sender: TObject);
begin
  FUpdatingLibrarySource := False;
  FBoardReady := False;
  FProcessing := False;
  StopRequested := False;
  BrusaHyPowerAG.Checked := True;
  LibSelection_Custom.Checked := False;
  SetLayerAssignmentsVisible(False);
  SetBoardReady(False);
  BoardStatusLabel.Caption := 'Open a PCB document, then click Refresh.';
  BoardStatusLabel.Width := 410;
  BoardFileNameLabel.Caption := '';
  UpdateLibraryCheckboxes;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if PCBServer.GetCurrentPCBBoard <> nil then
    RefreshButtonClick(Sender);
end;

procedure TForm1.SetBoardReady(Ready: Boolean);
begin
  FBoardReady := Ready;
  SourceGroupBox.Enabled := Ready;
  BoardStatusGroupBox.Enabled := Ready;
  BrusaHyPowerAG.Enabled := Ready;
  LibSelection_Custom.Enabled := Ready;
  LibSourceSelection_HyPower_Prod.Enabled := Ready and BrusaHyPowerAG.Checked;
  LibSourceSelection_HyPower_DBLIB.Enabled := Ready and BrusaHyPowerAG.Checked;
  sourceLibrary_Save.Enabled := False;
  LayerGroupBox.Enabled := Ready;
  TOP_DES.Enabled := Ready;
  TOP_ASM.Enabled := Ready;
  BOT_DES.Enabled := Ready;
  BOT_ASM.Enabled := Ready;
  topDesignatorSelection_ComboBox.Enabled := False;
  topAssemblySelection_ComboBox.Enabled := False;
  bottomDesignatorSelection_ComboBox.Enabled := False;
  bottomAssemblySelection_ComboBox.Enabled := False;
  BoardStatusLabel.Visible := True;
  SetLayerAssignmentsVisible(Ready);
end;

procedure TForm1.RefreshButtonClick(Sender: TObject);
var
  Board: IPCB_Board;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    SetBoardReady(False);
    BoardStatusLabel.Caption := 'Open a PCB document, then click Refresh.';
    BoardStatusLabel.Width := 390;
    BoardFileNameLabel.Caption := '';
    BoardStatusLabel.Font.Color := clRed;
    ShowMessage('Please open a PCB document first, then click Refresh.');
    Exit;
  end;

  FillAllLayerCombos;
  SetBoardReady(True);
  UpdateLibraryCheckboxes;
  BoardStatusLabel.Caption := '';
  if Board.FileName <> '' then
    BoardFileNameLabel.Caption := ExtractFileName(Board.FileName)
  else
    BoardFileNameLabel.Caption := 'PCB document ready.';
end;

// Updates the state of library-related checkboxes based on user selection
procedure TForm1.UpdateLibraryCheckboxes;
begin
  if FBoardReady and BrusaHyPowerAG.Checked then
  begin
    LibSourceSelection_HyPower_Prod.Enabled := True;
    LibSourceSelection_HyPower_DBLIB.Enabled := True;
  end
  else
  begin
    LibSourceSelection_HyPower_Prod.Enabled := False;
    LibSourceSelection_HyPower_DBLIB.Enabled := False;
  end;

  if FBoardReady and LibSelection_Custom.Checked then
  begin
    LibSourceSelection_HyPower_Prod.Enabled := False;
    LibSourceSelection_HyPower_DBLIB.Enabled := False;
    FillAllLayerCombos;
  end;

  if FBoardReady and BrusaHyPowerAG.Checked then
    SetDefaultLayerAssignments;

  if not BrusaHyPowerAG.Checked then
  begin
    FUpdatingLibrarySource := True;
    try
      LibSourceSelection_HyPower_Prod.Checked := False;
      LibSourceSelection_HyPower_DBLIB.Checked := False;
    finally
      FUpdatingLibrarySource := False;
    end;
  end;
  topDesignatorSelection_ComboBox.Enabled := FBoardReady and LibSelection_Custom.Checked;
  topAssemblySelection_ComboBox.Enabled := FBoardReady and LibSelection_Custom.Checked;
  bottomDesignatorSelection_ComboBox.Enabled := FBoardReady and LibSelection_Custom.Checked;
  bottomAssemblySelection_ComboBox.Enabled := FBoardReady and LibSelection_Custom.Checked;
  sourceLibrary_Save.Enabled := FBoardReady and
    (LibSelection_Custom.Checked or
     (BrusaHyPowerAG.Checked and
      (LibSourceSelection_HyPower_Prod.Checked or LibSourceSelection_HyPower_DBLIB.Checked)));
  SetLayerAssignmentsVisible(FBoardReady);
end;

// Shows/hides custom layer selection UI elements
procedure TForm1.SetLayerAssignmentsVisible(Visible: Boolean);
begin
  LayerGroupBox.Visible := Visible;
  BOT_DES.Visible := Visible;
  BOT_ASM.Visible := Visible;
  TOP_DES.Visible := Visible;
  TOP_ASM.Visible := Visible;
  topDesignatorSelection_ComboBox.Visible := Visible;
  topAssemblySelection_ComboBox.Visible := Visible;
  bottomDesignatorSelection_ComboBox.Visible := Visible;
  bottomAssemblySelection_ComboBox.Visible := Visible;
end;

// Toggles between HyPower library source options (PROD or DBLIB)
procedure TForm1.Toggle_HyPowerLibrary(Selected: string);
begin
  if FUpdatingLibrarySource then Exit;
  FUpdatingLibrarySource := True;
  try
    LibSourceSelection_HyPower_Prod.Checked := Selected = 'PROD';
    LibSourceSelection_HyPower_DBLIB.Checked := Selected = 'DBLIB';
  finally
    FUpdatingLibrarySource := False;
  end;
  UpdateLibraryCheckboxes;
end;

// Populates all layer combo boxes with available PCB layers
procedure TForm1.FillAllLayerCombos;
var
  PCB_Board: IPCB_Board;
  LayerName: String;
  i: Integer;
  Entry: String;
begin
  topDesignatorSelection_ComboBox.Items.Clear;
  topAssemblySelection_ComboBox.Items.Clear;
  bottomDesignatorSelection_ComboBox.Items.Clear;
  bottomAssemblySelection_ComboBox.Items.Clear;
  PCB_Board := PCBServer.GetCurrentPCBBoard;
  if PCB_Board = nil then
  begin
    ShowMessage('No PCB document is open.');
    Exit;
  end;
  for i := FIRST_SUPPORTED_LAYER_INDEX to LAST_SUPPORTED_LAYER_INDEX do
  begin
    try
      LayerName := PCB_Board.LayerName(i);
      if (LayerName = '') and (i >= FIRST_MECHANICAL_LAYER_INDEX) and
         (i <= LAST_SUPPORTED_LAYER_INDEX) then
        LayerName := PCB_Board.LayerStack.GetMechanicalLayerName(i);
      LayerName := Trim(LayerName);
      if (LayerName <> '') and (UpperCase(LayerName) <> 'NOLAYER') and
         (UpperCase(LayerName) <> 'NO LAYER') then
      begin
        Entry := Format('%d - %s', [i, LayerName]);
        topDesignatorSelection_ComboBox.Items.Add(Entry);
        topAssemblySelection_ComboBox.Items.Add(Entry);
        bottomDesignatorSelection_ComboBox.Items.Add(Entry);
        bottomAssemblySelection_ComboBox.Items.Add(Entry);
      end;
    except
    end;
  end;
end;

// Event handlers for UI elements
procedure TForm1.BrusaHyPowerAGClick(Sender: TObject);
begin
  UpdateLibraryCheckboxes;
end;

procedure TForm1.LibSelection_CustomClick(Sender: TObject);
begin
  UpdateLibraryCheckboxes;
end;

procedure TForm1.LibSourceSelection_HyPower_ProdClick(Sender: TObject);
begin
  if not FUpdatingLibrarySource then
    Toggle_HyPowerLibrary('PROD');
end;

procedure TForm1.LibSourceSelection_HyPower_DBLIBClick(Sender: TObject);
begin
  if not FUpdatingLibrarySource then
    Toggle_HyPowerLibrary('DBLIB');
end;

// Deletes manual text objects from the selected designator layers.
procedure DeleteManualTextsOnDesignatorLayers(TopLayer, BottomLayer: Integer);
var
  Board: IPCB_Board;
  Iterator: IPCB_BoardIterator;
  TextObj: IPCB_Text;
  NextText: IPCB_Text;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;
  Iterator := nil;
  PCBServer.PreProcess;
  try
    Iterator := Board.BoardIterator_Create;
    try
      Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
      Iterator.AddFilter_LayerSet(MkSet(TopLayer, BottomLayer));
      TextObj := Iterator.FirstPCBObject;
      while TextObj <> nil do
      begin
        if not ContinueProcessing then Break;
        NextText := Iterator.NextPCBObject;
        if (TextObj.Component = nil) and (not TextObj.IsDesignator) then
        begin
          Board.RemovePCBObject(TextObj);
          PCBServer.DestroyPCBObject(TextObj);
        end;
        TextObj := NextText;
      end;
    finally
      if Iterator <> nil then
        Board.BoardIterator_Destroy(Iterator);
    end;
  finally
    PCBServer.PostProcess;
  end;
end;

// Checks if a component is a test point by its footprint pattern
function IsTestPointComponent(Component: IPCB_Component): Boolean;
var
  Footprint: String;
  CommentText: String;
begin
  Result := False;
  if Component = nil then Exit;
  Footprint := UpperCase(Component.Pattern);
  CommentText := '';
  if Component.Comment <> nil then
    CommentText := UpperCase(Component.Comment.Text);
  Result := (Pos('TESTPOINT', Footprint) > 0) or
    (Pos('TESTPOINT', CommentText) > 0) or
    (Footprint = 'TESTPOINT_1MM') or
    (Footprint = 'TESTPOINT_0.8MM') or
    (Footprint = 'TESTING-PCC_TESTPOINT_1MM');
end;

// Checks if a component is from a Brusa library
function IsBrusaComponent(Component: IPCB_Component): Boolean;
var
  LibPath: String;
begin
  Result := False;
  if Component = nil then Exit;
  LibPath := UpperCase(Component.SourceComponentLibrary);
  Result := (Pos('BRUSA HYPOWER PROD', LibPath) > 0) or
    (Pos('BRUSA_ALTIUMLIB_DATABASE', LibPath) > 0);
end;

// Clears designator text objects from the source layers.
procedure ClearDesignatorsFromSourceLayers(Board: IPCB_Board; Component: IPCB_Component);
var
  Iterator: IPCB_GroupIterator;
  TextObj: IPCB_Text;
  NextText: IPCB_Text;
begin
  Iterator := Component.GroupIterator_Create;
  try
    Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
    Iterator.AddFilter_LayerSet(MkSet(SOURCE_TOP_LAYER, SOURCE_BOTTOM_LAYER));
    TextObj := Iterator.FirstPCBObject;
    while TextObj <> nil do
    begin
      if not ContinueProcessing then Break;
      NextText := Iterator.NextPCBObject;
      if (TextObj.IsDesignator) or (TextObj.UnderlyingString = '.Designator') then
      begin
        Board.RemovePCBObject(TextObj);
        Component.RemovePCBObject(TextObj);
        PCBServer.DestroyPCBObject(TextObj);
      end;
      TextObj := NextText;
    end;
  finally
    if Iterator <> nil then
      Component.GroupIterator_Destroy(Iterator);
  end;
end;

// Clears non-designator text objects from the selected assembly layers.
procedure ClearTextObjectsFromLayers(Board: IPCB_Board; Component: IPCB_Component; TopLayer, BottomLayer: Integer);
var
  Iterator: IPCB_GroupIterator;
  TextObj: IPCB_Text;
  NextText: IPCB_Text;
begin
  Iterator := Component.GroupIterator_Create;
  try
    Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
    Iterator.AddFilter_LayerSet(MkSet(TopLayer, BottomLayer));
    TextObj := Iterator.FirstPCBObject;
    while TextObj <> nil do
    begin
      if not ContinueProcessing then Break;
      NextText := Iterator.NextPCBObject;
      if not (TextObj.IsDesignator or (TextObj.UnderlyingString = '.Designator')) then
      begin
        Board.RemovePCBObject(TextObj);
        Component.RemovePCBObject(TextObj);
        PCBServer.DestroyPCBObject(TextObj);
      end;
      TextObj := NextText;
    end;
  finally
    if Iterator <> nil then
      Component.GroupIterator_Destroy(Iterator);
  end;
end;

// Copies objects from source layer to target layer for a component
procedure CopyLayerObjects(Board: IPCB_Board; Component: IPCB_Component; SourceLayer, TargetLayer: Integer);
var
  Iterator: IPCB_GroupIterator;
  Primitive, NewPrimitive: IPCB_Primitive;
  AddedToBoard, AddedToComponent: Boolean;
begin
  Iterator := Component.GroupIterator_Create;
  try
    Iterator.AddFilter_ObjectSet((AllPrimitives));
    Iterator.AddFilter_LayerSet(MkSet(SourceLayer));
    Primitive := Iterator.FirstPCBObject;
    while Primitive <> nil do
    begin
      if not ContinueProcessing then Break;
      if ((Primitive.ObjectId <> eTextObject) or (not Primitive.IsDesignator)) and
         (Primitive.ObjectId <> eComponentBodyObject) then
      begin
        NewPrimitive := Primitive.Replicate;
        if NewPrimitive <> nil then
        begin
          AddedToBoard := False;
          AddedToComponent := False;
          try
            NewPrimitive.BeginModify;
            try
              NewPrimitive.Layer := TargetLayer;
            finally
              NewPrimitive.EndModify;
            end;
            Board.AddPCBObject(NewPrimitive);
            AddedToBoard := True;
            Component.AddPCBObject(NewPrimitive);
            AddedToComponent := True;
          finally
            if not AddedToComponent then
            begin
              if AddedToBoard then
                Board.RemovePCBObject(NewPrimitive);
              PCBServer.DestroyPCBObject(NewPrimitive);
            end;
          end;
        end;
      end;
      Primitive := Iterator.NextPCBObject;
    end;
  finally
    if Iterator <> nil then
      Component.GroupIterator_Destroy(Iterator);
  end;
end;

// Creates centered designators for all components on the board
procedure CreateCenteredDesignatorsForAllComponents(TopLayer, BottomLayer: Integer;
  MirrorBottomDesignators: Boolean);
var
  Board: IPCB_Board;
  Comp: IPCB_Component;
  Iterator: IPCB_BoardIterator;
  Designator: IPCB_Text;
  CompRect, DesignatorRect: TCoordRect;
  CenterX, CenterY, OffsetX, OffsetY: TCoord;
  DesignatorCenterX, DesignatorCenterY: TCoord;
  TextHeight, StrokeWidth: Integer;
  ScaleFactor: Double;
  TargetLayer: Integer;
  DesignatorText: String;
  AddedToBoard, AddedToComponent: Boolean;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;
  Iterator := nil;
  Iterator := Board.BoardIterator_Create;
  try
    Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
    Iterator.AddFilter_LayerSet((AllLayers));
    Iterator.AddFilter_Method(eProcessAll);
    Comp := Iterator.FirstPCBObject;
    while Comp <> nil do
    begin
    if not ContinueProcessing then Break;
    if IsTestPointComponent(Comp) then
    begin
      Comp := Iterator.NextPCBObject;
      Continue;
    end;
    if Comp.Layer = eTopLayer then TargetLayer := TopLayer
    else if Comp.Layer = eBottomLayer then TargetLayer := BottomLayer
    else
    begin
      Comp := Iterator.NextPCBObject;
      Continue;
    end;
    CompRect := Comp.BoundingRectangleNoNameCommentForSignals;
    CenterX := (CompRect.Left + CompRect.Right) div 2;
    CenterY := (CompRect.Top + CompRect.Bottom) div 2;
  TextHeight := MilsToCoord(DESIGNATOR_INITIAL_HEIGHT_MILS);
    StrokeWidth := TextHeight div 10;
    Designator := PCBServer.PCBObjectFactory(eTextObject, eNoDimension, eCreate_Default);
    if Designator = nil then
    begin
      Comp := Iterator.NextPCBObject;
      Continue;
    end;
    AddedToBoard := False;
    AddedToComponent := False;
    PCBServer.PreProcess;
    try
      if (Comp.Name <> nil) and (Comp.Name.Text <> '') then
        DesignatorText := Comp.Name.Text
      else
        DesignatorText := 'UNKNOWN';
      Designator.BeginModify;
      try
        Designator.Layer := TargetLayer;
        Designator.Text := DesignatorText;
        Designator.UnderlyingString := '.Designator';
        Designator.Component := Comp;
        Designator.Size := TextHeight;
        Designator.Width := StrokeWidth;
        Designator.UseTTFonts := True;
        if TargetLayer = BottomLayer then
          Designator.MirrorFlag := MirrorBottomDesignators;
        Designator.TTFInvertedTextJustify := eAutoPos_CenterCenter;
        Designator.Rotation := Comp.Rotation;
        Designator.XLocation := CenterX;
        Designator.YLocation := CenterY;
      finally
        Designator.EndModify;
      end;
      Board.AddPCBObject(Designator);
      AddedToBoard := True;
      Comp.AddPCBObject(Designator);
      AddedToComponent := True;
      ScaleFactor := DESIGNATOR_SHRINK_FACTOR;
      repeat
        if not ContinueProcessing then Break;
        DesignatorRect := Designator.BoundingRectangle;
        if (DesignatorRect.Left >= CompRect.Left) and
           (DesignatorRect.Right <= CompRect.Right) and
           (DesignatorRect.Top <= CompRect.Top) and
           (DesignatorRect.Bottom >= CompRect.Bottom) then
          Break;
        Designator.BeginModify;
        try
          Designator.Size := Round(Designator.Size * ScaleFactor);
          Designator.Width := Round(Designator.Width * ScaleFactor);
          Designator.XLocation := CenterX;
          Designator.YLocation := CenterY;
        finally
          Designator.EndModify;
        end;
      until Designator.Size < MilsToCoord(DESIGNATOR_MIN_HEIGHT_MILS);
      DesignatorRect := Designator.BoundingRectangle;
      DesignatorCenterX := (DesignatorRect.Left + DesignatorRect.Right) div 2;
      DesignatorCenterY := (DesignatorRect.Top + DesignatorRect.Bottom) div 2;
      OffsetX := CenterX - DesignatorCenterX;
      OffsetY := CenterY - DesignatorCenterY;
      Designator.MoveByXY(OffsetX, OffsetY);
      Designator.GraphicallyInvalidate;
    finally
      try
        if not AddedToComponent then
        begin
          if AddedToBoard then
            Board.RemovePCBObject(Designator);
          PCBServer.DestroyPCBObject(Designator);
        end;
      finally
        PCBServer.PostProcess;
      end;
    end;
      Comp := Iterator.NextPCBObject;
    end;
  finally
    if Iterator <> nil then
      Board.BoardIterator_Destroy(Iterator);
  end;
  Board.ViewManager_FullUpdate;
  
end;

// Main processing function for all components on the board
procedure ProcessAllComponents(TopDesignatorLayer, BottomDesignatorLayer,
  TopAssemblyLayer, BottomAssemblyLayer: Integer; MirrorBottomDesignators: Boolean);
var
  Board: IPCB_Board;
  Component: IPCB_Component;
  Iterator: IPCB_BoardIterator;
  TargetWidth : TCoord;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    RefreshButtonClick(Sender);
    Exit;
  end;
  DeleteManualTextsOnDesignatorLayers(TopDesignatorLayer, BottomDesignatorLayer);
  if not ContinueProcessing then Exit;
  Iterator := nil;
  PCBServer.PreProcess;
  try
    Iterator := Board.BoardIterator_Create;
    try
      Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
      Iterator.AddFilter_LayerSet((AllLayers));
      Iterator.AddFilter_Method(eProcessAll);
      Component := Iterator.FirstPCBObject;
      while Component <> nil do
      begin
        if not ContinueProcessing then Break;
        if not IsBrusaComponent(Component) then
        begin
          ClearDesignatorsFromSourceLayers(Board, Component);
          ClearTextObjectsFromLayers(Board, Component, TopAssemblyLayer, BottomAssemblyLayer);
          if not IsTestPointComponent(Component) then
          begin
            if Component.Layer = eTopLayer then
              CopyLayerObjects(Board, Component, SOURCE_TOP_LAYER, TopAssemblyLayer)
            else if Component.Layer = eBottomLayer then
              CopyLayerObjects(Board, Component, SOURCE_BOTTOM_LAYER, BottomAssemblyLayer);
          end;
        end;
        Component := Iterator.NextPCBObject;
      end;
    finally
      if Iterator <> nil then
        Board.BoardIterator_Destroy(Iterator);
    end;
  finally
    PCBServer.PostProcess;
  end;
  if not ContinueProcessing then Exit;
  CreateCenteredDesignatorsForAllComponents(TopDesignatorLayer, BottomDesignatorLayer,
    MirrorBottomDesignators);
  if not ContinueProcessing then Exit;
  if not SaveCurrentPCB then Exit;
  if not ContinueProcessing then Exit;
  TargetWidth := MMsToCoord(ASSEMBLY_TRACK_WIDTH_MM);

  // Top assembly output layer.
  ProcessTracksOnLayer(TopAssemblyLayer, TargetWidth);
  if not ContinueProcessing then Exit;
  ProcessArcsOnLayer(TopAssemblyLayer, TargetWidth);
  if not ContinueProcessing then Exit;

  // Bottom assembly output layer.
  ProcessTracksOnLayer(BottomAssemblyLayer, TargetWidth);
  if not ContinueProcessing then Exit;
  ProcessArcsOnLayer(BottomAssemblyLayer, TargetWidth);
  if not ContinueProcessing then Exit;

  // Save the board
  if not SaveCurrentPCB then Exit;
  
  ShowMessage('Completed successfully.');
end;

// Event handler for the Save button - initiates the main processing
procedure TForm1.sourceLibrary_SaveClick(Sender: TObject);
var
  Board: IPCB_Board;
  TopDesignatorLayer, BottomDesignatorLayer: Integer;
  TopAssemblyLayer, BottomAssemblyLayer: Integer;
begin
  if FProcessing then
  begin
    StopRequested := True;
    sourceLibrary_Save.Caption := 'Stopping...';
    sourceLibrary_Save.Enabled := False;
    Exit;
  end;

  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    RefreshButtonClick(Sender);
    Exit;
  end;
  if GetWorkspace = nil then
  begin
    ShowMessage('Cannot access the Altium workspace.');
    Exit;
  end;
  if Board.FileName = '' then
  begin
    ShowMessage('Save the PCB document before running this operation.');
    Exit;
  end;

  if LibSelection_Custom.Checked then
  begin
    if not TryGetSelectedLayer(topDesignatorSelection_ComboBox, TopDesignatorLayer) or
       not TryGetSelectedLayer(bottomDesignatorSelection_ComboBox, BottomDesignatorLayer) or
       not TryGetSelectedLayer(topAssemblySelection_ComboBox, TopAssemblyLayer) or
       not TryGetSelectedLayer(bottomAssemblySelection_ComboBox, BottomAssemblyLayer) then
    begin
      ShowMessage('Select valid layers for all four custom outputs.');
      Exit;
    end;
    if (TopAssemblyLayer = SOURCE_TOP_LAYER) or
       (TopAssemblyLayer = SOURCE_BOTTOM_LAYER) or
       (BottomAssemblyLayer = SOURCE_TOP_LAYER) or
       (BottomAssemblyLayer = SOURCE_BOTTOM_LAYER) then
    begin
      ShowMessage('Assembly output layers cannot be the source layers.');
      Exit;
    end;
    if (TopDesignatorLayer = BottomDesignatorLayer) or
       (TopDesignatorLayer = TopAssemblyLayer) or
       (TopDesignatorLayer = BottomAssemblyLayer) or
       (BottomDesignatorLayer = TopAssemblyLayer) or
       (BottomDesignatorLayer = BottomAssemblyLayer) or
       (TopAssemblyLayer = BottomAssemblyLayer) then
    begin
      ShowMessage('Select a different layer for each custom output.');
      Exit;
    end;
  end
  else
  begin
    if not BrusaHyPowerAG.Checked then
    begin
      ShowMessage('Select a supported library configuration.');
      Exit;
    end;
    if not (LibSourceSelection_HyPower_Prod.Checked or
            LibSourceSelection_HyPower_DBLIB.Checked) then
    begin
      ShowMessage('Select a HyPower library source.');
      Exit;
    end;
    TopDesignatorLayer := DESIGNATOR_TOP_LAYER;
    BottomDesignatorLayer := DESIGNATOR_BOTTOM_LAYER;
    TopAssemblyLayer := ASSEMBLY_TOP_LAYER;
    BottomAssemblyLayer := ASSEMBLY_BOTTOM_LAYER;
  end;

  FProcessing := True;
  StopRequested := False;
  sourceLibrary_Save.Caption := 'Stop';
  sourceLibrary_Save.Enabled := True;
  BrusaHyPowerAG.Enabled := False;
  LibSelection_Custom.Enabled := False;
  LibSourceSelection_HyPower_Prod.Enabled := False;
  LibSourceSelection_HyPower_DBLIB.Enabled := False;
  LayerGroupBox.Enabled := False;
  RefreshButton.Enabled := False;
  try
    UnlockAllComponents;
    if not ContinueProcessing then Exit;
    DeleteOnlyComponentDesignators(TopDesignatorLayer, BottomDesignatorLayer);
    if not ContinueProcessing then Exit;
    ProcessAllComponents(TopDesignatorLayer, BottomDesignatorLayer,
      TopAssemblyLayer, BottomAssemblyLayer, BottomDesignatorMirrorCheckBox.Checked);
  finally
    if StopRequested then
      ShowMessage('Processing stopped. Changes already applied were not rolled back.');
    FProcessing := False;
    StopRequested := False;
    sourceLibrary_Save.Caption := 'Start';
    BrusaHyPowerAG.Enabled := FBoardReady;
    LibSelection_Custom.Enabled := FBoardReady;
    RefreshButton.Enabled := True;
    UpdateLibraryCheckboxes;
  end;
end;

// Unlocks all components on the board to make them movable
procedure TForm1.UnlockAllComponents;
var
  PCB_Board: IPCB_Board;
  Iterator: IPCB_BoardIterator;
  Comp: IPCB_Component;
  WasSelected: Boolean;
begin
  PCB_Board := PCBServer.GetCurrentPCBBoard;
  if PCB_Board = nil then
  begin
    ShowMessage('PCB board not found.');
    Exit;
  end;
  Iterator := nil;
  PCBServer.PreProcess;
  try
    Iterator := PCB_Board.BoardIterator_Create;
    try
      Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
      Iterator.AddFilter_LayerSet(AllLayers);
      Iterator.AddFilter_Method(eProcessAll);
      Comp := Iterator.FirstPCBObject;
      while Comp <> nil do
      begin
        if not ContinueProcessing then Break;
        WasSelected := Comp.Selected;
        Comp.BeginModify;
        try
          Comp.PrimitiveLock := False;
          Comp.Selected := True;
          Comp.Moveable := True;
        finally
          try
            Comp.Selected := WasSelected;
          finally
            Comp.EndModify;
          end;
        end;
        Comp := Iterator.NextPCBObject;
      end;
    finally
      if Iterator <> nil then
        PCB_Board.BoardIterator_Destroy(Iterator);
    end;
  finally
    PCBServer.PostProcess;
  end;
  
end;

// Deletes component designators from specified layers
procedure TForm1.DeleteOnlyComponentDesignators(TopLayer, BottomLayer: Integer);
var
  Board: IPCB_Board;
  Iterator: IPCB_BoardIterator;
  TextObj: IPCB_Text;
  NextObject: IPCB_Text;
  UnderlyingStr: String;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    ShowMessage('PCB document is not currently open.');
    Exit;
  end;

  Iterator := nil;
  PCBServer.PreProcess;
  try
    // Single iteration for both target layers
    Iterator := Board.BoardIterator_Create;
    try
      Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
      Iterator.AddFilter_LayerSet(MkSet(TopLayer, BottomLayer));
      Iterator.AddFilter_Method(eProcessAll);

      TextObj := Iterator.FirstPCBObject;
      while TextObj <> nil do
      begin
        if not ContinueProcessing then Break;
        // Store next object before potential deletion
        NextObject := Iterator.NextPCBObject;

        // Get and clean underlying string
        UnderlyingStr := TextObj.UnderlyingString;

        // Check for both '.Designator' and quoted version
        if ((UnderlyingStr = '.Designator') or (UnderlyingStr = ''''+'.Designator'+'''')) and (TextObj.Component <> nil) then
        begin
          // First remove from component
          if TextObj.Component <> nil then
            TextObj.Component.RemovePCBObject(TextObj);

          // Remove from board and destroy
          Board.RemovePCBObject(TextObj);
          PCBServer.DestroyPCBObject(TextObj);
        end;

        TextObj := NextObject;
      end;
    finally
      if Iterator <> nil then
        Board.BoardIterator_Destroy(Iterator);
    end;
  finally
    PCBServer.PostProcess;
  end;

  Board.ViewManager_FullUpdate;
  Board.GraphicallyInvalidate;

end;

procedure RunBrusaASM;
begin
  Form1.ShowModal;
end;

end.
