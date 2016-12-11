unit compiler_code;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterAny, SynCompletion, Forms,
  Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, IniFiles, LCLType;

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
             private    //private members
                   var m_command  : string;
                   var m_args     : string;
                   var m_fullLine : string;
                   var mainSet    : boolean;
                   var lastFNIn   : string; //for the type of function.
                   var functionIn : string; //the Function were momentary in.
                   var needBegin  : boolean; //If a begin sequence is required on the next Line.
                   var indentStack: array of array [1 .. 2] of string; //type|lineNumber of start//Used for begin-end; sequences.
                   var prototypes : array of array [1 .. 2] of string; //name|solved//If solved isnt, error
                   var protoAllow : boolean; //If protoypes aren't allowed (after the first function)
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
                     var varTable : array of array [1..2] of string; //vartable Column 1 = name, Column 2 = value
             ///////////////////GOTO//////////////////////////////////////
             private //functions
                     procedure parseGoto     ();
             private //variables
             ///////////////////INPUT/////////////////////////////////////
             private //functions
                     procedure handleInputAsm ();
             private //variables
             //////////////////BEGIN...END////////////////////////////////
             private
                     procedure handleBegin ();
             private
             //////////////////IF-STATEMENTS//////////////////////////////
             private

             private
             //Functions
             private
                 procedure handleMainFunc  ();
             private
             //function prototypes
             private
                 procedure handlePrototype ();
                 function  protoExists     (i: string) : boolean; //if theres already a prototype called like this... SHIT MAN
                 function  getProtoIndex   (i: string) : integer;
             private
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
begin
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
     synEdit3.lines.add ('ret');
     synEdit3.lines.add ('cmp_interror:');
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
          showmessage ('Dein Projekt muss abgespeichert werden, damit es Compiliert werden kann!');
        end;
end;

procedure TForm1.reset();
begin
    synEdit2.Lines.clear();
    synEdit3.Lines.clear();
    setLength(bssArray , 0);
    setLength(dataArray, 0);
    setLength(textArray, 0);
    setAssemblerData('section .data');
    setAssemblerData('cmp_BLANK: db 0x0a');
    setAssemblerData('cmp_interr: db "error, You have typed in a non-Integer Character!", 0x0a');
    setAssemblerData('cmp_interrlen: equ $-cmp_interr');
    setAssemblerData('cmp_buffer: times 9 db 0x00');
    setAssemblerText('section .text');
    setAssemblerText('global _start');
    setAssemblerText('_start:');
    setAssemblerBss ('section .bss');
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
     textArray[length(textFuncArr) - 1] := i;
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
     synEdit3.Lines.add('mov eax, 1');
     synEdit3.Lines.add('mov ebx, 0');
     synEdit3.Lines.add('int 80h');

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
    m_momLine   := 0;
    textLength:= synEdit1.Lines.Count;
    //loops throug the Text and feeds the momentary line into the Functions.
    while (m_momLine <= textLength -1) and (mistake = false) do
    begin
       Zeile.setLine    (synEdit1.lines[m_momLine]);
       Zeile.compileLine();
       inc              (m_momLine);
    end;
    if NOT(Zeile.m_command.noProtoUnsolved()) then
       begin
            Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Eine Funktion wurde deklariert aber nicht beschrieben!');
       end;
    if NOT(Zeile.m_command.mainSet) then
       begin
            Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Es wurde keine Haupt-funktion deklariert!');
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
begin
  getStringLength();                                           //deletes evth. after the two charakters '//'
  delete         (m_string, pos ('//', m_string), m_stringLength);
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
    if ((needBegin) and (m_fullLine <> 'begin')) and (NOT(m_fullLine = '')) then
       begin
          Form1.setMistake ('Zeile' + Form1.getLineNumber() + ': Fehler! "begin" benötigt!');
       end
    else
      begin
           case lowercase(m_command) of
              'schreiben'   : writeOut ();
              'neuevariable': parseVar ();
              'punktsetzen' : parseGoto();
              'gehezu'      : parseGoto();
              'eingeben'    : handleInputAsm();
              'prototyp'    : handlePrototype();
              else            proceedKeyW();
          end;
      end;
end;

///////////////////////////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------Write-----------------------------------------------------//
///////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TCommand.writeOut();
begin
    parseText();
end;

procedure TCommand.handleWriteAsm(isText: Boolean; text: string);
begin
     if isText = true then //handle the parsed information as text, Variables will come in later
     begin
         inc(m_numberMessages);
         Form1.setAssemblerData('msg' + IntToStr(m_numberMessages) + ': db "' + text + '"'); //Sets the variable wich has to get wrote down
         /////////////////////////////////////////////////////////////////////////
         Form1.setAssemblerText('mov eax, 4');
         Form1.setAssemblerText('mov ebx, 1');
         Form1.setAssemblerText('mov ecx, msg' + IntToStr(m_numberMessages));
         Form1.setAssemblerText('mov edx, ' + IntToStr(length (text)));   //params for sysCall 4
         Form1.setAssemblerText('int 80h');   //pokes the system
     end else //for variables, or different control-chars
           begin
                if lowerCase(text) = 'nzeile' then
                begin
                  Form1.setAssemblerText('mov eax, 4');
                  Form1.setAssemblerText('mov ebx, 1');
                  Form1.setAssemblerText('mov ecx, cmp_BLANK');
                  Form1.setAssemblerText('mov edx, 1');   //params for sysCall 4
                  Form1.setAssemblerText('int 80h');   //pokes the system
                end else
                    begin
                         if varDoesExist (text) then //checks if the pointed variable really DOES exist.
                            begin
                               Form1.setAssemblerText ('mov eax, 4');  //assembly-stuff.
                               Form1.setAssemblerText ('mov ebx, 1');
                               Form1.setAssemblerText ('mov ecx, ' + text);
                               Form1.setAssemblerText ('mov edx, 255');
                               Form1.setAssemblerText ('int 80h');
                            end else
                                begin
                                    Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Die von dir genannte Variable "' + text + '" existiert nicht');
                                end;
                    end;
           end;
end;

procedure TCommand.reset();
begin
    m_numberMessages := 0;
    protoAllow       := true;
    setLength (varTable, 0);  //empties the array without destructing it!
    setLength (prototypes, 0);//same
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
     name := copy (m_args, pos ('(', m_args) + 1, pos ('=', m_args) - 2);
     if varDoesExist (name) then
         begin
                Form1.setMistake ('Zeile ' + Form1.getLineNumber () + ': Die Variable gibt es schon.');
         end else if (lowercase(copy (name, 0, 4)) = 'cmp_') or (lowercase (name) = 'ergebniss') then  //cmp-vars are reserved for the Compiler.
         begin
                Form1.setMistake('Zeile ' + Form1.getLineNumber() + ': Dein Variablenname ist reserviert!.');
         end else
         begin
               //starts off by savingthe variable-name into the Array.
               setlength (varTable, length (vartable[1]));
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
                        val:= getTextInString(m_args);
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
                   arrayLength := length (varTable[1]) -1;  //-1 because of the offset.
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
               arrayLength := length (vartable[1]) - 1; //gets the length of the array
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
          if total > 9 then
             begin
                Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Variablen der art "Zahl" dürfen nicht mehr als neunstellige Beträge beinhalten');
                total := 9;
             end;
          Form1.setAssemblerBss (name + ': resb 9');
          while counter < total do
                begin
                   Form1.setAssemblerText ('mov BYTE[' + name + ' + ' + intToStr (counter-1) + '], "' + copy (i, counter, 1) + '"'); //inputs the single Char
                   inc(counter); //increments counter
                end;
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
                     Form1.setAssemblerText ('mov BYTE[' + name + ' + ' + intToStr (counter-1) + '], "' + copy (i, counter, 1) + '"'); //inputs the single Char
                     inc(counter); //increments counter
                  end;
       end;
end;


///////////////////////////////////////////////////////////////////////////////////
////////////////////////////GOTO AND CO////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

procedure TCommand.parseGoto();
var newArg : string = '';
begin
    newArg := copy (m_args, pos ('(', m_args) + 1, pos (')', m_args) - 2);
     if m_command = 'punktsetzen' then
        begin
            if copy (newArg, 0, 3) = 'cmp' then
               begin
                  Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Der Name eines Sprungpunktes darf nicht mit cmp anfangen.');
               end else
                   begin
                      Form1.setAssemblerText (newArg + ':');
                   end;
        end else if m_command = 'gehezu' then
                              begin
                                  if copy (newArg, 0, 3) = 'cmp' then
                                     begin
                                        Form1.setMistake ('Zeile ' + Form1.getLineNumber + ': Der Name eines Sprungpunktes darf nicht mit cmp anfangen.');
                                     end else
                                         begin
                                            Form1.setAssemblerText ('jmp ' + newArg);
                                         end;
                              end;
end;

//////////////////////////////////////////////////////////////////////////////////
////////////////////////////////GENERAL FUNCTIONS/////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

function TCommand.getTextInString (i: string) : string;
var textAccum   : string  = '';
var counter     : integer = 0;
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

procedure TCommand.handleInputAsm ();
var varName : string;
var counter : integer = 0;
begin
     varName := getTextWOBrackets (m_args);
    if varDoesExist(varName) then
        begin
           if varTable [getVarIndex (varName), 2] = 'zahl' then //Integer-types
               begin
                  Form1.setAssemblerText('mov eax, 3');
                  Form1.setAssemblerText('mov ebx, 1');
                  Form1.setAssemblerText('mov ecx, ' + varName);
                  Form1.setAssemblerText('mov edx, 9');
                  Form1.setAssemblerText('int 80h'); //calls the Kernel
                  Form1.setAssemblerText('mov eax, ' + varName); //moves the Pointer of varname into eax, which serves to pass an arguement
                  Form1.setAssemblerText('call cmp_sorting');
                  Form1.setAssemblerText('mov [' + varName + '], eax');
               end else
                   begin
                        Form1.setAssemblerText('mov eax, 3');
                        Form1.setAssemblerText('mov ebx, 1');
                        Form1.setAssemblerText('mov ecx, ' + varName);
                        Form1.setAssemblerText('mov edx, 255');
                        Form1.setAssemblerText('int 80h'); //calls the Kernel
                   end;
        end;
end;

function TCommand.getTextWOBrackets (i: string) : string; //get the Tex5 inside Brackets (Mainly, because m_args delivers the Brackets)
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
        end;
    if m_fullLine = 'ende' then //begin...end section (end)
        begin
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
      lengthOfStack := length (indentStack);
      needBegin     := false;
      setLength (indentStack, lengthOfStack);
      if functionIn = 'haupt' then
          begin
              indentStack[lengthOfStack, 1] := 'haupt';
              indentStack[lengthOfStack, 2] := Form1.getLineNumber(); //As the array is a String...
          end;
end;

procedure TCommand.handlePrototype ();
var proto: string;
begin
     if protoAllow then
         begin
            proto := getTextWOBrackets(proto);  //gets the prototype without the surrounding brackets
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

function TCommand.noProtoUnsolved () : boolean;
var counter  : integer = 0;
var lengthOf : integer = 0;
begin
  lengthOf := length (prototypes) -1;
     if prototypes = nil then
       begin
          noProtoUnsolved := true; //if the array is empty, there obviously can't be a protoype already called like this
       end else
           begin
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

function TCommand.getProtoIndex (i: string) : integer;
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
  mainSet   := true;
  needBegin := true;
end;

{$R *.lfm}

end.

