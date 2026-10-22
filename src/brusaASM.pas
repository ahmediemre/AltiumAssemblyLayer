unit brusaASM;

interface

uses
  System.SysUtils, System.Classes, Forms, Controls, StdCtrls, Dialogs,
  PCB, PCBConst, Windows;

type
  TForm1 = class(TForm)
   // Form UI Components
    BrusaHyPowerAG: TRadioButton;               					// Toggles HyPower library selection
    LibSourceSelection_HyPower_Prod: TCheckBox; 					// Selects production library source
    LibSourceSelection_HyPower_DBLIB: TCheckBox;					// Selects database library source
    LibSelection_BrusaElectronics: TRadioButton;					// Selects Brusa Electronics library
    LibSourceSelection_BrusaElectronics: TCheckBox; 				// Enables Brusa Electronics source
    LibSelection_BrusaICS: TRadioButton;        					// Selects Brusa ICS library
    LibSourceSelection_BrusaICS: TCheckBox;     					// Enables Brusa ICS source
    LibSelection_Custom: TRadioButton;          					// Enables custom library configuration
    sourceLibrary_Save: TButton;                					// Triggers the main processing
    BOT_DES: TLabel;                           						// Bottom designator layer label
    BOT_ASM: TLabel;                           						// Bottom assembly layer label
    TOP_DES: TLabel;                           						// Top designator layer label
    TOP_ASM: TLabel;                           						// Top assembly layer label
    LayerNumbers: TLabel;                      						// Layer numbers label
    topDesignatorSelection_ComboBox: TComboBox; 					// Top designator layer selection
    topAssemblySelection_ComboBox: TComboBox;   					// Top assembly layer selection
    bottomDesignatorSelection_ComboBox: TComboBox; 					// Bottom designator layer selection
    bottomAssemblySelection_ComboBox: TComboBox; 					// Bottom assembly layer selection
    sourceLib: TLabel;                         						// Library source label

    // Event Handlers
    procedure FormCreate(Sender: TObject);      					  // Initializes form
    procedure BrusaHyPowerAGClick(Sender: TObject); 				  // Handles HyPower selection
    procedure LibSelection_BrusaElectronicsClick(Sender: TObject);    // Handles Brusa Electronics selection
    procedure LibSelection_BrusaICSClick(Sender: TObject); 			  // Handles Brusa ICS selection
    procedure LibSelection_CustomClick(Sender: TObject); 			  // Handles custom selection
    procedure LibSourceSelection_HyPower_ProdClick(Sender: TObject);  // Handles production source selection
    procedure LibSourceSelection_HyPower_DBLIBClick(Sender: TObject); // Handles DB library source selection
    procedure sourceLibrary_SaveClick(Sender: TObject); 			  // Main processing trigger
  private
    // Helper Methods
    procedure UpdateLibraryCheckboxes;          					// Updates UI based on selections
    procedure SetCustomLayerLabelsVisible(Visible: Boolean); 		// Toggles custom layer UI
    procedure Toggle_HyPowerLibrary(Selected: string); 				// Manages HyPower library options
    procedure FillAllLayerCombos;              						// Populates layer selection comboboxes
    procedure UnlockAllComponents;             						// Unlocks all PCB components
    procedure DeleteOnlyComponentDesignators;  						// Removes existing designators
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure ProcessTracksOnLayer(Layer: TLayer; NewWidth: TCoord);
var
  Board    : IPCB_Board;
  Iterator : IPCB_BoardIterator;
  Track    : IPCB_Track;
  Modified : Integer;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;

  Modified := 0;
  PCBServer.PreProcess;

  try
    // Align all component ASM tracks track width, we shouldn't select and edit tracks and arcs at the same time!
    Iterator := Board.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eTrackObject));
    Iterator.AddFilter_LayerSet(MkSet(Layer));
    Iterator.AddFilter_Method(eProcessAll);

    Track := Iterator.FirstPCBObject;
    while Track <> nil do
    begin
      Track.BeginModify;
      Track.Selected := True; // Only select & modify tracks
      Track.Width := NewWidth;
      Track.EndModify;
      Track.GraphicallyInvalidate;
      Inc(Modified);
      Track := Iterator.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iterator);

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
  Modified : Integer;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;

  Modified := 0;
  PCBServer.PreProcess;

  try
  
    Iterator := Board.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eArcObject));
    Iterator.AddFilter_LayerSet(MkSet(Layer));
    Iterator.AddFilter_Method(eProcessAll);

    Arc := Iterator.FirstPCBObject;
    while Arc <> nil do
    begin
      Arc.BeginModify;
      Arc.Selected := True; // select only arcs
      Arc.LineWidth := NewWidth;
      Arc.EndModify;
      Arc.GraphicallyInvalidate;
      Inc(Modified);
      Arc := Iterator.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iterator);

  finally
    PCBServer.PostProcess;
  end;
end;

procedure ClearSelections;
var
  Board    : IPCB_Board;
  Iterator : IPCB_BoardIterator;
  Prim     : IPCB_Primitive;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;

  Iterator := Board.BoardIterator_Create;
  Iterator.AddFilter_Method(eProcessAll);

  Prim := Iterator.FirstPCBObject;
  while Prim <> nil do
  begin
    Prim.Selected := False;
    Prim := Iterator.NextPCBObject;
  end;
  Board.BoardIterator_Destroy(Iterator);
end;

procedure SaveCurrentPCB;
Var
    PCB_Board     : IPCB_Board;
    Workspace     : IWorkspace;
    PCB_FileName  : String;
    Document      : IDocument;
Begin
    // Access to Altium workspace
    Workspace := GetWorkspace;
    If Workspace = Nil Then
    Begin
        ShowMessage('Can not Access to Workspace!');
        Exit;
    End;

    // Get active PCB document
    PCB_Board := PCBServer.GetCurrentPCBBoard;
    If PCB_Board = Nil Then
    Begin
        ShowMessage('No Active PCB Document!');
        Exit;
    End;

    // Get name of the board
    PCB_FileName := PCB_Board.FileName;
    If PCB_FileName = '' Then
    Begin
        ShowMessage('PCB File not saved, please save it to continue!');
        Exit;
    End;

    // Save the PCB
    ResetParameters;
    AddStringParameter('ObjectKind', 'Document');
    RunProcess('WorkspaceManager:SaveObject');
End;
// Initializes the form and disables certain UI elements by default
procedure TForm1.FormCreate(Sender: TObject);
begin
  LibSelection_BrusaElectronics.Enabled := False;
  LibSourceSelection_BrusaElectronics.Enabled := False;
  LibSelection_BrusaICS.Enabled := False;
  LibSourceSelection_BrusaICS.Enabled := False;
  LibSelection_Custom.Checked := False;
  SetCustomLayerLabelsVisible(False);
  UpdateLibraryCheckboxes;
end;

// Updates the state of library-related checkboxes based on user selection
procedure TForm1.UpdateLibraryCheckboxes;
begin
  if BrusaHyPowerAG.Checked then
  begin
    LibSourceSelection_HyPower_Prod.Enabled := True;
    LibSourceSelection_HyPower_DBLIB.Enabled := True;
    SetCustomLayerLabelsVisible(False);
  end
  else
  begin
    LibSourceSelection_HyPower_Prod.Enabled := False;
    LibSourceSelection_HyPower_Prod.Checked := False;
    LibSourceSelection_HyPower_DBLIB.Enabled := False;
    LibSourceSelection_HyPower_DBLIB.Checked := False;
  end;

  if LibSelection_Custom.Checked then
  begin
    LibSourceSelection_HyPower_Prod.Enabled := False;
    LibSourceSelection_HyPower_Prod.Checked := False;
    LibSourceSelection_HyPower_DBLIB.Enabled := False;
    LibSourceSelection_HyPower_DBLIB.Checked := False;
    FillAllLayerCombos;
  end;
  SetCustomLayerLabelsVisible(LibSelection_Custom.Checked);
end;

// Shows/hides custom layer selection UI elements
procedure TForm1.SetCustomLayerLabelsVisible(Visible: Boolean);
begin
  BOT_DES.Visible := Visible;
  BOT_ASM.Visible := Visible;
  TOP_DES.Visible := Visible;
  TOP_ASM.Visible := Visible;
  LayerNumbers.Visible := Visible;
  topDesignatorSelection_ComboBox.Visible := Visible;
  topAssemblySelection_ComboBox.Visible := Visible;
  bottomDesignatorSelection_ComboBox.Visible := Visible;
  bottomAssemblySelection_ComboBox.Visible := Visible;
end;

// Toggles between HyPower library source options (PROD or DBLIB)
procedure TForm1.Toggle_HyPowerLibrary(Selected: string);
begin
  LibSourceSelection_HyPower_Prod.OnClick := nil;
  LibSourceSelection_HyPower_DBLIB.OnClick := nil;
  if Selected = 'PROD' then
    LibSourceSelection_HyPower_Prod.Checked := True
  else
    LibSourceSelection_HyPower_DBLIB.Checked := True;
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
    ShowMessage('No PCB document is open!');
    Exit;
  end;
  for i := 0 to 150 do
  begin
    try
      LayerName := PCB_Board.LayerName(i);
      if (LayerName = '') and (i >= 32) and (i <= 150) then
        LayerName := PCB_Board.LayerStack.GetMechanicalLayerName(i);
      if (Trim(LayerName) <> '') and (Trim(LayerName) <> 'No Layer') then
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

procedure TForm1.LibSelection_BrusaElectronicsClick(Sender: TObject);
begin
  UpdateLibraryCheckboxes;
end;

procedure TForm1.LibSelection_BrusaICSClick(Sender: TObject);
begin
  UpdateLibraryCheckboxes;
end;

procedure TForm1.LibSelection_CustomClick(Sender: TObject);
begin
  UpdateLibraryCheckboxes;
end;

procedure TForm1.LibSourceSelection_HyPower_ProdClick(Sender: TObject);
begin
  Toggle_HyPowerLibrary('PROD');
end;

procedure TForm1.LibSourceSelection_HyPower_DBLIBClick(Sender: TObject);
begin
  Toggle_HyPowerLibrary('DBLIB');
end;

// Deletes manual text objects from layers 68 and 69
procedure DeleteManualTextsOnLayers68_69(var ManualTextsDeleted: Integer);
var
  Board: IPCB_Board;
  Iterator: IPCB_BoardIterator;
  TextObj: IPCB_Text;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;
  ManualTextsDeleted := 0;
  PCBServer.PreProcess;
  try
    Iterator := Board.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
    Iterator.AddFilter_LayerSet(MkSet(68, 69));
    TextObj := Iterator.FirstPCBObject;
    while TextObj <> nil do
    begin
      if (TextObj.Component = nil) and (not TextObj.IsDesignator) then
      begin
        Board.RemovePCBObject(TextObj);
        Inc(ManualTextsDeleted);
      end;
      TextObj := Iterator.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iterator);
  finally
    PCBServer.PostProcess;
  end;
end;

// Checks if a component is a test point by its footprint pattern
function IsTestPointComponent(Component: IPCB_Component): Boolean;
var
  Footprint: String;
begin
  Result := False;
  try
    Footprint := UpperCase(Component.Pattern);
    if (Footprint = 'TESTPOINT_1MM') or (Footprint = 'TESTPOINT_0.8MM') or (UpperCase(Footprint) = 'TESTING-PCC_TESTPOINT_1MM')then
      Result := True;
  except
  end;
end;

// Checks if a component is from a Brusa library
function IsBrusaComponent(Component: IPCB_Component): Boolean;
var
  LibPath: String;
begin
  Result := False;
  try
    LibPath := UpperCase(Component.SourceComponentLibrary);
    if Pos('BRUSA HYPOWER PROD', LibPath) > 0 then Result := True;
  except
  end;
end;

// Clears designator text objects from layers 61 and 62
procedure ClearDesignatorsFromSourceLayers(Board: IPCB_Board; Component: IPCB_Component; var ClearCount61, ClearCount62: Integer);
var
  Iterator: IPCB_GroupIterator;
  TextObj: IPCB_Text;
begin
  Iterator := Component.GroupIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
  Iterator.AddFilter_LayerSet(MkSet(61, 62));
  TextObj := Iterator.FirstPCBObject;
  while TextObj <> nil do
  begin
    if (TextObj.IsDesignator) or (TextObj.UnderlyingString = '.Designator') then
    begin
      if TextObj.Layer = 61 then Inc(ClearCount61)
      else Inc(ClearCount62);
      Board.RemovePCBObject(TextObj);
      Component.RemovePCBObject(TextObj);
      PCBServer.DestroyPCBObject(TextObj);
    end;
    TextObj := Iterator.NextPCBObject;
  end;
  Component.GroupIterator_Destroy(Iterator);
end;

// Clears non-designator text objects from layers 66 and 67
procedure ClearTextObjectsFromLayers(Board: IPCB_Board; Component: IPCB_Component; var TopClearCount, BottomClearCount: Integer);
var
  Iterator: IPCB_GroupIterator;
  TextObj: IPCB_Text;
begin
  Iterator := Component.GroupIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
  Iterator.AddFilter_LayerSet(MkSet(66, 67));
  TextObj := Iterator.FirstPCBObject;
  while TextObj <> nil do
  begin
    if not (TextObj.IsDesignator or (TextObj.UnderlyingString = '.Designator')) then
    begin
      if TextObj.Layer = 66 then Inc(TopClearCount)
      else Inc(BottomClearCount);
      Board.RemovePCBObject(TextObj);
      Component.RemovePCBObject(TextObj);
      PCBServer.DestroyPCBObject(TextObj);
    end;
    TextObj := Iterator.NextPCBObject;
  end;
  Component.GroupIterator_Destroy(Iterator);
end;

// Copies objects from source layer to target layer for a component
procedure CopyLayerObjects(Board: IPCB_Board; Component: IPCB_Component; SourceLayer, TargetLayer: Integer; var Counter: Integer);
var
  Iterator: IPCB_GroupIterator;
  Primitive, NewPrimitive: IPCB_Primitive;
begin
  Iterator := Component.GroupIterator_Create;
  Iterator.AddFilter_ObjectSet((AllPrimitives));
  Iterator.AddFilter_LayerSet(MkSet(SourceLayer));
  Primitive := Iterator.FirstPCBObject;
  while Primitive <> nil do
  begin
    if ((Primitive.ObjectId <> eTextObject) or (not Primitive.IsDesignator)) and
       (Primitive.ObjectId <> eComponentBodyObject) then
    begin
      NewPrimitive := Primitive.Replicate;
      if NewPrimitive <> nil then
      begin
        NewPrimitive.BeginModify;
        try
          NewPrimitive.Layer := TargetLayer;
          Board.AddPCBObject(NewPrimitive);
          Component.AddPCBObject(NewPrimitive);
          Inc(Counter);
        finally
          NewPrimitive.EndModify;
        end;
      end;
    end;
    Primitive := Iterator.NextPCBObject;
  end;
  Component.GroupIterator_Destroy(Iterator);
end;

// Creates centered designators for all components on the board
procedure CreateCenteredDesignatorsForAllComponents;
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
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then Exit;
  Iterator := Board.BoardIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
  Iterator.AddFilter_LayerSet((AllLayers));
  Iterator.AddFilter_Method(eProcessAll);
  Comp := Iterator.FirstPCBObject;
  while Comp <> nil do
  begin
    if IsTestPointComponent(Comp) then
    begin
      Comp := Iterator.NextPCBObject;
      Continue;
    end;
    if Comp.Layer = eTopLayer then TargetLayer := 68
    else if Comp.Layer = eBottomLayer then TargetLayer := 69
    else
    begin
      Comp := Iterator.NextPCBObject;
      Continue;
    end;
    CompRect := Comp.BoundingRectangleNoNameCommentForSignals;
    CenterX := (CompRect.Left + CompRect.Right) div 2;
    CenterY := (CompRect.Top + CompRect.Bottom) div 2;
    TextHeight := MilsToCoord(60);
    StrokeWidth := TextHeight div 10;
    Designator := PCBServer.PCBObjectFactory(eTextObject, eNoDimension, eCreate_Default);
    if Designator = nil then
    begin
      Comp := Iterator.NextPCBObject;
      Continue;
    end;
    if (Comp.Name <> nil) and (Comp.Name.Text <> '') then
      DesignatorText := Comp.Name.Text
    else
      DesignatorText := 'UNKNOWN';
    PCBServer.PreProcess;
    try
      Designator.BeginModify;
      Designator.Layer := TargetLayer;
      Designator.Text := DesignatorText;
      Designator.UnderlyingString := '.Designator';
      Designator.Component := Comp;
      Designator.Size := TextHeight;
      Designator.Width := StrokeWidth;
      Designator.UseTTFonts := True;
      Designator.TTFInvertedTextJustify := eAutoPos_CenterCenter;
      // Set designator rotation based on component rotation
      case Comp.Rotation of
        0, 180:   Designator.Rotation := 0;
        90, 270:  Designator.Rotation := 90;
        45, 225:  Designator.Rotation := 45;
        135, 315: Designator.Rotation := 135;
      else
        Designator.Rotation := Comp.Rotation;
      end;
      Designator.XLocation := CenterX;
      Designator.YLocation := CenterY;
      Designator.EndModify;
      Board.AddPCBObject(Designator);
      Comp.AddPCBObject(Designator);
      Designator.GraphicallyInvalidate;
      ScaleFactor := 0.9;
      repeat
        DesignatorRect := Designator.BoundingRectangle;
        if (DesignatorRect.Left >= CompRect.Left) and
           (DesignatorRect.Right <= CompRect.Right) and
           (DesignatorRect.Top <= CompRect.Top) and
           (DesignatorRect.Bottom >= CompRect.Bottom) then
          Break;
        Designator.BeginModify;
        Designator.Size := Round(Designator.Size * ScaleFactor);
        Designator.Width := Round(Designator.Width * ScaleFactor);
        Designator.XLocation := CenterX;
        Designator.YLocation := CenterY;
        Designator.EndModify;
        Designator.GraphicallyInvalidate;
      until Designator.Size < MilsToCoord(10);
      DesignatorRect := Designator.BoundingRectangle;
      DesignatorCenterX := (DesignatorRect.Left + DesignatorRect.Right) div 2;
      DesignatorCenterY := (DesignatorRect.Top + DesignatorRect.Bottom) div 2;
      OffsetX := CenterX - DesignatorCenterX;
      OffsetY := CenterY - DesignatorCenterY;
      Designator.MoveByXY(OffsetX, OffsetY);
    finally
      PCBServer.PostProcess;
    end;
    Comp := Iterator.NextPCBObject;
  end;
  Board.BoardIterator_Destroy(Iterator);
  Board.ViewManager_FullUpdate;
  
end;

// Main processing function for all components on the board
procedure ProcessAllComponents;
var
  Board: IPCB_Board;
  Component: IPCB_Component;
  Iterator: IPCB_BoardIterator;
  TopCopyCount, BottomCopyCount: Integer;
  TopClearCount, BottomClearCount: Integer;
  Clear61Count, Clear62Count: Integer;
  ManualTextsDeleted: Integer;
  TargetWidth : TCoord;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    ShowMessage('No active PCB document!');
    Exit;
  end;
  TopCopyCount := 0; BottomCopyCount := 0;
  TopClearCount := 0; BottomClearCount := 0;
  Clear61Count := 0; Clear62Count := 0;
  ManualTextsDeleted := 0;
  DeleteManualTextsOnLayers68_69(ManualTextsDeleted);
  PCBServer.PreProcess;
  try
    Iterator := Board.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
    Iterator.AddFilter_LayerSet((AllLayers));
    Iterator.AddFilter_Method(eProcessAll);
    Component := Iterator.FirstPCBObject;
    while Component <> nil do
    begin
      if not IsBrusaComponent(Component) then
      begin
        ClearDesignatorsFromSourceLayers(Board, Component, Clear61Count, Clear62Count);
        ClearTextObjectsFromLayers(Board, Component, TopClearCount, BottomClearCount);
      end;
      Component := Iterator.NextPCBObject;
    end;
    Component := Iterator.FirstPCBObject;
    while Component <> nil do
    begin
      if not IsBrusaComponent(Component) and not IsTestPointComponent(Component) then
      begin
        if Component.Layer = eTopLayer then
          CopyLayerObjects(Board, Component, 61, 66, TopCopyCount)
        else if Component.Layer = eBottomLayer then
          CopyLayerObjects(Board, Component, 62, 67, BottomCopyCount);
      end;
      Component := Iterator.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iterator);
  finally
    PCBServer.PostProcess;
  end;
  CreateCenteredDesignatorsForAllComponents;
  SaveCurrentPCB;
  TargetWidth := MMsToCoord(0.1); // 0.1mm

  // 66th Layer - ASM TOP
  ProcessTracksOnLayer(66, TargetWidth);
  ProcessArcsOnLayer(66, TargetWidth);
  ClearSelections;

  // 67th Layer - ASM BOT
  ProcessTracksOnLayer(67, TargetWidth);
  ProcessArcsOnLayer(67, TargetWidth);
  ClearSelections;

  // Save the board
  SaveCurrentPCB;
  
  ShowMessage('Completed successfully!');
end;

// Event handler for the Save button - initiates the main processing
procedure TForm1.sourceLibrary_SaveClick(Sender: TObject);
begin
  UnlockAllComponents;
  DeleteOnlyComponentDesignators;
  ProcessAllComponents;
end;

// Unlocks all components on the board to make them movable
procedure TForm1.UnlockAllComponents;
var
  PCB_Board: IPCB_Board;
  Iterator: IPCB_BoardIterator;
  Comp: IPCB_Component;
  Count: Integer;
begin
  Count := 0;
  PCB_Board := PCBServer.GetCurrentPCBBoard;
  if PCB_Board = nil then
  begin
    ShowMessage('PCB board not found.');
    Exit;
  end;
  Iterator := PCB_Board.BoardIterator_Create;
  Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
  Iterator.AddFilter_LayerSet(AllLayers);
  Iterator.AddFilter_Method(eProcessAll);
  Comp := Iterator.FirstPCBObject;
  while Comp <> nil do
  begin
    Comp.PrimitiveLock := False;
    Comp.Selected := True;
    try
      Comp.Moveable := True;
    except
    end;
    Comp.Selected := False;
    Inc(Count);
    Comp := Iterator.NextPCBObject;
  end;
  PCB_Board.BoardIterator_Destroy(Iterator);
  
end;

// Deletes component designators from specified layers
procedure TForm1.DeleteOnlyComponentDesignators;
var
  Board: IPCB_Board;
  Iterator: IPCB_BoardIterator;
  TextObj: IPCB_Text;
  CountDeleted1, CountDeleted2: Integer;
  Layer1, Layer2: Integer;
  LayerText: String;
  NextObject: IPCB_Text;
  UnderlyingStr: String;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    ShowMessage('PCB document is not currently open.');
    Exit;
  end;

  // Determine target layers based on UI selection
  Layer1 := 68;
  Layer2 := 69;
  if LibSelection_Custom.Checked then
  begin
    try
      LayerText := Copy(topDesignatorSelection_ComboBox.Text, 1,
        Pos('-', topDesignatorSelection_ComboBox.Text) - 1);
      Layer1 := StrToInt(Trim(LayerText));
    except
      ShowMessage('Invalid Top Designator layer!');
      Exit;
    end;
    try
      LayerText := Copy(bottomDesignatorSelection_ComboBox.Text, 1,
        Pos('-', bottomDesignatorSelection_ComboBox.Text) - 1);
      Layer2 := StrToInt(Trim(LayerText));
    except
      ShowMessage('Invalid Bottom Designator layer!');
      Exit;
    end;
  end
  else if not (LibSourceSelection_HyPower_Prod.Checked or
               LibSourceSelection_HyPower_DBLIB.Checked) then
    Exit;

  CountDeleted1 := 0;
  CountDeleted2 := 0;

  PCBServer.PreProcess;
  try
    // Single iteration for both target layers
    Iterator := Board.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eTextObject));
    Iterator.AddFilter_LayerSet(MkSet(Layer1, Layer2));
    Iterator.AddFilter_Method(eProcessAll);

    TextObj := Iterator.FirstPCBObject;
    while TextObj <> nil do
    begin
      // Store next object before potential deletion
      NextObject := Iterator.NextPCBObject;

      // Get and clean underlying string
      UnderlyingStr := TextObj.UnderlyingString;

      // Check for both '.Designator' and quoted version
      if ((UnderlyingStr = '.Designator') or (UnderlyingStr = ''''+'.Designator'+'''')) and (TextObj.Component <> nil) then
      begin
        if TextObj.Layer = Layer1 then
          Inc(CountDeleted1)
        else if TextObj.Layer = Layer2 then
          Inc(CountDeleted2);

        // First remove from component
        if TextObj.Component <> nil then
          TextObj.Component.RemovePCBObject(TextObj);

        // Remove from board and destroy
        Board.RemovePCBObject(TextObj);
        PCBServer.DestroyPCBObject(TextObj);

        // Short delay for stability
        Sleep(50);
      end;

      TextObj := NextObject;
    end;

    Board.BoardIterator_Destroy(Iterator);
  finally
    PCBServer.PostProcess;
  end;

  Board.ViewManager_FullUpdate;
  Board.GraphicallyInvalidate;

end;

// Helper function to convert coordinates to millimeters (string output)
function CoordToMM(Coord: TCoord): String;
begin
  Result := FormatFloat('0.00', Coord * 0.00000254) + ' mm';
end;

// Helper function to convert coordinates to millimeters (numeric output)
function CoordValueToMM(Coord: TCoord): Double;
begin
  Result := Coord * 0.00000254;
end;

end.
