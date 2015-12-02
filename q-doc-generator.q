// q-doc Code Documentation Generator
//  JSON Generator
// Copyright (C) 2014 Jaskirat M.S. Rajasansir
// License BSD, see LICENSE for details

/ Gets all the files that have been parsed by the q-doc system and the number of documented entries per file
/  @returns (Dict) Single key dictionary 'files' with a table of files and documented entries
.qdoc.json.getFileList:{
    files:distinct value .qdoc.parseTree.source;
    funcCount:{ count where .qdoc.parseTree.source~\:x } each files;

    :enlist[`files]!enlist { `file`funcCount!(x;y) }./:flip (files;funcCount);
 };

/ Gets the parse tree for the specified file returned in a format ready for converting to JSON.
/  @param file (FilePath) The path of the file to get the parse tree for
/  @returns (Dict) Single key dictionary 'qdoc' with a table with each row a documented entry
/  @see .qdoc.json.error
.qdoc.json.getQDocFor:{[file]
    if[10h~type file;
        file:hsym `symbol$file;
    ];

    if[not file in distinct value .qdoc.parseTree.source;
        .log.error "Invalid file specified [ File: ",string[file]," ]";
        :.qdoc.json.error[;enlist[`file]!enlist file] "Invalid file specified";
    ];

    funcs:where .qdoc.parseTree.source~\:file;
    comments:funcs#.qdoc.parseTree.comments;
    tags:funcs#.qdoc.parseTree.tags;
    args:funcs#.qdoc.parseTree.arguments;

    doc:{[f;c;t;a]
        funcAndArgs:`func`arguments`comments!(f;a f;c f);
        docTags:(!).({`$1_/:key x};value)@\:t f;

        :funcAndArgs,docTags;

    }[;comments;tags;args] each funcs;

    :enlist[`qdoc]!enlist doc;
 };

/ Generates an error dictionary in case any parsing fails
/  @param msg (String) The error message
/  @param dict (Dict) Any related objects to help assist with debugging the issue
/  @returns (Dict) An error dictionary for conversion to JSON
.qdoc.json.error:{[msg;dict]
    if[all null dict;
        dict:()!();
    ];

    :dict,enlist[`ERROR]!enlist msg;
 };


/ for rst (restructured Text) generation

 .qdoc.rst.genFunc:{[dfunc]
    sign:".. q:method:: ",string[dfunc[`func]],"(",sv[", ";string[dfunc[`arguments]]],")";
    descp:dfunc[`comments];
    params:raze {(":param " ,string[x[`name]], ": ",x[`description];":type ",string[x[`name]], ": ",sv[" or ";string[x[`types]]])} each dfunc[`param];
    dreturn:dfunc[`returns];
    return: $[count[dreturn[`description]];":return: ",dreturn[`description];""];
    return_type: $[count[return];":retype: ", $[not null t:first[dreturn[`types]]; string[t]; "any"];""];
    :(sign;"\n"),("\t| ",/:descp),enlist["\n"],("\t",/:params),("\t",return;"\t",return_type;"\n");
    / rst_reserved_chars:"`\"";
    / output:last {ssr[x;y;"\\",y]} \ [output;rst_reserved_chars];
    :output;
    };

.qdoc.rst.genVar:{[dvar]
    sign:".. q:attribute:: ",string[dvar[`variable]];
    descp:dvar[`comments];
    :(sign;"\n"),("\t| ",/:descp),enlist["\n"];
    };

.qdoc.rst.genFile:{[file; includePrivate]
    t: .qdoc.json.getQDocFor[file];
    res: .qdoc.rst.genFunc each t[`qdoc] where includePrivate or not d[`qdoc;`func] like "f.p.*";
    res,: .qdoc.rst.genVar each t[`vars];
    :"" sv res;
    };

.qdoc.rst.writeFile:{[docRoot; includePrivate; file]
    res: 1 _ string[file], "\n,",#[1+count[string[file]];"="],"\n\n";

    res,:.qdoc.rst.genFile[file; includePrivate];
    docFile: hsym `$docRoot,"/", (-1 _ 1 _ string[file]),"rst";
    docFile 0: enlist[res];
    };

    / Gets the parse tree for the specified namespace returned in a format ready for converting to JSON.
    /  @param file (FilePath) The path of the file to get the parse tree for
    /  @returns (Dict) Single key dictionary 'qdoc' with a table with each row a documented entry
    /  @see .qdoc.json.error
    .qdoc.rst.getQDocFor:{[namespace]

        if[not namespace in distinct {`$".",vs[".";string[x]]@1} each key .qdoc.parseTree.source;
            .log.error "Invalid namespace specified [ Namespace: ",string[namespace]," ]";
            :.qdoc.json.error[;enlist[`namespace]!enlist namespace] "Invalid namespace specified";
        ];

        funcs:key[.qdoc.parseTree.source] where namespace={`$".",vs[".";string[x]]@1} each key .qdoc.parseTree.source;
        comments:funcs#.qdoc.parseTree.comments;
        tags:funcs#.qdoc.parseTree.tags;
        args:funcs#.qdoc.parseTree.arguments;
        nvars: key[.qdoc.parseTree.variables] where namespace={`$".",vs[".";string[x]]@1} each key .qdoc.parseTree.variables;
        vars: nvars # .qdoc.parseTree.variables;
        vars: ([] variable:key[vars];comments:value[vars]);

        doc:{[f;c;t;a]
            funcAndArgs:`func`arguments`comments!(f;a f;c f);
            docTags:(!).({`$1_/:key x};value)@\:t f;

            :funcAndArgs,docTags;

        }[;comments;tags;args] each funcs;

        :`qdoc`vars!(doc;vars);
     };

.qdoc.rst.genNamespace:{[namespace; includePrivate]
    t: .qdoc.rst.getQDocFor[namespace];
    funcs: .qdoc.rst.genFunc each t[`qdoc] where includePrivate or not t[`qdoc;`func] like "*f.p.*";
    vars: .qdoc.rst.genVar each t[`vars];
    :funcs, vars;
    };

.qdoc.rst.writeNamespace:{[docRoot; includePrivate; namespace]
    ns_label: $[count[label:.qdoc.rst.namespaces[namespace]];label, " (",string[namespace],")";string[namespace]];
    res: ns_label, "\n", #[count[ns_label];"="],"\n\n";
    res,: ".. q:namespace:: ",string[namespace],"\n\n";
    res,: raze "\n\t" ,/:raze .qdoc.rst.genNamespace[namespace; includePrivate];
    docFile: hsym `$docRoot,"/", (1 _ string[namespace]),".rst";
    docFile 0: enlist[res];
    };

.qdoc.rst.writeDoc:{[docRoot;includePrivate]
    namespaces: distinct {`$".",vs[".";string[x]]@1} each key .qdoc.parseTree.source;
    .qdoc.rst.writeNamespace [docRoot;includePrivate] each namespaces;

    / files:distinct value .qdoc.parseTree.source;
    / .qdoc.rst.writeFile [docRoot;includePrivate] each files;
    };
