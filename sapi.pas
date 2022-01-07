unit sapi;

{$mode objfpc}{$H+}
{$goto on}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ActnList, ComCtrls, CheckLst, Menus, ValEdit, Types,
  FPHTTPClient, opensslsockets, jsonparser, fpjson, lclintf, Interfaces;

type

  { TMainForm }

  TMainForm = class(TForm)
    EmailImage: TImage;
    DocsImage: TImage;
    SaveImage: TImage;
    InfoImage: TImage;
    NewRequestBtn: TButton;
    SendRequestBtn: TButton;
    HeaderAddBtn: TButton;
    QueryAddBtn: TButton;
    QueryDelBtn: TButton;
    HeaderDelBtn: TButton;
    HeaderCheckList: TCheckListBox;
    QueryCheckList: TCheckListBox;
    RequestMethodCombo: TComboBox;
    HeaderKeyCombo: TComboBox;
    QueryValueEdit: TEdit;
    QueryKeyEdit: TEdit;
    HeaderValueEdit: TEdit;
    QueryGroupBox: TGroupBox;
    HeaderGroupBox: TGroupBox;
    OpenContentBtn: TImage;
    RequestURLEdit: TLabeledEdit;
    RawResponseMemo: TMemo;
    ContentMemo: TMemo;
    ResHeaderTab: TTabSheet;
    OpenDialog1: TOpenDialog;
    RequestPageControl: TPageControl;
    ResponsePageControl: TPageControl;
    SaveDialog1: TSaveDialog;
    StatusBar: TStatusBar;
    QueryTab: TTabSheet;
    HeaderTab: TTabSheet;
    RawResponseTab: TTabSheet;
    JsonResponseTab: TTabSheet;
    ContentTab: TTabSheet;
    JsonTreeView: TTreeView;
    HeaderResValueEditor: TValueListEditor;
    procedure DocsImageClick(Sender: TObject);
    procedure EmailImageClick(Sender: TObject);
    procedure InfoImageClick(Sender: TObject);
    procedure NewRequestBtnClick(Sender: TObject);
    procedure SaveImageClick(Sender: TObject);
    procedure SendRequestBtnClick(Sender: TObject);
    procedure HeaderAddBtnClick(Sender: TObject);
    procedure QueryAddBtnClick(Sender: TObject);
    procedure QueryDelBtnClick(Sender: TObject);
    procedure HeaderDelBtnClick(Sender: TObject);
    procedure QueryValueEditChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OpenContentBtnClick(Sender: TObject);
    procedure InfoMenuItemClick(Sender: TObject);
    procedure SettingsMenuItemClick(Sender: TObject);
    procedure RequestMainMenuClick(Sender: TObject);
    procedure ImportMenuItemClick(Sender: TObject);
    procedure ExportMenuItemClick(Sender: TObject);
    procedure SaveMenuItemClick(Sender: TObject);
    procedure QuitMenuItemClick(Sender: TObject);
    procedure UnlockMenuItemClick(Sender: TObject);
    procedure DocsMenuItemClick(Sender: TObject);

    procedure ClearForm();
    procedure ShowJSONDocument(Root: TJSONData);
    procedure ShowJSONData(AParent: TTreeNode; Data: TJSONData);

    procedure RequestPageControlChange(Sender: TObject);
    procedure HeaderTabContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: boolean);
    procedure HeaderResValueEditorClick(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;
  QueryString: string;
  QueryList, HeaderList: TStringList;
  JData: TJSONData;
  JObject, TreeJsonObject: TJSONObject;
  JArray: TJSONArray;
  Index: integer;


implementation

{$R *.lfm}


{ TMainForm }


//Icon color 88D135

procedure TMainForm.FormCreate(Sender: TObject);
begin
  QueryList := TStringList.Create;
  HeaderList := TStringList.Create;
  QueryString := '';
  Index := 0;
end;

procedure TMainForm.OpenContentBtnClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    if OpenDialog1.FileName.IsEmpty = False then
    begin
      ContentMemo.Lines.LoadFromFile(OpenDialog1.FileName);
      ContentMemo.SelStart := 0;
    end;
  end;
end;

procedure TMainForm.SendRequestBtnClick(Sender: TObject);
var
  Data, Query, ErrorMessage, RequestMethod, Content: string;
  I, J: integer;
  RequestSuccess: boolean;
  Client: TFPHttpClient;
  StringStream: TStringStream;
begin
  RawResponseMemo.Lines.Clear;
  JsonTreeView.Items.Clear;
  HeaderResValueEditor.Clear;

  Query := '';
  RequestSuccess := True;
  StringStream := TStringStream.Create;


  if QueryList.Count <> 0 then
  begin
    Query := '?';
    for I := 0 to QueryList.Count - 1 do
    begin
      if QueryCheckList.Checked[I] then
      begin
        Query := Query + QueryList.Strings[I] + '&';
      end;
    end;
  end;
  Client := TFPHTTPClient.Create(nil);
  with Client do
    try
      try
        RequestMethod := RequestMethodCombo.Caption;
        if RequestMethod.Equals('POST') = True then
        begin
          for I := 0 to HeaderList.Count - 1 do
          begin
            if HeaderCheckList.Checked[I] then
            begin
              AddHeader(HeaderList.Names[I], HeaderList.Values[HeaderList.Names[I]]);
            end;
          end;
          for J := 0 to ContentMemo.Lines.Count - 1 do
          begin
            Content := ContentMemo.Lines.Text;
          end;
          StatusBar.SimpleText :=
            'Sending ' + 'POST' + ' Request to ' + RequestURLEdit.Text + ' ...';
          RequestBody := TRawByteStringStream.Create(Content);
          httpmethod('POST', RequestURLEdit.Text + Query, StringStream, []);
          Data := StringStream.DataString;
          StatusBar.Caption := ResponseStatusCode.ToString + ' ' + ResponseStatusText;
          for J := 0 to ResponseHeaders.Count - 1 do
          begin
            HeaderResValueEditor.InsertRow(ResponseHeaders.Names[J],
              ResponseHeaders.Values[ResponseHeaders.Names[J]], True);
          end;
          //Data := Client.SimplePost(RequestURLEdit.Text + Query);
        end
        else if RequestMethod.Equals('GET') = True then
        begin
          StatusBar.SimpleText :=
            'Sending ' + 'GET' + ' Request to ' + RequestURLEdit.Text + ' ...';
          httpmethod('GET', RequestURLEdit.Text + Query, StringStream, []);
          Data := StringStream.DataString;
          for J := 0 to ResponseHeaders.Count - 1 do
          begin
            HeaderResValueEditor.InsertRow(ResponseHeaders.Names[J],
              ResponseHeaders.Values[ResponseHeaders.Names[J]], True);
          end;
          StatusBar.SimpleText :=
            'Status : ' + ResponseStatusCode.ToString + ' ' + ResponseStatusText;
        end
        else
        begin
          RequestSuccess := False;
          ShowMessage('Method ' + RequestMethod + ' not yet supported');
          ErrorMessage := 'Request method not yet supported';
        end;
      except
        on E: Exception do
        begin
          RequestSuccess := False;
          ErrorMessage := E.ToString;
        end;
      end;
    finally
      begin
        RawResponseMemo.Lines.AddText(Data);
        RawResponseMemo.SelStart := 0;

        if ResponseHeaders.Values['Content-Type'].Contains('application/json') then
        begin
          ShowJsonDocument(GetJSON(Data));
        end;


        if RequestSuccess = True then
        begin
          StatusBar.SimpleText := 'The request was successful.';
        end
        else
        begin
          StatusBar.SimpleText := 'Request Unsuccessful Error : ' + ErrorMessage;
        end;
        Free;
      end;
      //  JData := GetJSON(Data);
      //  JObject := JData as TJSONObject;
    end;
end;

procedure TMainForm.NewRequestBtnClick(Sender: TObject);
begin
  ClearForm();
end;

procedure TMainForm.DocsImageClick(Sender: TObject);
begin
  OpenURL('https://www.globment.de/sapi-tool.html');
end;

procedure TMainForm.EmailImageClick(Sender: TObject);
begin
    OpenURL('mailto:info@globment.de');
end;

procedure TMainForm.InfoImageClick(Sender: TObject);
begin
  OpenURL('https://www.globment.de/en');
end;

procedure TMainForm.SaveImageClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    try
      RawResponseMemo.Lines.SaveToFile(SaveDialog1.FileName);
    finally
      StatusBar.Caption := 'Raw data response saved to file ' + SaveDialog1.FileName;
    end;
  end;
end;

procedure TMainForm.ClearForm();
begin
  RequestMethodCombo.Caption := RequestMethodCombo.Items[0];
  RequestURLEdit.Clear;

  HeaderList.Clear;
  QueryList.Clear;

  QueryCheckList.Clear;
  HeaderCheckList.Clear;
  ContentMemo.Clear;

  HeaderKeyCombo.Caption := '';
  HeaderValueEdit.Clear;
  QueryKeyEdit.Clear;
  QueryValueEdit.Clear;

  RawResponseMemo.Clear;
  JsonTreeView.Items.Clear;
  HeaderResValueEditor.Clear;
end;

procedure TMainForm.ShowJSONDocument(Root: TJSONData);

begin
  with JsonTreeView.Items do
  begin
    BeginUpdate;
    try
      JsonTreeView.Items.Clear;
      SHowJSONData(nil, Root);
      with JsonTreeView do
        if (Items.Count > 0) and Assigned(Items[0]) then
        begin
          Items[0].Expand(False);
          Selected := Items[0];
        end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TMainForm.ShowJSONData(AParent: TTreeNode; Data: TJSONData);
var
  N, N2: TTreeNode;
  I: integer;
  D: TJSONData;
  C: string;
  S: TStringList;
  SArray: array of string;
begin
  N := nil;
  if Assigned(Data) then
  begin
    case Data.JSONType of
      jtArray,
      jtObject:
      begin
        if (Data.JSONType = jtArray) then
        begin
          C := Data.AsJSON;
        end
        else
        begin
          C := Data.AsJSON;
        end;
        N := JsonTreeView.Items.AddChild(AParent, Format(C, [Data.Count]));
        S := TStringList.Create;
        try
          for I := 0 to Data.Count - 1 do
            if Data.JSONtype = jtArray then
              S.AddObject(IntToStr(I), Data.items[i])
            else
              S.AddObject(TJSONObject(Data).Names[i], Data.items[i]);
          //if FSortObjectMembers and (Data.JSONType=jtObject) then
          //  S.Sort;
          for I := 0 to S.Count - 1 do
          begin
            N2 := JsonTreeView.Items.AddChild(N, S[i]);
            D := TJSONData(S.Objects[i]);
            // N2.ImageIndex:=ImageTypeMap[D.JSONType];
            // N2.SelectedIndex:=ImageTypeMap[D.JSONType];
            ShowJSONData(N2, D);
          end
        finally
          S.Free;
        end;
      end;
      jtNull:
        N := JsonTreeView.Items.AddChild(AParent, '');
      else
        N := JsonTreeView.Items.AddChild(AParent, Data.AsString);
    end;
    if Assigned(N) then
    begin
      //N.ImageIndex:=ImageTypeMap[Data.JSONType];
      //N.SelectedIndex:=ImageTypeMap[Data.JSONType];
      N.Data := Data;
    end;
  end;
end;




procedure TMainForm.HeaderAddBtnClick(Sender: TObject);
var
  HeaderKey, HeaderValue: string;
begin
  HeaderKey := HeaderKeyCombo.Caption;
  HeaderValue := HeaderValueEdit.Text;
  if HeaderKey.IsEmpty = False then
  begin
    if HeaderValue.IsEmpty = False then
    begin
      HeaderList.AddPair(HeaderKey, HeaderValue);
      HeaderCheckList.Items.Add(HeaderKey + ', ' + HeaderValue);

      HeaderValueEdit.Clear;

    end;
  end;
end;

procedure TMainForm.QueryAddBtnClick(Sender: TObject);
var
  QueryKey, QueryValue: string;
begin
  QueryKey := QueryKeyEdit.Text;
  QueryValue := QueryValueEdit.Text;
  if QueryKey.IsEmpty = False then
  begin
    if QueryValue.IsEmpty = False then
    begin
      QueryString := QueryKeyEdit.Text + '=' + QueryValueEdit.Text;
      QueryList.Add(QueryString);
      QueryCheckList.Items.Add(QueryString);

      QueryKeyEdit.Clear;
      QueryValueEdit.Clear;

    end;
  end;

end;

procedure TMainForm.QueryDelBtnClick(Sender: TObject);
var
  J: integer;
begin
  for J := 0 to QueryCheckList.Count - 1 do
  begin
    if QueryCheckList.Selected[J] then
    begin
      QueryCheckList.Items.Delete(J);
      QueryList.Delete(J);
    end;
  end;
end;

procedure TMainForm.HeaderDelBtnClick(Sender: TObject);
var
  J: integer;
begin
  for J := 0 to HeaderCheckList.Count - 1 do
  begin
    if HeaderCheckList.Selected[J] then
    begin
      HeaderCheckList.Items.Delete(J);
      HeaderList.Delete(J);
    end;
  end;
end;

procedure TMainForm.QueryValueEditChange(Sender: TObject);
begin

end;

procedure TMainForm.InfoMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.SettingsMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.RequestMainMenuClick(Sender: TObject);
begin

end;

procedure TMainForm.ImportMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.ExportMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.SaveMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.QuitMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.UnlockMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.DocsMenuItemClick(Sender: TObject);
begin

end;

procedure TMainForm.RequestPageControlChange(Sender: TObject);
begin

end;

procedure TMainForm.HeaderTabContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: boolean);
begin

end;

procedure TMainForm.HeaderResValueEditorClick(Sender: TObject);
begin

end;

end.
