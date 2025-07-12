unit mcp.types.test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, fpjson, testregistry, mcp.types, dateutils; // Added dateutils for ISO date functions

type

  { TMCPTypesTest }

  TMCPTypesTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure AssertEquals(const Msg : string; aExpected,aActual : TMCPPromptKind); overload;
    procedure AssertEquals(const Msg : string; aExpected,aActual : TMCPRole); overload;
    procedure AssertEquals(const Msg : string; aExpected,aActual : TMCPRoles); overload;
  published
    procedure TestTMCPPromptKindHelper;
    procedure TestTMCPRoleHelper;
    procedure TestTMCPAnnotation;
    procedure TestTMCPSchema;
  end;

implementation

uses typinfo;

{ TMCPTypesTest }

procedure TMCPTypesTest.SetUp;
begin
  inherited SetUp;
end;

procedure TMCPTypesTest.TearDown;
begin
  inherited TearDown;
end;

procedure TMCPTypesTest.AssertEquals(const Msg: string; aExpected, aActual: TMCPPromptKind);
begin
  AssertEquals(Msg,GetEnumName(TypeInfo(TMCPPromptKind),ord(aExpected)),
                   GetEnumName(TypeInfo(TMCPPromptKind),ord(aActual)));
end;

procedure TMCPTypesTest.AssertEquals(const Msg: string; aExpected, aActual: TMCPRole);
begin
  AssertEquals(Msg,GetEnumName(TypeInfo(TMCPRole),ord(aExpected)),
                   GetEnumName(TypeInfo(TMCPRole),ord(aActual)));
end;

procedure TMCPTypesTest.AssertEquals(const Msg: string; aExpected, aActual: TMCPRoles);
begin
  AssertEquals(Msg,SetToString(PTypeInfo(TypeInfo(TMCPRoles)),Integer(aExpected),True),
                   SetToString(PTypeInfo(TypeInfo(TMCPRoles)),Integer(aActual),True));
end;

procedure TMCPTypesTest.TestTMCPPromptKindHelper;
var
  Kind: TMCPPromptKind;
begin
  // Test ToString
  Kind := pkText;
  AssertEquals('TMCPPromptKindHelper.ToString (pkText) failed', 'text', Kind.AsString);

  Kind := pkImage;
  AssertEquals('TMCPPromptKindHelper.ToString (pkImage) failed', 'image', Kind.AsString);

  Kind := pkEmbeddedResource;
  AssertEquals('TMCPPromptKindHelper.ToString (pkEmbeddedResource) failed', 'resource', Kind.AsString);

  // Test SetAsString
  Kind := pkText;
  Kind.AsString := 'image';
  AssertEquals('TMCPPromptKindHelper.SetAsString (image) failed', pkImage, Kind);

  Kind := pkAudio;
  Kind.AsString := 'resource';
  AssertEquals('TMCPPromptKindHelper.SetAsString (resource) failed', pkEmbeddedResource, Kind);
end;

procedure TMCPTypesTest.TestTMCPRoleHelper;
var
  Role: TMCPRole;
begin
  // Test ToString
  Role := prUser;
  AssertEquals('TMCPRoleHelper.ToString (prUser) failed', 'user', Role.AsString);

  Role := prAssistant;
  AssertEquals('TMCPRoleHelper.ToString (prAssistant) failed', 'assistant', Role.AsString);

  // Test SetAsString
  Role := prUser;
  Role.AsString := 'assistant';
  AssertEquals('TMCPRoleHelper.SetAsString (assistant) failed', prAssistant, Role);

  Role := prAssistant;
  Role.AsString := 'user';
  AssertEquals('TMCPRoleHelper.SetAsString (user) failed', prUser, Role);

  // Test invalid role (should raise exception)
  try
    Role.AsString := 'invalid';
    Fail('Expected EMCPException for invalid role but none was raised');
  except
    on E: EMCPException do
      AssertEquals('EMCPException for invalid role message mismatch', 'Invalid role: invalid', E.Message);
  end;
end;

procedure TMCPTypesTest.TestTMCPAnnotation;
var
  Annotation, LoadedAnnotation: TMCPAnnotation;
  JSON: TJSONObject;
  RolesArray: TJSONArray;
  TestDate: TDateTime;
begin
  // Test Initialize (class operator)
  Initialize(Annotation);
  AssertFalse('Annotation should not be initialized after default initialize', Annotation.Initialized);
  AssertEquals('LastModified should be 0 after initialize', 0, Annotation.LastModified);
  AssertEquals('Roles should be empty after initialize', [], Annotation.Roles);
  AssertFalse('Priority should be false after initialize', Annotation.Priority);


  // Test Setters and Initialized property
  Initialize(Annotation);
  Annotation.Priority := True;
  AssertTrue('Initialized should be true after setting priority', Annotation.Initialized);
  AssertTrue('Priority should be true', Annotation.Priority);

  TestDate := Now; // Capture current time for comparison
  Annotation.LastModified := TestDate;
  AssertTrue('Initialized should be true after setting LastModified', Annotation.Initialized);
  // Compare ISO8601 strings for TDateTime due to potential floating point inaccuracies
  AssertEquals('LastModified should be set', DateToISO8601(TestDate), DateToISO8601(Annotation.LastModified));

  Annotation.Roles:=Annotation.Roles+[prUser];
  AssertTrue('Initialized should be true after setting Roles', Annotation.Initialized);
  AssertTrue('Roles should include prUser', prUser in Annotation.Roles);

  // Test ToJSON (function) and ToJSON (procedure)
  JSON := Annotation.ToJSON;
  AssertNotNull('ToJSON function should return a JSON object', JSON);
  try
    AssertEquals('JSON priority should be 1', 1, JSON.Get('priority', 0));
    AssertTrue('JSON should contain lastModified', JSON.IndexOfName('lastModified')<>-1);
    AssertTrue('JSON should contain roles', JSON.IndexOfName('roles')<>-1);

    RolesArray := JSON.Get('roles',TJSONArray(Nil));
    AssertNotNull('Roles in JSON should be a JSONArray', RolesArray);
    AssertEquals('Roles array should have 1 item', 1, RolesArray.Count);
    AssertEquals('Role in JSON should be "user"', 'user', RolesArray.Items[0].AsString);
  finally
    JSON.Free;
  end;

  // Test FromJSON
  Initialize(LoadedAnnotation);
  JSON := TJSONObject.Create;
  try
    JSON.Add('priority', 0);
    JSON.Add('lastModified', DateToISO8601(EncodeDate(2023, 1, 1)));
    RolesArray := TJSONArray.Create;
    RolesArray.Add('assistant');
    JSON.Add('roles', RolesArray);

    LoadedAnnotation.FromJSON(JSON);
    AssertTrue('LoadedAnnotation should be initialized from JSON', LoadedAnnotation.Initialized);
    AssertFalse('LoadedAnnotation priority should be false', LoadedAnnotation.Priority);
    AssertEquals('LoadedAnnotation LastModified should match', EncodeDate(2023, 1, 1), LoadedAnnotation.LastModified);
    AssertTrue('LoadedAnnotation roles should include prAssistant', prAssistant in LoadedAnnotation.Roles);
    AssertTrue('LoadedAnnotation roles should have 1 member', LoadedAnnotation.Roles=[prAssistant]);
  finally
    JSON.Free;
  end;
end;

procedure TMCPTypesTest.TestTMCPSchema;
var
  Schema: TMCPSchema;
  ArgumentSchema: TJSONObject;
  JSON: TJSONObject;
  RequiredArray: TJSONArray;
  PropertiesObject: TJSONObject;
begin
  Schema := TMCPSchema.Create;
  try
    // Test AddArgument
    ArgumentSchema := TJSONObject.Create;
    ArgumentSchema.Add('type', 'string');
    Schema.AddArgument('param1', ArgumentSchema); // Added as required by default
    AssertNotNull('Argument param1 should exist', Schema.Arguments['param1']);
    AssertEquals('param1 type should be string', 'string', (Schema.Arguments['param1'] as TJSONObject).Get('type',''));
    AssertEquals('Required count should be 1', 1, Length(Schema.Required));
    AssertEquals('param1 should be in Required', 'param1', Schema.Required[0]);

    ArgumentSchema := TJSONObject.Create;
    ArgumentSchema.Add('type', 'integer');
    Schema.AddArgument('param2', ArgumentSchema, False); // Not required
    AssertNotNull('Argument param2 should exist', Schema.Arguments['param2']);
    AssertEquals('Required count should still be 1', 1, Length(Schema.Required)); // param2 is not required

    // Test ToJSON
    JSON := Schema.ToJSON;
    AssertNotNull('ToJSON should return a JSON object', JSON);
    try
      AssertEquals('JSON type should be object', 'object', JSON.Get('type',''));
      AssertTrue('JSON should contain properties', JSON.IndexOfName('properties')<>-1);
      AssertTrue('JSON should contain required', JSON.IndexOfName('required')<>-1);

      PropertiesObject := JSON.Get('properties',TJSONObject(Nil));
      AssertNotNull('Properties should be a JSON object', PropertiesObject);
      AssertTrue('Properties should contain param1', PropertiesObject.IndexOfName('param1')<>-1);
      AssertTrue('Properties should contain param2', PropertiesObject.IndexOfName('param2')<>-1);
      AssertEquals('param1 type in JSON', 'string', PropertiesObject.Get('param1',TJSONObject(Nil)).Get('type',''));
      AssertEquals('param2 type in JSON', 'integer', PropertiesObject.Get('param2',TJSONObject(Nil)).Get('type',''));

      RequiredArray := JSON.Get('required',TJSONArray(Nil));
      AssertNotNull('Required should be a JSON array', RequiredArray);
      AssertEquals('Required array count should be 1', 1, RequiredArray.Count);
      AssertEquals('Required array should contain param1', 'param1', RequiredArray.Items[0].AsString);

    finally
      JSON.Free;
    end;
  finally
    Schema.Free;
  end;
end;

initialization
  RegisterTests([TMCPTypesTest]);
end.
