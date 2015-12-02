
//   Parser
// Copyright (C) 2014 Jaskirat M.S. Rajasansir
// License BSD, see LICENSE for details


/ Stores the q-doc comment body (i.e. the lines that have not been parsed by a tag function).
/ The dictionary key is the function name and the value the list of lines that form the comment
/ body.
/  @see .qdoc.parser.parse
.qdoc.parseTree.comments:(!)."S*"$\:();

/ Stores the parsed tags for all functions and variables that have been successfully parsed by
/ the q-doc parser. This dictionary is keyed by function name. The value varies depending
/ on the tag that has been parsed
/  @see .qdoc.parser.tags
/  @see .qdoc.parser.parse
.qdoc.parseTree.tags:(!)."S*"$\:();

/ Stores a mapping of function name and the file that it was parsed from
.qdoc.parseTree.source:(!)."SS"$\:();

/ Stores the namespace associated with the file if relevant
.qdoc.parseTree.namespace:`;

/ Stores function arguments, keyed by the function name
.qdoc.parseTree.arguments:(!)."S*"$\:();

/ Stores the folder root where the q-doc parsing started from
.qdoc.parseTree.root:`;

/ Stores the variables and their comments
.qdoc.parseTree.variables:(!)."S*"$\:();

/ Defines the supported tags to be parsed. The dictionary key is the string that should
/ be identified from the file and the value is the function that should be executed on
/ lines that match.
/ NOTE: Tag comments must reside on the the same line as the tag
.qdoc.parser.tags:()!();
.qdoc.parser.tags[enlist"@param"]:`.qdoc.parser.tag.param;
.qdoc.parser.tags[enlist"@returns"]:`.qdoc.parser.tag.returns;
.qdoc.parser.tags[enlist"@global"]:`.qdoc.parser.tag.global;
.qdoc.parser.tags[enlist"@throws"]:`.qdoc.parser.tag.throws;
.qdoc.parser.tags[enlist"@see"]:`.qdoc.parser.tag.see;


/ Generates the parse trees for all .q and .k files recursively from the specified folder root.
/  @param folderRoot Folder The root folder to parse all .q and .k files recursively from
/  @throws FolderDoesNotExistException If the specified folder does not exist
/  @see .util.isFolder
/  @see .qdoc.parser.parse
.qdoc.parser.init:{[folderRoot]
    if[not .util.isFolder folderRoot;
        .log.error "Folder does not exist! [ Folder: ",string[folderRoot]," ]";
        '"FolderDoesNotExistException (",string[folderRoot],")";
    ];
    .qdoc.parseTree.root:folderRoot;

    files:.util.tree folderRoot;
    files@:where any files like/:enlist["*.q"];
    files:hsym each `symbol$files;

    .qdoc.parser.parse each files;

    / Post-processing, make file names relative to folder root for better UI display
    .qdoc.parseTree.source:hsym each `$ssr[;,[;"/"] string folderRoot;""] each string .qdoc.parseTree.source;
 };

/ Generates the parse tree for the specified file.
/  @param fileName File The file to parse for q-doc
/  @returns Boolean True if the parse was successful
/  @see .qdoc.parseTree.parseTags
/  @see .qdoc.parser.postProcess
.qdoc.parser.parse:{[fileName]
    .log.info "Generating q-doc parse tree for: ",string fileName;

    file:read0 fileName;

    init_lines:();
    beg_init: first where count each  {r:x ss "f.p.init:"} each file;
    if [    not null beg_init;
            end_init: first where not in [;(" ";"\t")] first each (1+beg_init) _ file;   / allows indentation by tab or by spaces
            init_lines: end_init # (1 +beg_init) _ file;
            init_lines:({trim $[first[x] in ("\t";" ");1 _ x;x]}/) each init_lines; / trim removes spaces in case of indentation by spaces
            init_lines@: where or[not in [;("}";"/";"\\";" ")] first each init_lines;"/ *"~/: 3#'init_lines];
            init_lines:?["/ *"~/:3#'init_lines;1 _'init_lines;init_lines];
        ];

    file@:where or[not in [;(" ";"\t";"}";"/";"\\")] first each file;in[;(" * ";"/ *";"\\d ")] 3#'file];
    if[count file;file:?["/ *"~/:3#'file;1 _'file;file]];

    file: init_lines, file;

    if[0=count[file];:1b];

    posAndNs:enlist[-1]!enlist[`.];    / functions declared before a \d belongs to the global namespace
    posAndNs,: (where in[;enlist["\\d "]] 3#' file)!(`$3 _' file where in[;enlist["\\d "]] 3#' file);
    / see if we can use functions from parser.q and file.q to remove blanks, makes it more general
    funcSignatures:file where and[or[like[;"*:{*"] each file;like[;"*: {*"] each file];not in[;enlist" * "] 3#' file];
    trimFuncSignatures:{$[x like "*{[[]*";first[ss[x;"]"]]#x;first[ss[x;"{"]]#x]} each funcSignatures;  / trim the function signatures after the arguments to allow one-line functions

    funcAndArgs:{ $[not["{["~2#x] and x like "*{[[]*"; :enlist`; :`$";" vs x where not any x in/:"{[]} "] } each (!). flip ({`$first x};last)@\:/:":" vs/:trimFuncSignatures;


    posAndFunc:(where in[;funcSignatures] each file)!key[funcAndArgs];
    posAndFunc: key[posAndFunc]!{ns:x@asc[key[x]]@last[where[z>asc[key[x]]]];$[(y[z] like ".z_*") or ns~`.;y[z];`$string[ns],".",string[y[z]]]} [posAndNs; posAndFunc] each key posAndFunc;  / prepend namespace as appropriate

    funcAndArgs:value[posAndFunc]!value[funcAndArgs];   / change functions to fullname

    varSignatures:(file where and[and[not like[;"*::*"] each file;or[like[;"*:*"] each file;like[;"*: *"] each file]];not in[;enlist" * "] 3#' file]) except funcSignatures;
    trimVarSignatures:{`$first[ss[x;":"]]#x} each varSignatures;  / trim the function signatures after the arguments to allow one-line functions

    if [    count varSignatures;
            posAndVar:(where in[;varSignatures] each file)!trimVarSignatures;
            posAndVar: key[posAndVar]!{ns:x@asc[key[x]]@last[where[z>asc[key[x]]]];$[(y[z] like ".z_*") or ns~`.;y[z];`$string[ns],".",string[y[z]]]} [posAndNs; posAndVar] each key posAndVar;  / prepend namespace as appropriate
    ];

    commentLines:(asc file?union[varSignatures;funcSignatures]) - til each deltas asc file?union[varSignatures;funcSignatures];
    commentLines:{y where "*"~/:first each trim each x@y} [file] each commentLines;
    if["*"~first trim first file; commentLines:@[commentLines;0;,;0]];    / deltas stops at 1 so first line of file gets ignored. If its a comment, manually add to list
    dCommentLines:({1+first x}each commentLines)! reverse each commentLines;


    funcCommentsDict:value[posAndFunc]! trim file dCommentLines each key posAndFunc;
    funcCommentsDict: trim 1_/:/: funcCommentsDict;

    tagDiscovery:{ key[.qdoc.parser.tags]!where each like[x;]@/:"*",/:key[.qdoc.parser.tags],\:"*" } each funcCommentsDict;
    tagComments:funcCommentsDict@'tagDiscovery;
    comments:funcCommentsDict@'(til each count each funcCommentsDict) except' raze each tagDiscovery;
    comments:comments@'where each not "/"~/:/:first@/:/:comments;

    / Key of funcAndArgs / comments / tagComments are equal and must remain equal
    keysToRemove:.qdoc.parser.postProcess[funcAndArgs;comments;tagComments];

    if[not .util.isEmpty keysToRemove;
        .log.info "Documented objects to be ignored: ",.Q.s1 keysToRemove;

        funcAndArgs:keysToRemove _ funcAndArgs;
        comments:keysToRemove _ comments;
        tagComments:keysToRemove _ tagComments;
    ];

    tagParseTree:raze .qdoc.parser.parseTags[;tagComments] each key tagComments;

    variables:()!();
    if[count posAndVar;
        varCommentsDict:value[posAndVar]! trim file dCommentLines each key posAndVar;
        variables: 1_/:/: varCommentsDict;   / remove the * at the beginning of the lines
        ];

    .qdoc.parseTree.comments,:comments;
    .qdoc.parseTree.tags,:tagParseTree;
    .qdoc.parseTree.source,:key[funcAndArgs]!count[funcAndArgs]#fileName;
    .qdoc.parseTree.arguments,:funcAndArgs;
    .qdoc.parseTree.variables,:variables;

    :1b;
 };


/ Extracts and parses the supported tags from the q-doc body.
/  @param func Symbol The function name the documentation is currently being parsed for
/  @param tagsAndComments Dict The dictionary of function name and comments split by tag name
.qdoc.parser.parseTags:{[func;tagsAndComments]
    parseDict:key[.qdoc.parser.tags]!(count[.qdoc.parser.tags]#"*")$\:();

    funcComments:tagsAndComments func;

    parsed:{
        tagFunc:get .qdoc.parser.tags x;
        :tagFunc[z;y x];
    }[;funcComments;func] each key .qdoc.parser.tags;

    :enlist[func]!enlist key[parseDict]!parsed;
 };

/ Performs post-processing on the generated function and arguments, comments and
/ parsed tags as appropriate.
/ Currently this function removes documented objects with any function to the left of the assigment
/ and removes additions to dictionaries if there are no comments associated with them.
/  @param funcAndArgs (Dict) Functions with argument list
/  @param comments (Dict) Functions with description
/  @param tagComments (Dict) Functions with tag parsing
/  @returns (SymbolList) Functions that should be removed from the parsed results
.qdoc.parser.postProcess:{[funcAndArgs;comments;tagComments]
    / Remove documented objects with any function to the left of the assignment
    assignmentInFunc:key[funcAndArgs] where any each any each string[key funcAndArgs] in/:\:",@:";  / removed the _ because it didn't allow snake format for function names

    / Remove additions to dictionaries if no comments
    dictKeysNoComments:{ $[(any any string[x] in/:\:"[]") & (()~y); :x; :` ] }./:flip (key;value)@\:comments;
    dictKeysNoComments@:where not null dictKeysNoComments;

    :distinct (,/)(assignmentInFunc;dictKeysNoComments);
 };


.qdoc.parser.tag.param:{[func;params]
    pDict:flip `name`types`description!"S**"$\:();

    if[()~params;
        :pDict;
    ];

    paramTrimmed:{x where not (x=" ") and (prev[x] in " ")} each params;
    paramSplit:1_/:" " vs/:paramTrimmed;
    paramNames:"S"$paramSplit@\:1;
    paramDescs:" " sv/:2_/:paramSplit;

    paramTypes:-1 _/: 1 _/: paramSplit@\:0;
    paramTypes:.qdoc.parser.typeParser[func;] each paramTypes;

    :pDict upsert flip (paramNames;paramTypes;paramDescs);
 };

.qdoc.parser.tag.returns:{[func;return]
    rDict:`types`description!"H*"$\:();

    if[()~return;
        :rDict;
    ];

    returnTrimmed:{x where not (x=" ") and (prev[x] in " ")} first return;
    returnSplit:1_" " vs returnTrimmed;

    :key[rDict]!(.qdoc.parser.typeParser[func;-1 _ 1 _ returnSplit 0];" " sv 1 _ returnSplit);
 };

 .qdoc.parser.tag.global:{[func;globals]
   pDict:flip `name`types`description!"S**"$\:();

    if[()~globals;
        :pDict;
    ];

    globalTrimmed:{x where not (x=" ") and (prev[x] in " ")} each globals;
    globalSplit:1_/:" " vs/:globalTrimmed;
    globalNames:"S"$globalSplit@\:1;
    globalDescs:" " sv/:2_/:globalSplit;

    globalTypes:-1 _/: 1 _/: globalSplit@\:0;
    globalTypes:.qdoc.parser.typeParser[func;] each globalTypes;

    :pDict upsert flip (globalNames;globalTypes;globalDescs);
 };


.qdoc.parser.tag.throws:{[func;throws]
    tDict:flip `exception`description!"S*"$\:();

    if[()~throws;
        :tDict;
    ];

    throwsSplit:1_/:" " vs/:throws;
    exceptions:"S"$throwsSplit@\:0;
    exceptionsDesc:" " sv/:1_/:throwsSplit;

    :tDict upsert flip (exceptions;exceptionsDesc);
 };

.qdoc.parser.tag.see:{[func;sees]
    if[()~sees;
        :enlist`;
    ];

    :"S"$first each 1_/:" " vs/:sees;
 };

.qdoc.parser.typeParser:{[func;types]
    types:lower "S"$"|" vs types where not any types in/:"()";

    if[not all types in lower key .qdoc.parser.types.input;
        .log.warn "Unrecognised data type [ Function: ",string[func]," ] [ Unrecognised Types: ",.Q.s1[types except key .qdoc.parser.types]," ]";
    ];

    / :.qdoc.parser.types.output .qdoc.parser.types.input types;
    :types;
 };


