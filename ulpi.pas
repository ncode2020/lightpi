unit ulpi;

{$mode objfpc}

interface

uses Classes, utypes, uconstants, ulexer, uparser, uinterpreter;

type TLightPascalInterpreter = class(TObject)
       private
         rootNode: TASTTreeNode; // root of the abstract syntax tree

         lexer: TLPI_Lexer;
         parser: TLPI_Parser;
         interpreter: TLPI_Interpreter;

       public
         Constructor Create(debug: Boolean = false); virtual;
         function Load(s: AnsiString): Boolean;
         procedure ResetVariables;
         function GetVariable(name: AnsiString): Variant;
         procedure SetVariable(name: AnsiString; value: Variant);
         function Execute: Boolean;
         function GetMessages: TStringList;
         procedure PrintMessages;
         Destructor Destroy; override;
     end;

implementation

uses sysutils, ulist;

Constructor TLightPascalInterpreter.Create(debug: Boolean = false);
begin
  ClpiDebugMode := debug;

  lexer := TLPI_Lexer.Create;
  parser := TLPI_Parser.Create;
  interpreter := TLPI_Interpreter.Create;
end;

// returns true on success
function TLightPascalInterpreter.Load(s: AnsiString): Boolean;
var tokenlist: TLightList;
begin
  Result := false;

  // was something already loaded?
  if rootNode <> nil then
    FreeAndNil(rootNode)
  else
    rootNode := nil;

  tokenlist := lexer.execute(s);
  if lexer.isError then Exit;

  rootNode := parser.execute(tokenlist);
  if parser.isError then Exit;

  ResetVariables; // create and initialize all variables with 0

  Result := true;
end;

procedure TLightPascalInterpreter.ResetVariables;
begin
  interpreter.init_variables(parser.symbols.Count);
end;

function TLightPascalInterpreter.GetVariable(name: AnsiString): Variant;
begin
  Result := interpreter.get_variable(name, parser.symbols);
end;

procedure TLightPascalInterpreter.SetVariable(name: AnsiString; value: Variant);
begin
  interpreter.set_variable(name, value, parser.symbols);
end;

// returns true on success
function TLightPascalInterpreter.Execute: Boolean;
begin
  Result := false;

  if (lexer.isError) or (parser.isError) then Exit;

  interpreter.execute(rootNode, parser.symbols);

  Result := not interpreter.isError;
end;

function TLightPascalInterpreter.Getmessages: TStringList;
var i: Integer;
    sl: TStringList;
begin
  sl := TStringList.Create;

  for i := 0 to lexer.messages.Count - 1 do
    sl.Add(lexer.messages[i]);

  for i := 0 to parser.messages.Count - 1 do
    sl.Add(parser.messages[i]);

  for i := 0 to interpreter.messages.Count - 1 do
    sl.Add(interpreter.messages[i]);

  Result := sl;
end;


// messages can easily be processed in other ways if needed
procedure TLightPascalInterpreter.PrintMessages;
var total_messages: TStringList;
begin
  total_messages := GetMessages;

  while total_messages.Count > 0 do
  begin
    writeln(total_messages[0]);
    total_messages.Delete(0);
  end;

  FreeAndNil(total_messages);
end;

Destructor TLightPascalInterpreter.Destroy;
begin
  FreeAndNil(rootNode); // contains the abstract syntax tree

  FreeAndNil(interpreter);
  FreeAndNil(parser);
  FreeAndNil(lexer);

  inherited;
end;

end.
