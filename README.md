#GerCompiler - A simple, german, lightweigth Linux-Compiler
--Made as extension to GerInterpreter (www.sites.google.com/site/gerinterpreter) </br>
--GerInterpreter has more Commands, use it as long, as my Project isn't finished :)</br>

SETUP: To compile the sources, you'll need Lazarus-Pascal (www.lazarus-ide.org).</br>

If you directly want to start the Compiler, use the StartCompiler.sh script, which sets-up everything nicely.</br>
PLEASE, DON'T upload Files, as this is a Project I want to drive by my own (until my Project is done)

#Possible Commands:
</br>
</br>         
//These types of comments are legal</br>
//The compiler (shouldnt) be case-sensitive </br>
schreiben ("Text") //This writes the Text given in " </br>
schreiben (nzeile) //This writes a new Line </br>
schreiben (varname) //writes the variable </br>
schreiben ("Text" + varname) //You can concatenate strings </br>
//You can concatenate as many arguements, as you want and eny type of arguements. </br>
schreiben ("Text" + "Text" + nzeile + "Text" + varname + "HELLO WORLD :)" + nzeile)

neuevariable (var1 = "HI") //creates a new string-variable with the Value of HI. Strings arent allowed </br>
//to be longer than 255 Character </br>
neuvariable (var2 = 42) //Creates a new Integer-Variable with the Answer to life (42) </br>
//Integers arent allowed to be longer than 9 chars.</br>
//Note, that Integer-variables aren't writeable due to a Unicode-glitch </br>
 </br>
punktsetzen (punkt1) //sets a goto-Label </br>
gehezu (punkt1) //goto </br> 
 </br>
 </br>
         
 eingeben (varname) //Inputs into the variable. </br>

 
The executable is in the same folder, as your source-code. Run it in the Terminal with ./programm


Please give me some Feedback, but don't post direct Answers to my Questions, </br>as I prefer working alone at this school Project </br> (I'm in the 8th school-year)
 </br>
HAVE FUN USING IT!
