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
    FUpdatingLibrarySource: Boolean;
    procedure UpdateLibraryCheckboxes;          					// Updates UI based on selections
    procedure SetCustomLayerLabelsVisible(Visible: Boolean); 		// Toggles custom layer UI
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
    Result := True;
End;
// Initializes the form and disables certain UI elements by default
procedure TForm1.FormCreate(Sender: TObject);
begin
  FUpdatingLibrarySource := False;
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
  end
  else
  begin
    LibSourceSelection_HyPower_Prod.Enabled := False;
    LibSourceSelection_HyPower_DBLIB.Enabled := False;
  end;

  if LibSelection_Custom.Checked then
  begin
    LibSourceSelection_HyPower_Prod.Enabled := False;
    LibSourceSelection_HyPower_DBLIB.Enabled := False;
    FillAllLayerCombos;
  end;

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
  if FUpdatingLibrarySource then Exit;
  FUpdatingLibrarySource := True;
  try
    LibSourceSelection_HyPower_Prod.Checked := Selected = 'PROD';
    LibSourceSelection_HyPower_DBLIB.Checked := Selected = 'DBLIB';
  finally
    FUpdatingLibrarySource := False;
  end;
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
  for i := FIRST_SUPPORTED_LAYER_INDEX to LAST_SUPPORTED_LAYER_INDEX do
  begin
    try
      LayerName := PCB_Board.LayerName(i);
      if (LayerName = '') and (i >= FIRST_MECHANICAL_LAYER_INDEX) and
         (i <= LAST_SUPPORTED_LAYER_INDEX) then
        LayerName := PCB_Board.LayerStack.GetMechanicalLayerName(i);
      LayerName := Trim(LayerName);
      if (LayerName <> '') and (LayerName <> 'No Layer') then
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
begin
  Result := False;
  if Component = nil then Exit;
  Footprint := UpperCase(Component.Pattern);
  Result := (Footprint = 'TESTPOINT_1MM') or
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
procedure CreateCenteredDesignatorsForAllComponents(TopLayer, BottomLayer: Integer);
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
        Designator.TTFInvertedTextJustify := eAutoPos_CenterCenter;
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
      finally
        Designator.EndModify;
      end;
      Board.AddPCBObject(Designator);
      AddedToBoard := True;
      Comp.AddPCBObject(Designator);
      AddedToComponent := True;
      ScaleFactor := DESIGNATOR_SHRINK_FACTOR;
      repeat
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
  TopAssemblyLayer, BottomAssemblyLayer: Integer);
var
  Board: IPCB_Board;
  Component: IPCB_Component;
  Iterator: IPCB_BoardIterator;
  TargetWidth : TCoord;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    ShowMessage('No active PCB document!');
    Exit;
  end;
  DeleteManualTextsOnDesignatorLayers(TopDesignatorLayer, BottomDesignatorLayer);
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
  CreateCenteredDesignatorsForAllComponents(TopDesignatorLayer, BottomDesignatorLayer);
  if not SaveCurrentPCB then Exit;
  TargetWidth := MMsToCoord(ASSEMBLY_TRACK_WIDTH_MM);

  // Top assembly output layer.
  ProcessTracksOnLayer(TopAssemblyLayer, TargetWidth);
  ProcessArcsOnLayer(TopAssemblyLayer, TargetWidth);

  // Bottom assembly output layer.
  ProcessTracksOnLayer(BottomAssemblyLayer, TargetWidth);
  ProcessArcsOnLayer(BottomAssemblyLayer, TargetWidth);

  // Save the board
  if not SaveCurrentPCB then Exit;
  
  ShowMessage('Completed successfully!');
end;

// Event handler for the Save button - initiates the main processing
procedure TForm1.sourceLibrary_SaveClick(Sender: TObject);
var
  Board: IPCB_Board;
  TopDesignatorLayer, BottomDesignatorLayer: Integer;
  TopAssemblyLayer, BottomAssemblyLayer: Integer;
begin
  Board := PCBServer.GetCurrentPCBBoard;
  if Board = nil then
  begin
    ShowMessage('No active PCB document!');
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

  UnlockAllComponents;
  DeleteOnlyComponentDesignators(TopDesignatorLayer, BottomDesignatorLayer);
  ProcessAllComponents(TopDesignatorLayer, BottomDesignatorLayer,
    TopAssemblyLayer, BottomAssemblyLayer);
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

end.
