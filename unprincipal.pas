unit unPrincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, ComCtrls, DBGrids,
  StdCtrls, ExtCtrls, IdHTTP, IdSSLOpenSSL, uDWResponseTranslator,
  uRESTDWPoolerDB, fphttpclient, opensslsockets, fpjson, jsonparser, DateUtils,
  ServerUtils, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DWClientREST_BearerToken: TDWClientREST;
    DWResponseTranslator_DWClientREST_BearerToken: TDWResponseTranslator;
    Label1: TLabel;
    Lbl_ValidadeToken: TLabel;
    Panel1: TPanel;
    RESTDWClientSQL_DWClientREST_BearerToken: TRESTDWClientSQL;
    TabControl1: TTabControl;
    procedure Button1Click(Sender: TObject);
    procedure DWClientREST_BearerTokenBeforeGet(var AUrl: String;
      var AHeaders: TStringList);
    procedure FormCreate(Sender: TObject);
  private
    vvd_expire:TDateTime;
    vvs_token:String;
    vvs_clientId :String;
    vvs_clientSecret :String;
    vvs_userName :String;
    vvs_password :String;
    vvs_urlbase :String;


    function getToken():String;
    function getTokenIndy():String;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  vvoJsonParser:TJSONParser;
  vvoJson:TJSONObject;
  vli_expire:Integer;
  vvo_AuthOption:TRDWAuthOptionBearerClient;
begin
  if((vvs_token = '') or (vvd_expire <= Now())) then
  begin
    try
      vvoJsonParser:=TJSONParser.create(
        getTokenIndy()
      );
      vvoJson:=(vvoJsonParser.Parse as TJSONObject);
      vvs_token:=vvoJson.get('access_token','');
      vli_expire:=vvoJson.get('expires_in',0);
      vvd_expire:=IncSecond(Now,vli_expire);
      Lbl_ValidadeToken.Caption:=FormatDateTime('DD/MM/YYYY HH:MM:SS',vvd_expire);

		except
      vvs_token:='';
		end;
	end;

  if(vvs_token <> '') then
  begin
    vvo_AuthOption:= (DWClientREST_BearerToken.AuthenticationOptions.OptionParams as TRDWAuthOptionBearerClient);
    vvo_AuthOption.Token:= vvs_token;
	  RESTDWClientSQL_DWClientREST_BearerToken.Close;
	  RESTDWClientSQL_DWClientREST_BearerToken.Open;
	end;
end;

procedure TForm1.DWClientREST_BearerTokenBeforeGet(var AUrl: String;
  var AHeaders: TStringList);
begin
  AUrl:=vvs_urlbase+'/produtos/get';
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  configIni:TIniFile;
begin
  configIni := TIniFile.Create('./config.ini');
  try
    vvs_userName := configIni.ReadString('local','userName','');
    vvs_password := configIni.ReadString('local','password','');
    vvs_clientId := configIni.ReadString('local','clientId','');
    vvs_clientSecret := configIni.ReadString('local','clientSecret','');
    vvs_urlbase := configIni.ReadString('local','urlbase','');
  finally
    configIni.Free;
  end;

end;

function TForm1.getToken(): String;
var
  vvoBody:TStrings;
begin

  With TFPHttpClient.Create(Nil) do
  try
    vvoBody:=TStringList.Create;
    try
      AddHeader('Accept','application/json');
      AddHeader('Content-Type','application/x-www-form-urlencoded');

      vvoBody.Text:=''+
        'grant_type=password'#13+
        'client_id='+vvs_clientId+#13+
        'client_secret='+vvs_clientSecret+#13+
        'username='+vvs_userName+#13+
        'password='+vvs_password+#13+
        '';

        Result:= FormPost(vvs_urlbase+'/token',vvoBody)
    except
      on E: Exception do
        Raise;
    end;

  finally
    vvoBody.Free;
    Free;
  end;
end;

function TForm1.getTokenIndy(): String;
var
  ssl: TIdSSLIOHandlerSocketOpenSSL;
  httpClient: TIdHTTP;
  Params: TStringList;
begin
  try
	  ssl:= TIdSSLIOHandlerSocketOpenSSL.Create();
	  httpClient := TIdHTTP.create();
    Params := TStringList.Create;

    httpClient.IOHandler:=ssl;

    Params.add('grant_type=password');
    Params.add('client_id='+vvs_clientId);
    Params.add('client_secret='+vvs_clientSecret);
    Params.add('username='+vvs_userName);
    Params.add('password='+vvs_password);

    httpClient.Request.Method :=  'POST';
    httpClient.Request.ContentType := 'application/x-www-form-urlencoded';
    httpClient.Request.Accept := 'application/json';
    httpClient.ConnectTimeout := 5000;
    Result:=httpClient.post(vvs_urlbase+'/token',params);

  finally
    Params.Free;
    ssl.Free;
    httpClient.Free;
	end;
end;

end.

