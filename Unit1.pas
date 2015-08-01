unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, ADODB, StdCtrls, ExtCtrls, ComCtrls, a0ptConst, ImgList;

type TStatBarStatus = (SB_UNCONNECTION, SB_CONNECTION);
type TSelTypeParam  = (typeLogOper, typeLogObjc);
type THighLevelTree = (hlLogin, hlSmType);

type
  TFrmMain = class(TForm)
    Pnl: TPanel;
    StatusBar: TStatusBar;
    memo: TMemo;
    ADOConnect: TADOConnection;
    TV: TTreeView;
    Q1: TADOQuery;
    Q2: TADOQuery;
    Q3: TADOQuery;
    Q4: TADOQuery;
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    ImageList: TImageList;
    GrBoxFilter: TGroupBox;
    btnFilterDown: TButton;
    btnFilter: TButton;
    DateTimePicker: TDateTimePicker;
    Label1: TLabel;
    CmBoxExSelect: TComboBoxEx;
    Label2: TLabel;
    GroupBox1: TGroupBox;
    ImgStatFilter: TImage;
    lblStatFilter: TLabel;
    ProgressBar: TProgressBar;
    lblProgress: TLabel;
    procedure UpDateStatBar(SB_STATUS: TStatBarStatus);
    procedure FormCreate(Sender: TObject);
    function GetTypeToStr(Param: TSelTypeParam; IntValue: integer): String;
    procedure TVClick(Sender: TObject);
    procedure CmBoxExSelectClick(Sender: TObject);
    procedure CreateTreeView(HighLevel: THighLevelTree);
    procedure btnFilterClick(Sender: TObject);
    procedure btnFilterDownClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;
  DATE_FILTER: Boolean;

implementation

{$R *.dfm}

procedure TFrmMain.btnFilterClick(Sender: TObject);
begin
  if CmBoxExSelect.ItemIndex = -1 then
  begin
   MessageBox(Handle,PChar('Не задан верхний уровень каталога'),
              PCHar(Caption),MB_ICONWARNING);
   Exit;
  end;
  DATE_FILTER := True;
  ImageList.GetIcon(5,ImgStatFilter.Picture.Icon); // установка значка
  lblStatFilter.Caption := 'Фильтр активен';
  //вызов процедуры построения дерева с учетом фильтра даты
  CreateTreeView(THighLevelTree(CmBoxExSelect.ItemIndex));
end;

procedure TFrmMain.btnFilterDownClick(Sender: TObject);
begin
  if CmBoxExSelect.ItemIndex = -1 then
  begin
   MessageBox(Handle,PChar('Не задан верхний уровень каталога'),
              PCHar(Caption),MB_ICONWARNING);
   Exit;
  end;
  DATE_FILTER := false;
  ImageList.GetIcon(4,ImgStatFilter.Picture.Icon);
  lblStatFilter.Caption := 'Фильтр не активен';
  //вызов процедуры постороения дерева
  CreateTreeView(THighLevelTree(CmBoxExSelect.ItemIndex));
end;

procedure TFrmMain.CmBoxExSelectClick(Sender: TObject);
begin
  CreateTreeView(THighLevelTree(CmBoxExSelect.ItemIndex));
end;

procedure TFrmMain.FormCreate(Sender: TObject);
var udl_file: string;
begin
  udl_file := ExtractFilePath(Application.ExeName)+'a0ptest.udl';
  ADOConnect.ConnectionString := 'File Name='+udl_file;
  ADOConnect.Connected := True;
  if ADOConnect.Connected then UpDateStatBar(SB_CONNECTION)
  else UpDateStatBar(SB_UNCONNECTION);

  // установка значка фильтр не активен
  ImageList.GetIcon(4,ImgStatFilter.Picture.Icon);

  try
    // coздание индекса только по тем полям, которые участвуют в поисковых запросах
    Q1.SQL.Text := 'Create index INDX_A0Protocol ON A0Protocol(Oper, SmType, EvDate, Login)';
    Q1.ExecSQL;
  Except
    // Ошибки о создании индекса не будут выводиться
    // потому что не известно с какаким уровнем доступа будет подключаться пользователь
    // 
  end;  

  // Это если загрузка данных потребуется при старте программы 
  //CmBoxExSelect.ItemIndex := 0;
  //CreateTreeView(hlLogin);

end;

function TFrmMain.GetTypeToStr(Param: TSelTypeParam; IntValue: integer): String;
begin
   {
     В условиях задания не было определено, что записано в поле SMType
     индекс массива или индекс типа
     т.к. тип нумеруется от 0 то данные в таблице БД равные 0 будут считаться значением выбора типа
    тип нумеруется от 0 его количество соответствует количеству элементов в массиве
     массив нумеруется от 1, то проверка допустимого элемента массива
    будет на 1 единицу меньше максимального значения массива
    }
  case Param of
    typeLogOper:
      begin
        if IntValue < Length(strLogOperations) then
          result := strLogOperations[TLogOperations(IntValue)]
        else Result := '< Значение не определено >';
      end;
    typeLogObjc:
      begin
         if IntValue < Length(strLogObjects) then
          result := strLogObjects[TLogObjects(IntValue)]
        else Result := '< Значение не определено >';
      end;
  end;
end;

procedure TFrmMain.CreateTreeView(HighLevel: THighLevelTree);
var
    TN1,TN2,TN3,TN4: TTreeNode;
    StrValue     : String; // просто троковая переменная
    DATE_BETWEEN : String; // для фильтра по дате
    LevelName0   : String;
    LevelName1   : String;
    Param0       : String;
    Param1       : String;
begin
  memo.Lines.Clear;
  memo.Lines.BeginUpdate;
  TV.Items.Clear;
  TV.Items.BeginUpdate;
  lblProgress.Visible := True;
  ProgressBar.Visible := True;
  StatusBar.Panels[1].Text := 'Путь:';

  Q1.SQL.Text := 'Select count(*) from A0Protocol';
  Q1.Open;
  ProgressBar.Max := Q1.Fields[0].AsInteger;

  case HighLevel of
    hlLogin  : begin
                 LevelName0 := 'Login';
                 LevelName1 := 'SmType';
                 Param0     := 'Login=:pLogin';
                 Param1     := 'SmType=:pSmType'
               end;
    hlSmType : Begin
                 LevelName0 := 'SmType';
                 LevelName1 := 'Login';
                 Param0     := 'SmType=:pSmType';
                 Param1     := 'Login=:pLogin';
               End;
  end;


  if DATE_FILTER = true then
    begin
     // извлечение года в строковом формате
     DateTimeToString(StrValue,'YYYY',DateTimePicker.DateTime);
     // Формирование дополнительного запроса
    DATE_BETWEEN := 'EvDate BETWEEN ''01.01.'+StrValue+' 00:00:00.001'''+
                    ' and ''31.12.'+StrValue+' 23:59:59.999''';
  end;

  //// Создание первого уровня дерева
  if DATE_FILTER = true then
  begin
    Q1.SQL.Text := 'select DISTINCT('+LevelName0+') from A0Protocol WHERE ' + DATE_BETWEEN + ' ORDER BY '+LevelName0+' ASC';
    DATE_BETWEEN := ' and '+DATE_BETWEEN;
  end
  else Q1.SQL.Text := 'select DISTINCT('+LevelName0+') from A0Protocol ORDER BY '+LevelName0+' ASC';
  Q1.Open;
  Q1.First;
  while not Q1.Eof do
  begin
    Application.ProcessMessages;
    case HighLevel of
      hlLogin :
        begin
          TN1 := TV.Items.Add(Nil, Q1.Fields[0].AsString);
          TN1.ImageIndex    := 0;
          TN1.SelectedIndex := 0;
        end;
      hlSmType:
        begin
          TN1 := TV.Items.Add(Nil, GetTypeToStr(typeLogObjc, Q1.Fields[0].AsInteger));
          TN1.ImageIndex    := 1;
          TN1.SelectedIndex := 1;
        end;
    end;
    memo.Lines.Add(TN1.Text);
    ProgressBar.Position := TV.Items.Count;

    //// Создание второго уровеня дерева
    Q2.SQL.Text := 'Select distinct('+LevelName1+') from A0Protocol '+
                   'WHERE '+ Param0 + DATE_BETWEEN + ' ORDER BY '+LevelName1+' ASC';
    Q2.Parameters[0].Value := Q1.Fields[0].Value;
    Q2.Open;
    Q2.First;
    while not Q2.Eof do
    begin
      Application.ProcessMessages;
      case HighLevel of
        hlLogin  :
          begin
            TN2 := TV.Items.AddChild(TN1, GetTypeToStr(typeLogObjc, Q2.Fields[0].AsInteger));
            TN2.ImageIndex    := 1;
            TN2.SelectedIndex := 1;
          end;
        hlSmType :
          begin
            TN2 := TV.Items.AddChild(TN1, Q2.Fields[0].AsString);
            TN2.ImageIndex    := 0;
            TN2.SelectedIndex := 0;
          end;
      end;
      memo.Lines.Add(StringOfChar(' ',TN2.Level*5)+TN2.Text);
      ProgressBar.Position := TV.Items.Count;

      //// Создание третьего уровеня дерева
      Q3.SQL.Text := 'select distinct(Oper) from A0Protocol '+
        'WHERE '+Param0+' and '+Param1 + DATE_BETWEEN+' ORDER BY Oper ASC';
      Q3.Parameters[0].Value := Q1.Fields[0].Value;
      Q3.Parameters[1].Value := Q2.Fields[0].Value;
      Q3.Open;
      Q3.First;
      while not Q3.Eof do
      begin
        Application.ProcessMessages;
        // Извлечени данных из БД с преобразованиес типов
        TN3 := TV.Items.AddChild(TN2, GetTypeToStr(typeLogOper,Q3.Fields[0].AsInteger));
        TN3.ImageIndex    := 2;
        TN3.SelectedIndex := 2;
        memo.Lines.Add(StringOfChar(' ',TN3.Level*5)+ TN3.Text);
        ProgressBar.Position := TV.Items.Count;

        //// Создаем четвертый уровень дерева
        Q4.SQL.Text := 'select (convert(varchar, EvDate,111)+''/''+convert(varchar,EvDate,108)+' +
                       'CHAR(32)+CAST(ProjID AS VARCHAR(5))+CHAR(32)' +
                       '+REPLACE(REPLACE(LogText,CHAR(10),CHAR(32)),CHAR(13),CHAR(32))) AS LogText ' +
                       'from A0Protocol WHERE '+Param0+' and '+Param1+' and Oper='+Q3.Fields[0].AsString +
                       DATE_BETWEEN + ' ORDER BY LogText ASC';
        Q4.Parameters[0].Value := Q1.Fields[0].Value;
        Q4.Parameters[1].Value := Q2.Fields[0].Value;
        Q4.Open;
        Q4.First;
        while Not Q4.Eof do
        begin
          Application.ProcessMessages;
          TN4 := TV.Items.AddChild(TN3, Q4.Fields[0].AsString);
          TN4.ImageIndex    := 3;
          TN4.SelectedIndex := 3;
          memo.Lines.Add(StringOfChar(' ',TN4.Level*5) + TN4.Text);
          ProgressBar.Position := TV.Items.Count;

          Q4.Next;
        end;
        Q3.Next;
      end;
      Q2.Next;
    end;
    Q1.Next;
  end;

 TV.Items.EndUpdate;
 memo.Lines.EndUpdate;
 lblProgress.Visible := false;
 ProgressBar.Visible := false;
 if TV.Items.Count = 0 then
 begin
   TV.Items.Add(NIL,'< НЕТ ДАННЫХ >');
   memo.Lines.Add('< НЕТ ДАННЫХ >');
   TV.Items[0].ImageIndex    := -1;
   TV.Items[0].SelectedIndex := -1;
 end;

end;

procedure TFrmMain.TVClick(Sender: TObject);
var N: TTreeNode;
    S: String;
begin
  S := '';
  N:=TV.Selected;
  while N <> NIL do
  begin
    if N.Level < 3 then S := N.Text+'\'+ S;
    N := N.Parent;
  end;
  StatusBar.Panels[1].Text := 'Путь: '+S;
end;

procedure TFrmMain.UpDateStatBar(SB_STATUS: TStatBarStatus);
begin
  case SB_STATUS of
    SB_UNCONNECTION:
      begin
        StatusBar.Panels[0].Text := 'Состояние: неподключено';
      end;
    SB_CONNECTION:
      begin
        StatusBar.Panels[0].Text := 'Состояние: подключено';
      end;
  end;

end;

end.
