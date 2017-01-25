#GerCompiler - A simple, german, lightweigth Linux-Compiler
--Made as extension to GerInterpreter (www.sites.google.com/site/gerinterpreter) </br>
--GerInterpreter has more Functions, use it as long, as my Project isn't finished :)</br>

SETUP: To compile the sources, you will need Lazarus-Pascal (www.lazarus-ide.org).</br>

To directly use the executable, use the script, or run

    
    sudo chmod +x /Compiler
    sudo ./Compiler

Please give me some Feedback, but don't post direct Answers to my Questions, </br>as I prefer working alone at this school Project </br>
 </br>
HAVE FUN USING IT!

Little explanantion: 

to start, we need a main-function.
```
haupt
anfang

ende
```

Inside of this, we can use many commands...
Example: ```schreiben ``` </br>
This command writes to the terminal.

We use it like this: 
```
schreiben ("HELLO" + " " + "World" + nZeile)
```

You can concatenate as many strings, escape-sequences (nZeile) or Variables as needed...
```
nZeile
```
appends a new Line to the written Text.


To add a new Variable, we need to do so before the first function has been created.

```
neuevariable (Hallo = "HELLO") //Adds a new Variable //The compiler recognizes the type of Variable
//strings need to be encapsulated in Quotes


haupt //The main-function
anfang
    schreiben (Hallo + nzeile)
    Hallo =+1 //Is round about the same as the ++ operator in C++
    schreiben (Hallo + nZeile)
ende
```
If we want the user to be able to input a value for the Variable, we can do this...
```
neuevariable (Hallo = 123) //This time, we create a Number-variable. 

haupt
anfang
    schreiben (Hallo + nZeile)
    eingeben (Hallo)
    schreiben (Hallo + nZeile)    
ende
```

This inputs the variable; It also pays attention, the user didn't input anything wrong like  

→Too long numbers (in case of Numbers)
→Characters (in case of Numbers) 

Now, by that, we can create a new Function.
```
prototyp (writeHello) //Creates the function-prototype

haupt
anfang //This is the same as the begin...end indentation-block in Pascal... In c++ it would be {...}
    aufrufen (writeHello)
ende

leer writeHello
anfang
schreiben ("Hello World" + nZeile)
ende
```
This creates a function. To call the function, we use the command ```aufrufen```

Inside of functions, we can also do comparisons...
```
prototyp (test)
neuevariable (var1 = "3") //comparisons with Numbers need to be tested...

leer test
anfang
    wenn var1 == "3"
    anfang
       schreiben (Hello ;-))
    ende
ende

haupt
anfang
   aufrufen (test) //it should write 'Hello', because var 1 equals to "1"
ende
```

You can compare almost everytype of Variables, but can't concatenate...
Theres also a goto() function.
```
haupt
anfang
    punktsetzen (s1) //places the goto-point
    schreiben ("HI" + nZeile)
    gehezu (s1) //goes to s1... It will write infinitely HI
ende
```
