unit compiler_code;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterAny, SynCompletion, Forms,
  Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, LCLType;

type

  { TForm1 }

  TForm1 = class(TForm)
    //private Components of TForm1 (GENERATED!)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    SynAnySyn1: TSynAnySyn;
    SynEdit1: TSynEdit;
    SynEdit2: TSynEdit;
    SynEdit3: TSynEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private //private methods of TForm1
    procedure feedLines       ();
    procedure reset           ();
    procedure writeAssembler  ();
    procedure runToolChain    ();
    procedure createFunctions ();
    procedure createIntCheck  ();
  private  //private members of TForm1
    var m_momLine  : integer;
    var bssArray   : array of string;
    var dataArray  : array of string;
    var textArray  : array of string;
    var textFuncArr: array of string;
    var mistake    : boolean;
 public  //public methods of TForm1
    //writes the different sections of the Assembler-code
    ////////////////////////////////////////////////////////////
    procedure setAssemblerBss    (i :string);
    procedure setAssemblerText   (i :string);
    procedure setAssemblerTextFun(i :string);
    procedure setAssemblerData   (i :string);
    ////////////////////////////////////////////////////////////
    procedure setMistake       (i :string);  //writes something into TSynedit2.
    function  getLineNumber    () :string;   //little ugly (because of the return-value), but time-saving
  end;

    TCommand = class     //just a groupment of the different Commands, to keep the Class TLine as small as possible :)
             public      //setters and getters
                   procedure setCommand (command: string);
                   procedure setArgs    (args   : string);
                   procedure setFullLine(line   : string);
                   procedure reset      ();
                   procedure proceedKeyW();
                   function  noProtoUnsolved () : boolean;
                   function  getStacklenght () : integer;
             private    //private members
                   var m_command  : string;
                   var m_args     : string;
                   var m_fullLine : string;
                   var mainSet    : boolean;
                   var lastFNIn   : string; //for the type of function.
                   var functionIn : string; //the Function were momentary in.
                   var needBegin  : boolean; //If a begin sequence is required on the next Line.
                   var indentStack: array of array [1 .. 3] of string; //name|type|lineNumber of start//Used for begin-end; sequences.
                   var prototypes : array of array [1 .. 2] of string; //name|solved//If not solved, error
                   var protoAllow : boolean; //If protoypes aren't allowed (after the first function)
                   var gotoArray  : array of array [1 .. 3] of string;  //name|scope|deployed
                   var wasInFunc  : boolean; //if there was ever a function declared (for variables and prototypes)
             private //private methods
                   procedure compute   ();
                   function  getTextInString   (i: string) : string;
                   function  quoteClosed       (i: string) : boolean;
                   function  getTextWOBrackets (i: string) : string;
             ///////////////////WRITE//////////////////////////////////////////
             private    //WRITE //these are the Methods of the Write-Routine.
                   procedure parseText ();
                   procedure writeOut  ();
                   procedure handleWriteAsm (isText: boolean; text: string);
             private
                   var m_numberMessages: integer;
             ////////////////////Variables///////////////////////////////
             private //functions
                   procedure parseVar    ();
                   function  typeCheck   (val: string) : string;
                   function  varDoesExist(i: string)   : boolean;
                   function  getVarIndex (i: string)   : integer;
                   procedure handleVarAsm(i: string; name: string; itype: string);
                   //procedure checkvarComm(com: string);
             private //variables
                     var varTable : array of array [1..2] of string; //vartable Column 1 = name, Column 2 = type
             ///////////////////GOTO//////////////////////////////////////
             private //functions
                     procedure parseGoto     ();
                     function  gotoDeployed  () : boolean;
             private //variables
             ///////////////////INPUT/////////////////////////////////////
             private //functions
                     procedure handleInputAsm ();
             private //variables
                     var numberInputs: integer;
             //////////////////BEGIN...END////////////////////////////////
             private
                     procedure handleBegin ();
                     procedure handleEnd   ();
             private
             //////////////////IF-STATEMENTS//////////////////////////////
             private
                 procedure handleIf ();
                 procedure handleEqu();
                 procedure handleEquVarAndText (firstOp: string; secondOp: string);
                 procedure handleEquVarAndInt  (firstOp: string; secondOp: string);
                 procedure handleEquVarAndVar  (firstOp: string; secondOp: string);
             private
                 var numberIf: integer;
             //Functions
             private
                 procedure handleMainFunc  ();
                 procedure handleVoidFunc  ();
             private
             //function prototypes
             private
                 procedure handlePrototype ();
                 function  protoExists     (i: string) : boolean; //if theres already a prototype called like this... SHIT MAN
                 function  getProtoIndex   (i: string) : integer;
             private
             //call function
             private
                 procedure callFunc ();
    end;

        TLine = class
         public          //public methods
               procedure   setLine       (i: string);  //setter for the line.
               procedure   compileLine   ();           //just runs the different methods of the class
               constructor Create        ();           //constructor to create the instance befehle of TCommand.
               destructor  Free          ();           //deletes the instance of TCommand to avoid memory leaks
         private         //private members
               var m_string       : string;
               var m_stringLength : integer;
               var m_command      : TCommand;
               var m_comType      : string;
               var m_argType      : string;
         private         //private methods          //clear by the name
               procedure resetCommand    ();
               procedure deleteBlanks    ();
               procedure deleteComments  ();
               procedure getStringLength ();
               procedure getCommandInLine();
               procedure getArgInLine    ();       //gets the arguement inside an line.
               procedure passComm        ();
    end;


var Form1 : TForm1;
var Zeile : TLine;

implementation

{ TForm1 }

procedure TForm1.createIntCheck();
begin                                {
     synEdit3.lines.add ('cmp_sorting:');
     synEdit3.lines.add ('mov ebx, 0');
     synEdit3.lines.add ('cmp_sorting_loop:');
     synEdit3.lines.add ('inc ebx');
     synEdit3.lines.add ('cmp byte [eax], 48');
     synEdit3.lines.add ('jl cmp_interror');
     synEdit3.lines.add ('cmp byte [eax], 57');
     synEdit3.lines.add ('jg cmp_interror');
     synEdit3.lines.add ('cmp byte [eax], 0');
     synEdit3.lines.add ('jz cmp_exit_sorting_loop');
     synEdit3.lines.add ('cmp ebx, 10');
     synEdit3.lines.add ('je cmp_exit_sorting_loop');
     synEdit3.lines.add ('jmp cmp_sorting_loop');
     synEdit3.lines.add ('cmp_exit_sorting_loop:');
     synEdit3.lines.add ('ret');    }
     synEdit3.lines.add ('cmp_interror:');
     synEdit3.lines.add ('mov eax, 3');
     synEdit3.lines.add ('mov ebx, 1');
     synEdit3.lines.add ('mov ecx, cmp_buffer');
     synEdit3.lines.add ('mov edx, 1000000');  //drains the terminal completely
     synEdit3.lines.add ('int 80h');
     synEdit3.lines.add ('mov eax, 4');
     synEdit3.lines.add ('mov ebx, 1');
     synEdit3.lines.add ('mov ecx, cmp_interr');
     synEdit3.lines.add ('mov edx, cmp_interrlen');
     synEdit3.lines.add ('int 80h');
     synEdit3.lines.add ('mov eax, 1');
     synEdit3.lines.add ('mov ebx, 0');
     synEdit3.lines.add ('int 80h');
     synEdit3.lines.add ('cmp_strToInt:');
     synEdit3.lines.add ('mov ebx, 0');
     synEdit3.lines.add ('mov ebx, 0');
     synEdit3.lines.add ('cmp_conversion_loop:');
     synEdit3.lines.add ('cmp BYTE[eax], 0');
     synEdit3.lines.add ('jz cmp_leave_loop');
     synEdit3.lines.add ('sub byte[eax], 48');
     synEdit3.lines.add ('inc eax');
     synEdit3.Lines.add ('inc ebx');
     synEdit3.lines.add ('cmp ebx, 9');
     synedit3.lines.add ('jge cmp_leave_loop');
     synEdit3.lines.add ('jmp cmp_conversion_loop');
     synEdit3.lines.add ('cmp_leave_loop:');
     synEdit3.lines.add ('ret');
     synEdit3.lines.add ('cmp_get_last_int:');
     synEdit3.lines.add ('xor edx, edx');
     synEdit3.lines.add ('mov ebx, 10');
     synEdit3.lines.add ('idiv ebx');
     synEdit3.lines.add ('ret');
     synEdit3.lines.add ('cmp_write_ints:');   //gets the Integer to write into eax
     synEdit3.lines.add ('xor ebx, ebx'); //empties ebx
     synEdit3.lines.add ('mov ecx, cmp_write_caret'); //gets the pointer
     synEdit3.lines.add ('add ecx, 8');
     synEdit3.lines.add ('cmp_write_ints_loop:');
     synEdit3.lines.add ('call cmp_get_last_int');
     synEdit3.lines.add ('add dx, 0x30');     //adds 48 to edx
     synEdit3.lines.add ('mov [ecx], dx');
     synEdit3.lines.add ('dec ecx');
     synEdit3.lines.add ('mov byte[ecx], 0x00');
     synEdit3.lines.add ('dec ecx');
     synEdit3.lines.add ('cmp ecx, cmp_write_caret');
     synEdit3.lines.add ('jg cmp_write_ints_loop');
     synEdit3.lines.add ('mov eax, 4');            //writes the found integer
     synEdit3.lines.add ('mov ebx, 1');
     synEdit3.lines.add ('mov ecx, cmp_write_caret');
     synEdit3.lines.add ('mov edx, 9');
     synEdit3.lines.add ('int 80h');
     synEdit3.lines.add ('ret');
     synEdit3.lines.add ('cmp_int_len_error:');
     synEdit3.lines.add ('mov eax, 4');
     synEdit3.lines.add ('mov ebx, 1');
     synEdit3.lines.add ('mov ecx, cmp_intlenerr');
     synEdit3.lines.add ('mov edx, cmp_intlenerr_len');
     synEdit3.lines.add ('int 80h');
     synEdit3.lines.add ('mov eax, 1');
     synEdit3.lines.add ('int 80h');
end;

procedure TForm1.createFunctions ();
begin
    //create the function 4 checking the input
    createIntCheck;
end;

procedure TForm1.runToolChain ();   //runs the Assembler and the Linker of Linux
begin
    if saveDialog1.FileName <> '' then           //is the File already saved?
    begin
         Button2.Click();                                                //start of by saving the Program
         //runs the different things on the TOOLCHAIN
         synEdit3.Lines.saveToFile (saveDialog1.Filename + '.asm');
         sysUtils.ExecuteProcess   ('/usr/bin/nasm', '-f elf64 ' + saveDialog1.FileName + '.asm', []);
         sysUtils.ExecuteProcess   ('/usr/bin/ld', saveDialog1.Filename + '.o -o ' + saveDialog1.FileName + '.exec', []);
         sysUtils.ExecuteProcess   ('/usr/bin/clear', '', []);
         sysUtils.ExecuteProcess   (saveDialog1.Filename + '.exec', '', []);
    end else
        begin
          Form1.setMistake ('Dein Projekt muss abgespeichert werden, damit es Compiliert werden kann!');
        end;
end;

procedure TForm1.reset();
begin
    synEdit2.Lines.clear();
    synEdit3.Lines.clear();
    setLength(bssArray , 0);
    setLength(dataArray, 0);
    setLength(textArray, 0);
    setLength(textFuncArr, 0);
    setAssemblerData('section .data');
    setAssemblerData('cmp_BLANK: db 0x0a');
    setAssemblerData('cmp_interr: db "Fehler: an dieser Stelle des Programms war eine Zahl erforderlich!", 0x0a');
    setAssemblerData('cmp_interrlen: equ $-cmp_interr');
    setAssemblerData('cmp_intlenerr: db "Fehler: Die eingegebene Zahl war zu gross", 0x0a');
    setAssemblerData('cmp_intlenerr_len: equ $-cmp_intlenerr');
    setAssemblerText('section .text');
    setAssemblerText('global _start');
    setAssemblerText('_start:');
    setAssemblerBss ('section .bss');
    setAssemblerBss ('cmp_input_buffer: resb 1');
    setAssemblerBss ('cmp_write_caret: resb 10'); //for writing Integers als ASCII
    setAssemblerBss ('cmp_buffer: resb 255'); //reserves 255 Bytes for this variable!
    Zeile.resetCommand();
    Form1.mistake:= false;
end;

function TForm1.getLineNumber () : string;
begin
    getLineNumber:= intToStr(m_momLine + 1);
end;
//WRITES INTO THE ARAY TO WRITE INTO THE ASSEMBLER/
procedure TForm1.setAssemblerBss(i :string);
begin
  setLength (bssArray, length(bssArray) +1);
  bssArray[length(bssArray) - 1] := i;
end;

procedure TForm1.setAssemblerData(i :string);
begin
    setLength (dataArray, length(dataArray) +1);
    dataArray[length(dataArray) - 1] := i;
end;

procedure TForm1.setAssemblerText(i: string);
begin
    setLength (textArray, length(textArray) +1);
    textArray[length(textArray) - 1] := i;
end;

procedure TForm1.setAssemblerTextFun (i: string);
begin
     setLength (textFuncArr, length(textFuncArr) +1);
     textFuncArr[length(textFuncArr) - 1] := i;
end;

///////////////////////////////////////////////////

//writes from the array into the Edit-field.
procedure TForm1.writeAssembler();
var counter: integer = 0;
begin
     while counter < length (dataArray) do //first the data-section
     begin
          SynEdit3.Lines.add(dataArray[counter]);
          inc (counter);
     end;
      /////////////////////////////////////
     synEdit3.Lines.add(''); //just for an better looking segmentation.

     counter := 0; //resets the counter
     /////////////////////////////////////
     while counter < length (bssArray) do //now for the bss-section
     begin
          synEdit3.Lines.add(bssArray[counter]);
          inc (counter);
     end;
     ///////////////////////////////////////
     synEdit3.Lines.add('');

     counter := 0;
     //////////////////////////////////////
     while counter < length (textArray) do //last but not leased, the text-section
     begin
          synEdit3.Lines.add(textArray[counter]);
          inc (counter);
     end;

     //terminate run of the program without "segfaulting"! (System call sys_close)
     synEdit3.Lines.add('call func_main');

     synEdit3.Lines.add('mov eax, 1');
     synEdit3.Lines.add('mov ebx, 0');
     synEdit3.Lines.add('int 80h');

     counter := 0;

    while counter < length (textFuncArr) do //Text with functions!
     begin
          synEdit3.Lines.add(textFuncArr[counter]);
          inc (counter);
     end;

     createFunctions();

end;

procedure TForm1.setMistake(i :string);
begin
    synEdit2.Lines.add (i);
    Form1.mistake:= true;
end;

procedure TForm1.feedLines (); ///////////////////////////////THE LOOP WHICH FEEDS THE LINES INTO FUNCTIONS:
var textLength: integer;
begin
    m_momLine       := 0;
    textLength      := synEdit1.Lines.Count;
    synEdit1.enabled:= false;
    //loops throug the Text and feeds the momentary line into the Functions.
    while (m_momLine <= textLength -1) and (mistake = false) do
    begin
       Zeile.setLine    (synEdit1.lines[m_momLine]);
       Zeile.compileLine();
       inc              (m_momLine);
    end;
    synEdit1.enabled:= true;
    if mistake = false then
       begin
              if NOT(Zeile.m_command.noProtoUnsolved()) then
                 begin
                      Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Eine Funktion wurde deklariert aber nicht beschrieben!');
                 end;
              if NOT(Zeile.m_command.mainSet) then
                 begin
                      Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Es wurde keine Haupt-funktion deklariert!');
                 end;
              if NOT(Zeile.m_command.gotoDeployed) then
                 begin
                      Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Der für eine Sprunganweisung verwendete Sprungpunkt wurde nicht definiert!');
                 end;
              if Zeile.m_command.getStacklenght() <> 0 then
                 begin
                    Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Fehler: ende erwartet, aber Dateiende gefunden!');
                 end;
       end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Zeile.Free  (); //deletes the instance of TLine.
  showmessage ('Bis Bald :)'); //CU soon :)
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  reset         ();                 //resets the environnement-variables
  feedLines     ();                 //the compiler
  if mistake = false then
  begin //if the user made a mistake in his code, just don't assemble it!
      writeAssembler();                 //writes everything into the Synedit3-Field
      runToolChain  ();                 //runs the ASSEMBLER and the Linker of Linux
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if saveDialog1.FileName = '' then  //choose the destination
  begin
      if saveDialog1.Execute then    //if the Savedialog was executed, if not, gives an error.
      begin
          synEdit1.Lines.saveToFile (saveDialog1.filename);
      end
         else
             begin
                showmessage ('Du hast keinen dateinamen ausgewählt.');
             end;
  end else
      begin //already choosen the destination
         synEdit1.Lines.saveToFile (saveDialog1.filename);
      end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if openDialog1.execute then
  begin
      synEdit1.Lines.LoadFromFile(openDialog1.filename);
      saveDialog1.FileName := openDialog1.filename;
  end else
      begin
         showmessage ('Du hast keine Datei ausgewählt.');
      end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
    Zeile := TLine.create(); //creates an instance of TLine.
    reset                ();
end;


//###################################################################################################//
/////////////////////////Implementation of the Methods of TLine ///////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////
//***************************************************************************************************//
//###################################################################################################//

procedure TLine.resetCommand();
begin
  m_command.reset();
end;

procedure TLine.passComm();
begin
    m_Command.setCommand(m_ComType);
    m_Command.setArgs   (m_ArgType);
end;

procedure TLine.getCommandInLine();
var bracketPos: integer;
begin
     bracketPos:= pos ('(', m_string);                       //gets the command in the Line, to pass over to the Command-parser

     if NOT(bracketPos = 0) then                            //if there is no bracket. You get the point.
     begin
          m_comType := copy (m_String, 0, bracketPos -1);
     end else
     begin
         m_comType  := m_string;                                    //sets the command to the entire string, if there is no Bracket
     end;
end;

procedure TLine.getArgInLine();
var bracketOpenPos : integer;                       //because the args are between two brackets.
var bracketClosePos: integer;
begin
    bracketOpenPos := pos('(', m_string);
    bracketClosePos:= pos(')', m_string);

    if (bracketClosePos = 0) and (bracketOpenPos <> 0) then   //mistake on not closed bracket.
    begin
        Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Du hast die Klammer nicht geschlossen.');
    end else
    begin
        m_argType:= copy (m_string, bracketOpenPos, bracketClosePos);  //gets the Arg
    end;
end;

destructor TLine.Free();
begin
    m_Command.Free;                               //deletes TCOMMAND
end;

constructor TLine.Create();
begin
    m_Command:= TCommand.Create();                //just to create the instance of TCOMMAND
end;

procedure TLine.deleteComments();
var momString: string;
begin
  getStringLength();                                           //deletes evth. after the two charakters '//'
  momString := m_string;
  delete (momString, pos (m_command.getTextInString(m_string), m_string), length (m_command.getTextInString(m_string)));
  if pos ('//', m_string) <> 0 then
     delete (m_string, pos ('//', m_string) + length (m_command.getTextInString(m_string)), m_stringLength);
end;

procedure TLine.setLine(i: string);        //Setter --> no getter needed.
begin
  m_string:= i;
end;

//////////////////////////////////////////////////////////////////////////////////////////////////
//OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO//
//////////////////////////////////////////////////////////////////////////////////////////////////
procedure TLine.compileLine();             //runs all of the Methods.
begin
   getStringLength    ();                     // gets the length of the String-input
   deleteBLanks       ();                     //deletes all of the blank space inside the String.
   deleteComments     ();                     //deletes comments "//" inside of the text.
   getCommandInLine   ();                     //gets the COmmand inside the Line
   getArgInLine       ();                     //get the Argument inside the Line
   passComm           ();                     //passes the Command and the args into TCOMMAND
   m_command.setFullLine(m_string);
   m_command.compute  ();                     //computes the passed arguements. AND FINALLY: The args get transformed to assembler!
end;
//////////////////////////////////////////////////////////////////////////////////////////////////
//OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO//
//////////////////////////////////////////////////////////////////////////////////////////////////

procedure TLine.deleteBlanks ();           //blankSpace-Deleter
var isText : boolean = false;              //switch, to check, if the momentary Character is text or not.
var counter: integer = 0;                  //counts the number of cycles of the loop
var momChar: string  = '';
begin
     while ((counter < m_stringLength) and (not (m_stringLength = 0))) do//the 'Loop'
     begin
         momChar := copy (m_string, counter, 1);
         if (not (isText)) and (momChar <> ' ') then
         begin
             m_string[counter] := lowercase (m_string[counter]);
         end;
       if ((momChar = ' ') and (not(isText))) then//delete the blank space!
       begin
           if counter = 0 then
           begin
               delete (m_string, counter + 1, 1);  //deletes the blank position
           end else
               delete (m_string, counter, 1);  //deletes the blank position
           dec (counter);                  //because there is a position less in the string now.
           getStringLength();              //regenerates the length of the String;
       end;
       if (momChar = '"') then//the cursor is going out of or in to a text
       begin
           case isText of
             true  : isText:= false;       //switches, if the position is inside a text or not
             false : isText:= true;
           end;
       end;
      inc (counter);
     end;
end;

procedure TLine.getStringLength ();
begin
    m_stringLength:= length (m_string);          //gets the Length of the String input.
end;

//###################################################################################################//
/////////////////////////Implementation of the Methods of Command//////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////
//***************************************************************************************************//
//###################################################################################################//

procedure TCommand.setCommand(command: string);
begin
    m_command:= command;
end;


procedure TCommand.setArgs (args: string);
begin
    m_args:= args;
end;

procedure TCommand.setFullLine (line:String);
begin
    m_fullLine:= line;
end;

procedure TCommand.compute();
begin
    if ((needBegin) and (m_fullLine <> 'anfang')) and (NOT(m_fullLine = '')) then
       begin
          Form1.setMistake ('Zeile' + Form1.getLineNumber() + ': Fehler! "anfang" erwartet!');
       end
    else
      begin
           case lowercase(m_command) of   //searches for the keyword -.-
              'schreiben'   : writeOut ();
              'neuevariable': parseVar ();
              'punktsetzen' : parseGoto();
              'gehezu'      : parseGoto();
              'eingeben'    : handleInputAsm();
              'prototyp'    : handlePrototype();
              'aufrufen'    : callFunc();
              else            proceedKeyW();
          end;
      end;
end;

///////////////////////////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------Write-----------------------------------------------------//
///////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TCommand.writeOut();
begin
    if functionIn = '' then
       begin
          Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Der Befehl schreiben darf nur innerhalb einer Funktion aufgerufen werden!');
       end;
    parseText();
end;

procedure TCommand.handleWriteAsm(isText: Boolean; text: string);
var counter : integer = 0;
begin
     if isText = true then //handle the parsed information as text, Variables will come in later
     begin
         inc(m_numberMessages);
         Form1.setAssemblerData('msg' + IntToStr(m_numberMessages) + ': db "' + text + '"'); //Sets the variable wich has to get wrote down
         /////////////////////////////////////////////////////////////////////////
         Form1.setAssemblerTextFun('mov eax, 4');
         Form1.setAssemblerTextFun('mov ebx, 1');
         Form1.setAssemblerTextFun('mov ecx, msg' + IntToStr(m_numberMessages));
         Form1.setAssemblerTextFun('mov edx, ' + IntToStr(length (text)));   //params for sysCall 4
         Form1.setAssemblerTextFun('int 80h');   //pokes the system
     end else //for variables, or different control-chars
           begin
                if lowerCase(text) = 'nzeile' then
                begin
                  Form1.setAssemblerTextFun('mov eax, 4');
                  Form1.setAssemblerTextFun('mov ebx, 1');
                  Form1.setAssemblerTextFun('mov ecx, cmp_BLANK');
                  Form1.setAssemblerTextFun('mov edx, 1');   //params for sysCall 4
                  Form1.setAssemblerTextFun('int 80h');   //pokes the system
                end else if lowerCase (text) = 'nseite' then
                    begin
                      counter := 0;
                      while counter <= 100 do
                      begin
                         Form1.setAssemblerTextFun('mov eax, 4');
                         Form1.setAssemblerTextFun('mov ebx, 1');
                         Form1.setAssemblerTextFun('mov ecx, cmp_BLANK');
                         Form1.setAssemblerTextFun('mov edx, 1');   //params for sysCall 4
                         Form1.setAssemblerTextFun('int 80h');   //pokes the system
                         inc (counter);
                      end;
                    end  else if varDoesExist (text) then //checks if the pointed variable really DOES exist.
                            begin
                              if varTable[getVarIndex(text), 2] = 'text' then
                                 begin
                                      Form1.setAssemblerTextFun ('mov eax, 4');  //assembly-stuff.
                                      Form1.setAssemblerTextFun ('mov ebx, 1');
                                      Form1.setAssemblerTextFun ('mov ecx, ' + text);
                                      Form1.setAssemblerTextFun ('mov edx, 255');
                                      Form1.setAssemblerTextFun ('int 80h');
                                 end else
                                     begin
                                          Form1.setAssemblerTextFun ('xor eax, eax');
                                          Form1.setAssemblerTextFun ('mov eax, dword[' + text + ']');
                                          //Form1.setAssemblerTextFun ('mov dword[' + text + '], eax');
                                          Form1.setAssemblerTextFun ('call cmp_write_ints');
                                     end;
                            end else
                                begin
                                    Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Die von dir genannte Variable "' + text + '" existiert nicht');
                                end;
                    end;
end;

procedure TCommand.reset();
begin
    m_numberMessages := 0;
    protoAllow       := true;
    functionIn       := '';
    mainSet          := false;
    setLength (varTable, 0);  //empties the array without destructing it!
    setLength (prototypes, 0);//same
    setLength (gotoArray, 0);
    setLength (indentStack, 0);
    lastFNIn         := '';
    protoAllow       := true;
    wasInFunc        := false;
    needBegin        := false;
    numberIf         := 0;
    numberInputs     := 0;
end;

procedure TCommand.parseText();     //In der Dritten Version... hoffen wir, dass ich das nich nochmal schreiben muss.
var parseLength: integer = 0;
var isText     : boolean = false;
var textAccum  : string  = '';
var counter    : integer = 1;
var momChar    : string;
begin
    parseLength := length (m_args);
    textAccum   := '';
    momChar     := '';
     while (counter < parseLength) and (momChar <> ')') do
     begin
      inc (counter, 1);
      momChar:= copy (m_args, counter, 1);
          if momChar = chr (34) then //chr(34) == "
          begin
            isText:= true;
           while true do
            begin
                 inc (counter);
                 momChar:= copy (m_args, counter, 1); //sets the momentan charakter
                 if momChar = '"' then //goes out of the loop
                 begin
                    break;
                 end else   //when the text continues
                         begin
                               textAccum += momChar;
                         end;
                 if counter >= parseLength then   //handles the 'text was not closed' exception
                 begin
                   Form1.setMistake('Zeile:' + Form1.getLineNumber + '. Du Hast eine Text-Sequenz nicht formgemäß geschlossen');
                   isText:= false; //goes out of the Loop
                 end;
            end;
          end;
         if (momChar = '+') or (momChar = ')') then //if the Text Sequence is finished, run the Assembly-Part.
              begin
                 handleWriteAsm(isText, textAccum);
                 isText   := false;
                 textAccum:= '';
                 momChar  := '';
              end;
         if (momChar = '(') then //error-fixing (Unit-Test)
                      begin
                         inc (counter);
                         showmessage ('FAIL AT UNIT TEST 0!');
                      end;
         if ((copy (m_args, counter-1, 1) = '+') or (copy (m_args, counter-1, 1) = '(')) and (momChar <> '"') then//variables //////////////////////////////////////////////////////
                      begin
                       dec (counter);
                           while (momChar <> '+') and (copy (m_args, counter+1, 1) <> ')') do
                              begin
                                   inc (counter);
                                   momChar:= copy (m_args, counter, 1);
                                  if momChar = '+' then
                                     begin
                                      break;
                                     end;
                                   textAccum += momChar;
                              end;
                           if (copy (m_args, counter+1, 1) <> ')') then
                              begin
                                   handleWriteAsm(isText, textAccum);
                                   isText   := false;
                                   textAccum:= '';
                                   momChar  := '';
                              end;
                      end;
      end;
end;

////////////////////////////////////////////////////////////////////////////////
//-----------------------------Variables--------------------------------------//
////////////////////////////////////////////////////////////////////////////////

function TCommand.typeCheck(val: string) : string;    //checks, if the user added a string-in an Integer.
var counter    : Integer;
var parseLength: Integer;
var momChar    : String;
var isText     : boolean = false;
begin
     parseLength:= length (val);
     counter    := 1;
     while counter <= parseLength do
           begin
               momChar := copy (val, counter, 1);
               if (ord (momChar[1])>57) or (ord (momChar[1]) < 48) then
                            begin
                              isText:= true
                            end;
               inc (counter);
           end;
     if isText = true then
        begin
             typeCheck    := 'text';
        end else
            begin
                typeCheck := 'zahl';
            end;
end;

procedure TCommand.parseVar();    //neuevariable (name= wert) //automatische  typerkennung
var name: string = '';
var val : string = '';
begin
     if true then  //for better indentation.
        begin
           if wasInFunc = true then
              begin
                 Form1.setMistake('Zeile ' + Form1.getLineNumber() + ': Variablen dürfen nur am Anfang des Programmes deklariert werden!');
              end;
           if functionIn <> '' then
              begin
                 Form1.setMistake('Zeile ' + Form1.getLineNumber() + ': Variablen dürfen nur auserhalb einer Funktion deklariert werden!');
              end;
           name := copy (m_args, pos ('(', m_args) + 1, pos ('=', m_args) - 2);
           if protoExists (name) then
              begin
                 Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Die Namen von Variablen und Funktionen dürfen sich nicht überschneiden!');
              end;
        end;
     /////////////////////////////////////////////////////////
     if varDoesExist (name) then
         begin
                Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Die Variable gibt es schon.');
         end else if (lowercase(copy (name, 0, 4)) = 'cmp_') or (lowercase (name) = 'ergebniss') then  //cmp-vars are reserved for the Compiler.
         begin
                Form1.setMistake('Zeile ' + Form1.getLineNumber() + ': Dein Variablenname ist reserviert!.');
         end else
         begin
               //starts off by savingthe variable-name into the Array.
               setlength (varTable, length (vartable) + 1);
               varTable [length (vartable)-1, 1]:= name;
               //gets the Value, to which the Variable is assigned.
               val:= copy (m_args, pos ('=', m_args) + 1, pos (')', m_args) - pos ('=', m_args)-1);
               //checks everything
               if (copy (val, 0, 1) = '"') then
                  begin
                      if quoteClosed (m_args) then
                         begin
                              val := getTextInString(m_args);
                              handleVarAsm(val, name, 'text');
                              varTable [length (vartable)-1, 2]:= 'text';
                         end else
                             begin
                                Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Du hast eine Textsequenz nicht formgemäß geschlossen.');
                             end;
                  end else
                  begin
                        if typeCheck (val) = 'zahl' then
                                    begin
                                        varTable [length (vartable)-1, 2]:= 'zahl';
                                        handleVarAsm(val, name, 'zahl');
                                    end else
                                     begin
                                           Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Eine zahl darf keine Buchstaben enthalten!');
                                     end;
                  end;
         end;
end;

function TCommand.varDoesExist (i: string) : boolean;
var counter    : integer = 0;
var arrayLength: integer;
begin
    if varTable = nil then   //if there are no Variables at all.
           begin
               varDoesExist := false;
           end else
               begin //searches the variable-name in the Array. ##nice
                   arrayLength := length (varTable) -1;  //-1 because of the offset.
                   varDoesExist:= false; //sets false by default, which gets changed in the while-loop
                   while counter <= arrayLength do
                         begin
                             if varTable [counter, 1] = i then
                                    begin
                                         varDoesExist:= true; //no comment
                                    end;
                             inc (counter);
                         end;
               end;
end;


function TCommand.getVarIndex (i:string) : integer; //has to get coded, isnt implemented yet
var counter     : integer = 0;
var arrayLength: integer;
begin
    if varTable = nil then
       begin
           getVarIndex := -1; //returns a failure (unit test #1)
           showmessage ('Unit-test Fail #1');
       end else
           begin
               arrayLength := length (vartable) - 1; //gets the length of the array
               while counter <= arrayLength do
                     begin
                         if varTable [counter, 1] = i then   //looks up, if the mom index corresponds to the seeked String.
                            begin
                                getVarIndex:= counter;       //returns the Index
                            end;
                            inc (counter);
                     end;
           end;
end;

procedure TCommand.handleVarAsm (i: string; name: string; itype: string);
var counter: integer = 1;
var total  : integer = 0;
begin
    total := length (i);
    if iType = 'zahl' then
       begin
            Form1.setAssemblerBss  (name +': resd 1');
            Form1.setAssemblerText ('mov dword[' + name+ '], ' + i);
       end else
       begin
            if total > 255 then
               begin
                  Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Variablen der art "Text" dürfen nicht mehr als 255 Zeichen beinhalten.');
                  total := 255;
               end;
            Form1.setAssemblerBss (name + ': resb 255');
            while counter <= total do
                  begin
                       if i = '"' then
                          begin
                             Form1.setAssemblerText ('mov BYTE[' + name + ' + ' + intToStr (counter-1) + '], "' + ' ' + '"'); //inputs the single Char
                             break;
                          end else
                                 begin
                                      Form1.setAssemblerText ('mov BYTE[' + name + ' + ' + intToStr (counter-1) + '], "' + copy (i, counter, 1) + '"'); //inputs the single Char
                                      inc(counter); //increments counter
                                 end;
                  end;
       end;
end;


///////////////////////////////////////////////////////////////////////////////////
////////////////////////////GOTO AND CO////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

procedure TCommand.parseGoto();
var newArg : string  = '';
var i      : integer = 0;
var foundLa: boolean = false;
begin
    if functionIn = '' then
       begin
          Form1.setMistake('Zeile ' + Form1.getLineNumber() + ': Der Befehl gehezu muss in einer Funktion stehen!');
       end;
    newArg := copy (m_args, pos ('(', m_args) + 1, pos (')', m_args) - 2);
     if m_command = 'punktsetzen' then
        begin
            if (copy (newArg, 0, 3) = 'cmp') or (copy (newArg, 0, 5) = 'func_') then
               begin
                  Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Der Name eines Sprungpunktes darf nicht mit cmp anfangen.');
               end else
                   begin
                      for i := 0 to length (gotoArray) -1 do
                      begin
                         if gotoArray[i, 1] = newArg then
                            begin
                               foundLa := true;
                               break;
                            end;
                      end;
                      if (foundLa = true) and (gotoArray[i, 3] = '1') then
                         begin
                              Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Dieser Sprungpunkt existiert schon!');
                         end else
                             begin
                                     Form1.setAssemblerTextFun('cmp_goto_' + newArg + ':');
                                     if foundLa then
                                        begin
                                              if (gotoArray [i, 3] = '1') and (gotoArray [i, 2] <> functionIn) then
                                                    begin
                                                      Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Sprungpunkte dürfen Funktionen nicht überspringen!');
                                                    end;
                                                       gotoArray[i, 3] := '1';
                                        end else
                                            begin
                                                 setLength (gotoArray, length (gotoArray) +1);
                                                 gotoArray [length (gotoArray) -1, 1] := newArg;
                                                 gotoArray [length (gotoArray) -1, 2] := functionIn;
                                                 gotoArray [length (gotoArray) -1, 3] := '1';
                                            end;
                             end;
                   end;
            end else if m_command = 'gehezu' then
                              begin
                                  if copy (newArg, 0, 3) = 'cmp' then
                                     begin
                                        Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Der Name eines Sprungpunktes darf nicht mit cmp anfangen.');
                                     end else
                                         begin                                            for i := 0 to length (gotoArray) -1 do
                                            begin
                                               if gotoArray[i, 1] = newArg then
                                                  begin
                                                     foundLa := true;
                                                     break;
                                                  end;
                                            end;
                                                if foundLa then
                                                   begin
                                                      if gotoArray[i, 2] = functionIn then
                                                         begin
                                                           Form1.setAssemblerTextFun('jmp ' + 'cmp_goto_' + newArg);
                                                         end else
                                                             begin
                                                                Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Sprungpunkte dürfen Funktionen nicht überspringen!');
                                                             end;
                                                   end else
                                                       begin
                                                           setLength (gotoArray, length (gotoArray) + 1);
                                                           gotoArray[length (gotoArray) -1, 1] := newArg;
                                                           gotoArray[length (gotoArray) -1, 2] := functionIn;
                                                           gotoArray[length (gotoArray) -1, 3] := '0';
                                                           Form1.setAssemblerTextFun('jmp ' + 'cmp_goto_' + newArg);
                                                       end;
                                         end;
                              end;
end;

//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////GENERAL FUNCTIONS/////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

function TCommand.getTextInString (i: string) : string;
var textAccum   : string  = '';
var counter     : integer = 1;
var parseLen    : integer = 0;
var numberQuotes: integer = 0;
var momChar     : string  = '';
begin
     parseLen := length (i);
     while counter < parselen do
           begin
              momChar := copy (i, counter, 1);    //copie the momentan
                if momChar = '"' then
                   begin                                                        //if its a quote, increase the couter
                      inc (numberQuotes);
                      inc (counter); //switches to the next char
                      momChar := copy (i, counter, 1);
                   end;
                if numberQuotes = 1 then
                   begin
                      textAccum += momChar;         //if theres a quote, take the text
                   end;
                if numberQuotes = 2 then
                   begin
                      break;                         //if the quote is closed, break out of the loop
                   end;
                inc (counter);
           end;
     getTextInString := textAccum;
end;

function TCommand.quoteClosed (i: string) : boolean;
var counter     : integer = 0;
var parseLen    : integer = 0;
var numberQuotes: integer = 0;
var momChar     : string  = '';
begin
     parseLen := length (i);
     while counter < parselen do
           begin
              quoteClosed := false;
              momChar := copy (i, counter, 1);    //copie the momentan character
                if momChar = '"' then
                   begin                                                        //if its a quote, increase the couter
                      inc (numberQuotes);
                   end;
                if numberQuotes = 1 then
                   begin
                      quoteClosed := false;
                   end;
                if numberQuotes = 2 then
                   begin
                      quoteClosed := true;
                      break;                         //if the quote is closed, break out of the loop
                   end;
                inc (counter);
           end;
end;

procedure popa ();
begin
     Form1.setAssemblerTextFun ('pop eax');
     Form1.setAssemblerTextFun ('pop ebx');
     Form1.setAssemblerTextFun ('pop ecx');
     Form1.setAssemblerTextFun ('pop edx');
end;

procedure pusha ();
begin
     Form1.setAssemblerTextFun ('push eax');
     Form1.setAssemblerTextFun ('push ebx');
     Form1.setAssemblerTextFun ('push ecx');
     Form1.setAssemblerTextFun ('push edx');
end;

////////////////////////77777777777777777////////////////////////////////////////////////////////////////77
////////////////////////////////////INPUT//////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
procedure TCommand.handleInputAsm ();
var varName : string;
var counter : integer = 0;
var total   : integer = 0;
begin
     if functionIn = '' then
        begin
           Form1.setMistake('Zeile ' + Form1.getLineNumber() + ': Der Befehl eingeben muss in einer Funktion stehen!');
        end;
     varName := getTextWOBrackets (m_args);
    if varDoesExist(varName) then
        begin
           counter := 0;
           if varTable [getVarIndex (varName), 2] = 'zahl' then //Integer-types
               begin
                  //BUG: The thing doesn't get parsed right. Solve: read in char for char and check for 0x0a..
                  Form1.setAssemblerTextFun(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,');
                  Form1.setAssemblerTextFun('mov edx, 0000');
                  Form1.setAssemblerTextFun('mov [cmp_buffer], DWORD 00000000');
                  Form1.setAssemblerTextFun('input_loop' + intToStr(numberInputs) + ':');
                  Form1.setAssemblerTextFun('mov [cmp_input_buffer], byte 0000');
                  Form1.setAssemblerTextFun('inc edx');
                  Form1.setAssemblerTextFun('push dx');
                  Form1.setAssemblerTextFun('mov eax, 3');
                  Form1.setAssemblerTextFun('mov ebx, 1');
                  Form1.setAssemblerTextFun('mov ecx, cmp_input_buffer');
                  Form1.setAssemblerTextFun('mov edx, 1');
                  Form1.setAssemblerTextFun('int 80h');
                  Form1.setAssemblerTextFun('mov ecx, [cmp_input_buffer]');
                  Form1.setAssemblerTextFun('cmp ecx, 0x0a');
                  Form1.setAssemblerTextFun('je after_input_loop' + intToStr(numberInputs));
                  Form1.setAssemblerTextFun('cmp ecx, 0x30');
                  Form1.setAssemblerTextFun('jl cmp_interror');
                  Form1.setAssemblerTextFun('cmp ecx, 0x39');
                  Form1.setAssemblerTextFun('jg cmp_interror');
                  Form1.setAssemblerTextFun('pop dx');
                  Form1.setAssemblerTextFun('cmp edx, 5');
                  Form1.setAssemblerTextFun('je cmp_skip_input_loop' + intToStr(numberInputs));
                  Form1.setAssemblerTextFun('sub ecx, 0x30');
                  Form1.setAssemblerTextFun('mov ebx, DWORD [cmp_buffer]');
                  Form1.setAssemblerTextFun('mov eax, 10');
                  Form1.setAssemblerTextFun('imul ebx, eax');
                  Form1.setAssemblerTextFun('add ebx, ecx');
                  Form1.setAssemblerTextFun('mov [cmp_buffer], ebx');
                  Form1.setAssemblerTextFun('cmp_skip_input_loop' + intToStr(numberInputs) + ':');
                  Form1.setAssemblerTextFun('jmp input_loop' + intToStr(numberInputs));
                  Form1.setAssemblerTextFun('after_input_loop' + intToStr(numberInputs) + ':');
                  Form1.setAssemblerTextFun('pop dx');
                  Form1.setAssemblerTextFun('cmp dx, 5');
                  Form1.setAssemblerTextFun('jg cmp_int_len_error');
                  Form1.setAssemblerTextFun('mov dword [' + varName + '], 0000');
                  Form1.setAssemblerTextFun('xor ecx, ecx');
                  Form1.setAssemblerTextFun('mov ecx, DWORD [cmp_buffer]');
                  Form1.setAssemblerTextFun('mov [' + varName + '],dword ecx');
               end else
                   begin
                      total := 255;
                      while counter < total do
                       begin
                               Form1.setAssemblerTextFun ('mov BYTE[' + varName + ' + ' + intToStr(counter) + '], 0'); //inputs the single Char
                               inc (counter);
                       end;
                      Form1.setAssemblerTextFun ('mov eax, 3');
                      Form1.setAssemblerTextFun ('mov ebx, 1');
                      Form1.setAssemblerTextFun ('mov ecx, ' + varname);
                      Form1.setAssemblerTextFun ('mov edx, 255');
                      Form1.setAssemblerTextFun ('int 80h');
                      Form1.setAssemblerTextFun ('mov eax, ' + varname);
                      Form1.setAssemblerTextFun ('cmp_input_loop' + intToStr(numberInputs) + ':');
                      Form1.setAssemblerTextFun ('cmp byte [eax], 0x0a');
                      Form1.setAssemblerTextFun ('je cmp_skip_input_loop' + intToStr(numberInputs));
                      Form1.setAssemblerTextFun ('inc eax');
                      Form1.setAssemblerTextFun ('jmp cmp_input_loop' + intToStr(numberInputs));
                      Form1.setAssemblerTextFun ('cmp_skip_input_loop' + intToStr(numberInputs) + ':');
                      Form1.setAssemblerTextFun ('mov [eax],byte 0x00');
                   end;
        end;
end;

function TCommand.getTextWOBrackets (i: string) : string; //get the Text inside Brackets (Mainly, because m_args delivers the Brackets)
begin
     getTextWOBrackets := copy (i, 2, pos (')', i) - 2);
end;

////////////////////////////////PROCEED Functions with no Brackets ///////////////////////////////////
procedure TCommand.proceedKeyW ();
var validKeyword : boolean = false;
begin
    if copy (m_fullLine, 0, 4) = 'leer' then //void functions
        begin
          validKeyWord := true;
          handleVoidFunc();
        end;
    if copy (m_fullLine, 0, 5) = 'haupt' then //function main ()
        begin
          validKeyWord := true;
          handleMainFunc();
        end;
    if copy (m_fullLine, 0, 4) = 'zahl' then //integer returning-functions
        begin
          validKeyWord := true;
        end;
    if copy (m_fullLine, 0, 4) = 'text' then
        begin
          validKeyWord := true;
        end;
    if m_fullline = 'anfang' then //begin .. end section
        begin
          validKeyWord := true;
          handleBegin ();
        end;
    if m_fullLine = 'ende' then //begin...end section (end)
        begin
          handleEnd();
          validKeyWord := true;
        end;
    if copy (m_fullLine, 0, 4) = 'wenn' then //If-Statements.
        begin
          handleIF();
          validKeyWord := true;
        end;
    if varDoesExist (copy (m_fullLine, 0, pos ('=', m_fullline) + 1)) then  //for operations on variables
        begin
          validKeyWord := true;
        end;
    if (validKeyWord = false) and (m_fullLine <> '') then //if the Keyword was invalid
        begin
            Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Der Befehl ' + m_fullLine + ' wurde vom Compiler nicht erkannt!');
        end;
end;


procedure TCommand.handleBegin ();
var lengthOfStack : integer = 0;
begin
    if NOT(needBegin = true) then
      begin
        Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Unerwartet: Befehl erwartet aber anfang gefunden');
      end;
      wasInFunc:= true;
      lengthOfStack := length (indentStack) + 1;
      needBegin     := false;
      setLength (indentStack, lengthOfStack);
      if functionIn = 'haupt' then
          begin
              indentStack[lengthOfStack -1, 1] := 'haupt';
              indentStack[lengthOfStack -1, 2] := Form1.getLineNumber(); //As the array is a String...
          end;
      if lastFNIn = 'leer' then //for void functions
          begin
             indentStack[lengthOfStack -1, 1] := functionIn; //name
             indentStack[lengthOfStack -1, 2] := 'leer';     //type
             indentStack[lengthOfStack -1, 3] := Form1.getLineNumber(); //line_number
             Form1.setAssemblerTextFun(functionIn + ':');
             prototypes[getProtoIndex(functionIn), 2] := '1'; //sets the prototype to true
          end;
      if lastFNIn = 'wenn' then //if
          begin
             indentStack[lengthOfStack -1, 1] := intToStr(numberIf); //name (N-th if-Statement)
             indentStack[lengthOfStack -1, 2] := 'wenn';     //type
             indentStack[lengthOfStack -1, 3] := Form1.getLineNumber(); //line_number
          end;

end;

procedure TCommand.handlePrototype ();
var proto: string;
begin
   if wasInFunc = true then
        begin
           Form1.setMistake('Zeile ' + Form1.getLineNumber() + ': Variablen dürfen nur am Anfang des Programmes deklariert werden!');
        end;
     if protoAllow then
         begin
            proto := m_args;      //copies the inside of the brackets into proto
            if varDoesExist(getTextWOBrackets(proto)) then  //checks, if there is already a variable called like the new function
                begin
                  Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Die Namen von Variablen und Funktionen dürfen sich nicht überschneiden!');
                end;
            proto := getTextWOBrackets(proto);  //gets the prototype without the surrounding brackets
            proto := lowerCase (proto);
            if NOT(protoExists (proto)) then //checks, if there is already a protoype called like this.
                begin
                   setlength (prototypes, length (prototypes) +1);
                   prototypes [length (prototypes) -1, 1] := proto;
                   prototypes [length (prototypes) -1, 2] := '0'; //false, but theres no boolean -.-
                end else
                    begin
                         Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Diese Funktion wurde schon benannt!');
                    end;
         end else
             begin
                  Form1.setMistake ('Zeile ' +  Form1.getLineNumber() + ': Nach einer Funktionsanweisung dürfen keine Prototypen für funktionen mehr kommen!');
             end;
end;

function TCommand.protoExists (i: string) : boolean;
var counter  : integer = 0;
var lengthOf : integer = 0;
var momString: string  = '';
begin
   protoExists  := false;
     if i = 'haupt' then
         begin
            Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Die Funktion haupt braucht keinen Prototypen!');
         end else
             begin
                  if prototypes = nil then
                    begin
                       protoExists := false; //if the array is empty, there obviously can't be a protoype already called like this
                    end else
                        begin
                            lengthOf := length (prototypes) -1;
                            while counter <= lengthOf do //iterates throug the array and does some logic
                                  begin
                                      momString := prototypes [counter, 1];
                                      if momString = i then
                                          begin
                                             protoExists := true;
                                             break;
                                          end;
                                      inc (counter);
                                  end;
                        end;
             end;
end;

function TCommand.noProtoUnsolved () : boolean; //if every prototype got its function assigned
var counter  : integer = 0;
var lengthOf : integer = 0;
begin
  lengthOf := length (prototypes) -1;
     if prototypes = nil then
       begin
          noProtoUnsolved := true; //if the array is empty, there obviously can't be a protoype already called like this
       end else
           begin
              noProtoUnsolved := true;
               while counter <= lengthOf do
                     begin
                          if prototypes [counter, 2] = '0' then
                              begin
                                   noProtoUnsolved := false; // if theres an unsolved protoype
                                   break;
                              end;
                          inc (counter);
                     end;
           end;
end;

function TCommand.getProtoIndex (i: string) : integer;    //get the index of the name of the prototype inside the array.
var counter  : integer = 0;
var lengthOf : integer = 0;
begin
  lengthOf := length (prototypes) -1;
     if prototypes = nil then
       begin
          getProtoIndex := -1; //if the array is empty, throw an error-code!
       end else
           begin
               while counter <= lengthOf do
                     begin
                          if prototypes [counter, 1] = i then
                              begin
                                   getProtoIndex := counter;
                                   break;
                              end;
                          inc (counter);
                     end;
           end;
end;

procedure TCommand.handleMainFunc (); //for the Main-function...
begin
  protoAllow:= false; //no prototypes allowed anymore
  if mainSet = true then
      begin
         Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Die funktion haupt darf nur einmal im Programm vorkommen!');
      end;
  mainSet   := true;
  needBegin := true;
  functionIn:= 'haupt';
  Form1.setAssemblerTextFun('func_main:');
end;

procedure TCommand.handleEnd ();
begin
  if length (indentStack) = 0 then
      begin
           Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Funktionsdeklaration erwartet aber ende gefunden!');
      end;
  if indentStack[length (indentStack) - 1, 1] = 'haupt' then
      begin
         Form1.setAssemblerTextFun('ret');
         FunctionIn := '';
      end;
  if indentStack[length (indentStack) - 1, 2] = 'leer' then
      begin
         functionIn := '';
         Form1.setAssemblerTextFun('ret');
      end;
  if indentStack [length (indentStack) - 1, 2] = 'wenn' then
      begin
        Form1.setAssemblerTextFun('cmp_after_if' + indentStack[length (indentStack) - 1, 1]  + ':');
      end;
  setLength (indentStack, length (indentStack) - 1);
end;

function TCommand.gotoDeployed : boolean; //iterates throug the label-array, and checks, if every goto was really implemented.
var counter : integer = 0;
begin
  if gotoArray = nil then
    begin
       gotoDeployed := true; //if the array is empty, throw an error-code!
    end else
        begin
           gotoDeployed := true;
            while counter <= length (gotoArray)-1 do
                  begin
                       if gotoArray [counter, 3] = '0' then
                           begin
                                gotoDeployed := false;
                                break;
                                Form1.setMistake (gotoArray [counter, 1]);
                           end;
                       inc (counter);
                  end;
        end;
end;

procedure TCommand.handleVoidFunc ();
var func_name: string;
var parse    : string;
begin
   needBegin := true;
   parse     := copy (m_fullLine, 5, length (m_fullLine) - 4); //removes the prefix for void functions
   parse     := lowerCase (parse);
   if NOT(protoExists (parse)) then
       begin
            Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Die Funktion ' + parse + ' hat keinen Prototypen.');
       end;
   if prototypes[getProtoIndex (parse), 2] = '1' then
       begin
          Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Dieser Prototyp wurde schon einmal beschrieben.');
       end;
   func_name := parse;
   functionIn:= func_name;
   lastFNIn  := 'leer';
end;

procedure TCommand.callFunc ();
var parse : string = ''; //just the momStrng without brackets ()
begin
    parse := getTextWOBrackets(m_args); //removes the brackets
    if NOT(protoExists(parse)) then //if the prototype doesn't exist, throw an error!
        begin
            Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Die aufgerufene Funktion ' + parse + ' gibt es garnicht');
        end else
            begin
                Form1.setAssemblerTextFun('call ' + parse); //sets the assembler
            end;
end;


procedure TCommand.handleIf();
begin
    //First check, what type of vars get checked to each others.
    needBegin := true;
    lastFNIn  := 'wenn';
    if pos ('==', 'spacer' + m_fullLine) <> 0 then //on equal
        begin
           handleEqu();
        end;
end;

procedure TCommand.handleEqu ();       //SORRY for this crappy function! I'm too lazy to remake this. ya know?
var firstOp  : string;
var secondOP : string;
var opPos    : integer;
var asmText  : string;
var op1Type  : string = '';
var op2Type  : string = '';
var switchCon: string;
begin
     opPos   := pos ('==', m_fullLine);
     firstOp := copy (m_fullLine, 5, opPos-5);  //the operand before the ==
     secondOP:= copy (m_fullLine, opPos + 2, length (m_fullLine));     //after ==
     if varDoesExist(firstOP) then      //Does the variable of first op exist?
         begin
           op1Type := 'var';
         end else
             begin
                if ord (firstOp[1]) = 34 then
                    begin
                      op1Type := 'text';
                    end else
                        begin
                           if typeCheck(firstOp) = 'zahl' then
                               begin
                                 op1Type := 'zahl';
                               end else
                                   begin
                                      Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Zahlen dürfen keinen Text enthalten!');
                                   end;
                        end;
             end;
             asmText := 'cmp eax, ';
         if varDoesExist(secondOP) then      //Does the variable of first op exist?
         begin
              op2Type:= 'var';
         end else
             begin
                if ord (secondOp[1]) = 34 then       //strings can't be compared to ints. ya know
                    begin
                         op2Type:= 'text';
                    end else
                        begin
                           if typeCheck(secondOp) = 'zahl' then
                               begin
                                   op2Type:= 'zahl';
                               end else
                                   begin
                                      Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Zahlen dürfen keinen Text enthalten!');
                                   end;
                        end;
             end;
         inc (numberIf);
         //Tests, if the Compared vars are Texts and Vars
         if ((op1Type = 'text') and (op2Type = 'var')) or ((op1Type = 'var') and (op2Type = 'text')) then   //if the compared types are strings and variables
             begin
                  if op1Type = 'var' then //checks if the variables are really string-typed
                      begin
                          if vartable[getVarIndex(firstOp), 2] <> 'text' then
                              begin
                                     Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Du kannst Texte nicht mit Zahlen vergleichen!');
                              end;
                      end else
                          begin
                             switchCon:= firstOp;  //swaps them in place, so they can't penguin anymore
                             firstOp  := secondOp;
                             secondOp := switchCon;
                             if vartable[getVarIndex(secondOp), 2] <> 'text' then
                                 begin
                                        Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Du kannst Texte nicht mit Zahlen vergleichen!');
                                 end;
                          end;
                   handleEquVarAndText(firstOp, secondOp);
             end else if (op1Type = 'var') and (op2Type = 'zahl') then //var and Var
                      begin
                          if vartable [getVarIndex (firstOp), 2] <> 'zahl' then //Wenn die Variablen einen anderen Datentypen haben.
                             begin
                               Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Du Darfst zahlen nur mit Zahlvariablen vergleichen!');
                             end else
                             begin
                                  handleEquVarAndInt (firstOp, secondOp);
                             end;
                      end else if ((op1Type = 'zahl') and (op2Type = 'zahl')) or ((op1Type = 'text') and (op1Type = 'text')) then
                          begin
                              if NOT (firstOp = secondOP) then
                                begin
                                     Form1.setAssemblerTextFun('jmp cmp_after_if' + intToStr(numberIf));
                                end;
                          end else if (op1Type = 'var') and (op2Type = 'var') then
                              begin
                                     handleEquVarAndVar(firstOp, secondOp);
                              end;
end;

function TCommand.getStacklenght () : integer;
begin
     getStackLenght := length (indentStack);
end;

procedure TCommand.handleEquVarAndText (firstOp: string; secondOp: string); //first op is supposed to be the Variable, second Op the text.
var counter : integer = 1;
var momChar : char;
begin
//Straigth forward: I take the variable, split it into little Pieces, and do the same with the string.
    secondOp:= getTextInString(secondOp);
    while (counter < 255) do //does as long as the string-limit isn't reached!
      begin
         if counter > length (secondOp) then
          begin
               break;
          end;
          momChar := secondOp[counter];
          Form1.setAssemblerTextFun('mov al, [' + firstOp + ' + ' + intToStr (counter - 1) + ']');
          Form1.setAssemblerTextFun('cmp al, ' + intToStr(ord (momChar))); //checks, if the ASCII-number of the Checked Text matches the vars text.
          Form1.setAssemblerTextFun('jne cmp_after_if' + intToStr (numberIf));
          inc (counter); // -.-
      end;
    if counter <> 255 then
     begin
       Form1.setAssemblerTextFun('mov al, [' + firstOp + ' + ' + intToStr (counter - 1) + ']');
       Form1.setAssemblerTextFun('cmp al, 0'); //checks, if the ASCII-number of the Checked Text matches the vars text.
       Form1.setAssemblerTextFun('jne cmp_after_if' + intToStr (numberIf));
     end;
end;


procedure TCommand.handleEquVarAndInt (firstOp: string; secondOp: string);
var counter: integer = 4;
var momChar: char;
begin
    counter := length (secondOp);
    Form1.setAssemblerTextFun('mov eax, dword[' + firstOp + ']');
    Form1.setAssemblerTextFun('mov ecx, dword[' + firstOp + ']');
    while (counter <> 0) do //does as long as the int-limit isn't reached!
      begin
          momChar := secondOp[counter];
          Form1.setAssemblerTextFun('call cmp_get_last_int');
          Form1.setAssemblerTextFun('cmp dl, ' + momChar); //checks, if the ASCII-number of the Checked Text matches the vars text.
          Form1.setAssemblerTextFun('jne cmp_after_if' + intToStr (numberIf));
          dec (counter); // -.-
      end;
    Form1.setAssemblerTextFun('mov dword[' + firstOp + '], ecx');
end;

procedure TCommand.handleEquVarAndVar (firstOp: string; secondOp: string);
var counter : integer = 0;
begin
    if vartable[getVarIndex(firstOp), 2] = vartable [getVarIndex(secondOp), 2] then
     begin
        if vartable[getVarIndex(firstOp), 2] = 'text' then
         begin
         //Straigth forward: I take the variable, split it into little Pieces, and do the same with the string.
            while (counter < 255) do //does as long as the string-limit isn't reached!
              begin
                  Form1.setAssemblerTextFun('mov al, [' + firstOp  + ' + ' + intToStr (counter) + ']');
                  Form1.setAssemblerTextFun('mov bl, [' + secondOp + ' + ' + intToStr (counter) + ']');
                  Form1.setAssemblerTextFun('cmp al, bl');
                  Form1.setAssemblerTextFun('jne cmp_after_if' + intToStr (numberIf));
                  inc (counter); // -.-
              end;
          end else
              begin
                 secondOp:= getTextInString(secondOp);
                 Form1.setAssemblerTextFun('mov eax, dword[' + firstOp  + ']');
                 Form1.setAssemblerTextFun('mov ebx, dword[' + secondOp + ']');
                 Form1.setAssemblerTextFun('cmp al, bl');
                 Form1.setAssemblerTextFun('jne cmp_after_if' + intToStr (numberIf));
                 inc (counter); // -.-
              end;
     end else
         begin
              Form1.setMistake ('Zeile ' + Form1.getLineNumber() + ': Es dürfen nur Variablen der gleichen Art verglichen werden!');
         end;
end;



{$R *.lfm}

end.

