;;
;; AST inferred from the parser and slightly edited
;;

(def:ast verilog0 ()
   (verilog  <*description:ds>)
   (description  (|
       (primitive <nameOfUDP:nm> <*nameOfVariable:args> <*UDPDeclaration:ds> <*UDPInitialStatement:init> <tableDefinition:td>)
       (macromodule <moduleident:nm> <*ports:ports> <*moduleItem:body>)
       (module <moduleident:nm> <*ports:ports> <*moduleItem:body>)
   ))
   (ports <*port:ps>)
   (UDPDeclaration  (|
       (input <*range:r> <*nameOfVariable:l>)
       (reg <*range:r> . <*registerVariable:rs>)
       (output <*range:r> <*nameOfVariable:l>)
   ))
   (UDPInitialStatement  (|
       (initial <outputTerminalName:l> <initVal:r>)
   ))
   (tableDefinition  (|
       (combtable . <*combinationalEntry:es>)
       (seqtable . <*sequentialEntry:es>)
   ))
   (moduleItem  (|
       (vfunction <*rangeOrType:tp> <nameOfFunction:nm> <*tfDeclaration:tfs> <statement:st>)
       (task <nameOfTask:nm> <*tfDeclaration:tfs> <statement:st>)
       (always <statement:s>)
       (initial <statement:s>)
       (specify . <*specifyItem:ss>)
       (assignnt <nettype:nt> <*driveStrength:ds> <*expandrange:e> <*delay:d> <*assignment:as>)
       (assign <*driveStrength:ds> <*delay:d> <*assignment:as>)
       (defparam . <listOfParamAssignments:pas>)
       (moduleinst <nameOfModule:nm> <*parameterValueAssignment:va> . <*moduleInstance:is>)
       (udpinst <nameOfUDP:nm> <*driveStrength:ds> <*delay:d> . <*UDPInstance:is>)
       (gate <gatetype:gt> <*driveStrength:ds> <*delay:d> . <*gateInstance:gs>)
       (event . <*nameOfEvent:es>)
       (real . <*nameOfVariable:rs>)
       (integer . <*registerVariable:rs>)
       (time . <*registerVariable:rs>)
       (reg <*range:r> . <*registerVariable:rs>)
       (net <nettype:nt> <*expandrange:r> <*delay:d> <*nameOfVariable:l>)
       (netas <nettype:nt> <*driveStrength:ds> <*expandrange:er> <*delay:d> <*assignment:as>)
       (trireg <*chargeStrength:s> <*expandrange:er> <delay:d>)
       (inout <*range:r> <*nameOfVariable:l>)
       (output <*range:r> <*nameOfVariable:l>)
       (input <*range:r> <*nameOfVariable:l>)
       (parameter . <*parameterAssignment:as>)
   ))
   (range  (|
       (r <constantExpression:l> <constantExpression:r>)
   ))
   (registerVariable  (|
       (reg <nameOfRegister:nm>)
       (mem <nameOfMemory:nm> <constantExpression:l> <constantExpression:r>)
   ))
   (combinationalEntry  (|
       (ce <levelInputList:l> <OutputSymbol:s>)
   ))
   (sequentialEntry  (|
       (se <inputList:l> <state:s> <nextState:ns>)
   ))
   (port  (|
       (pref1 <ident:id>)
       (pref2 <ident:id> <constantExpression:e>)
       (pref3 <ident:id> <constantExpression:e1> <constantExpression:e2>)
       (begin . <*port:rs>)
       (named <nameOfPort:nm> <port:e>)
       (inout <*range:r> <*nameOfVariable:l>)
       (output <*range:r> <*nameOfVariable:l>)
       (input <*range:r> <*nameOfVariable:l>)
   ))
   (rangeOrType  (|
       (real)
       (integer)
   ))
   (tfDeclaration  (|
       (real . <*nameOfVariable:rs>)
       (integer . <*registerVariable:rs>)
       (time . <*registerVariable:rs>)
       (reg <*range:r> . <*registerVariable:rs>)
       (output <*range:r> <*nameOfVariable:l>)
       (input <*range:r> <*nameOfVariable:l>)
       (parameter . <*parameterAssignment:as>)
   ))
   (statement  (|
       (null)
       (release <lvalue:l>)
       (force <assignment:a>)
       (deassign <lvalue:l>)
       (assign <assignment:a>)
       (bdisable <nameOfBlock:b>)
       (tdisable <nameOfTask:t>)
       (systask <nameOfSystemTask:nm> . <*expression:es>)
       (task <nameOfTask:nm> . <*expression:es>)
       (forknm <nameOfBlock:nm> <*blockDeclaration:ds> . <*statement:ss>)
       (fork . <*statement:ss>)
       (beginnm <nameOfBlock:nm> <*blockDeclaration:ds> . <*statement:ss>)
       (begin . <*statement:ss>)
       (eto <nameOfEvent:n>)
       (wait <expression:e> <statement:s>)
       (de <delayOrEventControl:evc> <statement:s>)
       (for <assignment:a1> <expression:e> <assignment:a2> <statement:s>)
       (while <expression:e> <statement:s>)
       (repeat <expression:e> <statement:s>)
       (forever <statement:s>)
       (casex <expression:e> . <*caseItem:es>)
       (casez <expression:e> . <*caseItem:es>)
       (case <expression:e> . <*caseItem:es>)
       (if2 <expression:cnd> <statement:tr>)
       (if3 <expression:cnd> <statement:tr> <statement:fl>)
       (nonblocking <lvalue:l> <expression:r>)
       (nonblocking_de <delayOrEventControl:evc> <lvalue:l> <expression:r>)
       (blocking <lvalue:l> <expression:r>)
       (blocking_de <delayOrEventControl:evc> <lvalue:l> <expression:r>)
   ))
   (specifyItem  (|
       (sdpdif <sdpdConditionalExpression:e> <pathDescription:l> <pathDelayValue:r>)
       (hold <timingCheckEvent:e1> <timingCheckEvent:e2> <timingCheckLimit:l1> <*notifyRegister:r>)
       (setup <timingCheckEvent:e1> <timingCheckEvent:e2> <timingCheckLimit:l1> <*notifyRegister:r>)
       (espdl <*expression:cnd> <*edgeIdentifier:ei> <specifyInputTerminalDescriptor:l> 
              <*specifyOutputTerminalDescriptor:r> <*polarityOperator:op> <dataSourceExpression:ds> 
              <pathDelayValue:v>)
       (espd <*expression:cnd> <*edgeIdentifier:ei> <specifyInputTerminalDescriptor:l> 
             <specifyOutputTerminalDescriptor:r> <*polarityOperator:op> <dataSourceExpression:ds> <pathDelayValue:v>)
       (ifpdl <conditionalPortExpression:cnd> <*specifyInputTerminalDescriptor:l> <*polarityOperator:p> 
              <*specifyOutputTerminalDescriptor:r> <pathDelayValue:v>)
       (ifpd <conditionalPortExpression:cnd> <specifyInputTerminalDescriptor:l> <*polarityOperator:p> 
             <specifyOutputTerminalDescriptor:r> <pathDelayValue:v>)
       (pathdecl <pathDescription:l> <pathDelayValue:r>)
       (specparam . <*paramAssignment:as>)
   ))
   (driveStrength  (|
       (s10 <strength1:l> <strength0:r>)
       (s01 <strength0:l> <strength1:r>)
   ))
   (expandrange  (|
       (range <range:r>)
       (scalared <range:r>)
       (vectored <range:r>)
   ))
   (delay  (|
       (ehash . <*expression:es>)
       (nhash <ident:id>)
       (hash <number:n>)
       (delay3 <expression:e1> <expression:e2> <expression:e3>)
       (delay2 <expression:e1> <expression:e2>)
       (delay1 <expression:e1>)
       (delay1i <ident:i>)
       (delay1n <number:n>)
   ))
   (assignment  (|
       (a <lvalue:l> <expression:r>)
   ))
   (parameterValueAssignment  (|
       (va . <listOfModuleConnections:cs>)
   ))
   (moduleInstance  (|
       (mod <nameOfInstance:nm> . <listOfModuleConnections:cs>)
   ))
   (UDPInstance  (|
       (is <*nameOfUDPInstance:nm> . <*terminal:ts>)
   ))
   (gateInstance  (|
       (gate <*nameOfGateInstance:nm> . <*terminal:ts>)
   ))
   (parameterAssignment  (|
       (ass <ident:l> <constantExpression:r>)
   ))
   (constantExpression  (|
       (constexpr <expression:e>)
   ))
   (levelInputList  (|
       (levell <*LevelSymbol:ss>)
   ))
   (inputList  (|
       (edgel <*LevelSymbol:lsl> <edge:e> <*LevelSymbol:lsr>)
       (levell <*LevelSymbol:ss>)
   ))
   (nextState  (|
       (hyphen)
       (s <OutputSymbol:s>)
   ))
   (lvalue  (|
       (var <ident:nm>)
       (idx <ident:nm> <constantExpression:l>)
       (idx2 <ident:nm> <constantExpression:l> <constantExpression:r>)
       (concatenation . <*expression:es>)
   ))
   (expression  (|
       (negedge <scalarEventExpression:r>)
       (posedge <scalarEventExpression:e>)
       (or <expression:l> <expression:r>)

       (nop)
       (number <number:n>)
       (var <ident:nm>)
       (mintypmax <expression:e1> <expression:e2> <expression:e3>)
       (fsyscall <nameOfSystemFunction:nm> . <*expression:args>)
       (fcall <nameOfFunction:nm> . <*expression:args>)
       (concatenation . <*expression:es>)
       (multipleconcatenation <expression:e> <expression:c>)
       (idx <ident:nm> <constantExpression:l>)
       (idx2 <ident:nm> <constantExpression:l> <constantExpression:r>)
       (string <string:s>)
       (unop <unaryOperator:op> <expression:p>)
       (binop <BinaryOperator:op> <expression:l> <expression:r>)
       (ternary <expression:c> <expression:l> <expression:r>)
   ))
   (blockDeclaration  (|
       (event . <*nameOfEvent:es>)
       (time . <*registerVariable:rs>)
       (real . <*nameOfVariable:rs>)
       (integer . <*registerVariable:rs>)
       (reg <*range:r> . <*registerVariable:rs>)
       (parameter . <*parameterAssignment:as>)
   ))
   (delayOrEventControl  (|
       (repeat <expression:e> <eventControl:c>)
       (ate <expression:e>)
       (at <ident:nm>)
       (ehash <expression:e>)
       (nhash <ident:id>)
       (hash <number:n>)
   ))
   (caseItem  (|
       (default <statement:s>)
       (case <*expression:es> <statement:s>)
   ))
   (sdpdConditionalExpression  (|
       (binop <BinaryOperator:op> <expression:l> <expression:r>)
       (unop <unaryOperator:op> <expression:e>)
   ))
   (pathDescription  (|
       (pathdescs <*specifyInputTerminalDescriptor:is> <*specifyOutputTerminalDescriptor:os>)
       (pathdesc <specifyInputTerminalDescriptor:l> <specifyOutputTerminalDescriptor:r>)
   ))
   (pathDelayValue  (|
       (delay <pathDelayExpression:e>)
       (delays . <*pathDelayExpression:des>)
   ))
   (timingCheckEvent  (|
       (ce <*timingCheckEventControl:c> <specifyTerminalDescriptor:d> <*timingCheckCondition:nd>)
   ))
   (edgeIdentifier  (|
       (negedge)
       (posedge)
   ))
   (specifyInputTerminalDescriptor  (|
       (itd1 <inputIdentifier:nm>)
       (itd2 <inputIdentifier:nm> <constantExpression:l>)
       (itd3 <inputIdentifier:nm> <constantExpression:l> <constantExpression:r>)
   ))
   (conditionalPortExpression  (|
       (binop <BinaryOperator:op> <port:l> <port:r>)
       (unop <unaryOperator:op> <port:l>)
   ))
   (paramAssignment  (|
       (a <ident:l> <constantExpression:r>)
   ))
   (nameOfInstance  (|
       (i <ident:nm> <*range:r>)
   ))
   (listOfModuleConnections  (|
       (none)
       (pcs . <*modulePortConnection:pc>)
       (npcs . <*namedPortConnection:npc>)
   ))
   (nameOfUDPInstance  (|
       (i <ident:nm> <*range:r>)
   ))
   (terminal  (|
       (id <ident:nm>)
   ))
   (nameOfGateInstance  (|
       (i <ident:nm> <*range:r>)
   ))
   (edge  (|
       (e1 <EdgeSymbol:s>)
       (e2 <LevelSymbol:l> <LevelSymbol:r>)
   ))
   (eventControl  (|
       (ate <expression:e>)
       (at <ident:nm>)
   ))
   (timingCheckEventControl  (|
       (edge . <*edgeDescriptor:ds>)
       (negedge)
       (posedge)
   ))
   (timingCheckCondition  (|
       (binop <binop:op> <scalarExpression:l> <scalarConstant:r>)
       (unop <unop:op> <scalarExpression:e>)
       (scalarexpr <expression:e>)
   ))
   (modulePortConnection  (|
       (none)
       (e <expression:e>)
   ))
   (namedPortConnection  (|
       (n <ident:nm> <expression:e>)
       (nempty <ident:nm>)
   ))
   (scalarEventExpression  (|
       (scalareventexpr <expression:e>)
   ))
   (scalarExpression  (|
       (scalarexpr <expression:e>)
   ))
   (number <numliteral:v>)


   (localIdentifier <idToRename:id>)
   (ident <localIdentifier:id>) ; aliases for renaming
   (nameOfVariable <ident:id>)
   (nameOfFunction <ident:id>)
   (nameOfTask <ident:id>)
   (nameOfEvent <ident:id>)
   (nameOfRegister <ident:id>)
   (nameOfMemory <ident:id>)
   (nameOfPort <ident:id>)
   (nameOfBlock <ident:id>)
   (outputTerminalName <ident:id>)
)
