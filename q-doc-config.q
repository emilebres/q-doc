// q-doc Code Documentation Generator
//   Configuration
// Copyright (C) 2014 Jaskirat M.S. Rajasansir
// License BSD, see LICENSE for details


/ Defines the mapping between the supported types for q-doc and the underlying q types. All list
/ types are also defined by appending 'List' to each type. Further, some custom types have also
/ been defined with non-standard kdb type values.
/ NOTE: You should ignore the custom type values unless interested in writing your own q-doc generator.
/ NOTE 2: The types are currently case-sensitive.
.qdoc.parser.types.input:(!)."SH"$\:();
.qdoc.parser.types.input[`bool`boolean]:-1h;
.qdoc.parser.types.input[`guid]:-2h;
.qdoc.parser.types.input[`byte]:-4h;
.qdoc.parser.types.input[`short`shortint`int16]:-5h;
.qdoc.parser.types.input[`integer`int`int32]:-6h;
.qdoc.parser.types.input[`long`longint`int64]:-7h;
.qdoc.parser.types.input[`real`single]:-8h;
.qdoc.parser.types.input[`float`double]:-9h;
.qdoc.parser.types.input[`char`character]:-10h;
.qdoc.parser.types.input[`symbol`sym]:-11h;
.qdoc.parser.types.input[`timestamp]:-12h;
.qdoc.parser.types.input[`month]:-13h;
.qdoc.parser.types.input[`date]:-14h;
.qdoc.parser.types.input[`datetime]:-15h;
.qdoc.parser.types.input[`timespan]:-16h;
.qdoc.parser.types.input[`minute`min]:-17h;
.qdoc.parser.types.input[`second`sec]:-18h;
.qdoc.parser.types.input[`time]:-19h;

.qdoc.parser.types.input[`true]:-30h;
.qdoc.parser.types.input[`false]:-31h;
.qdoc.parser.types.input[`number]:-35h;
.qdoc.parser.types.input[`file]:-40h;
.qdoc.parser.types.input[`folder]:-41h;
.qdoc.parser.types.input[`filepath]:-42h;
.qdoc.parser.types.input[`folderpath]:-43h;
.qdoc.parser.types.input[`host]:-44h;
.qdoc.parser.types.input[`port]:-45h;
.qdoc.parser.types.input[`path]:-46h;
.qdoc.parser.types.input[`string]:-50h;

.qdoc.parser.types.input,:(!).({ `$string[x],"list" };abs)@/:'(key .qdoc.parser.types.input;value .qdoc.parser.types.input);

.qdoc.parser.types.input[``void]:0Nh;
.qdoc.parser.types.input[`atom]:-0Wh;
.qdoc.parser.types.input[`list]:0h;
.qdoc.parser.types.input[`table]:98h;
.qdoc.parser.types.input[`dict`dictionary]:99h;
.qdoc.parser.types.input[`function]:100h;


.qdoc.parser.types.output:(!)."HS"$\:();
.qdoc.parser.types.output[-1h]:`Boolean;
.qdoc.parser.types.output[-2h]:`GUID;
.qdoc.parser.types.output[-4h]:`Byte;
.qdoc.parser.types.output[-5h]:`$"16-bit Integer";
.qdoc.parser.types.output[-6h]:`$"32-bit Integer";
.qdoc.parser.types.output[-7h]:`$"64-bit Integer";
.qdoc.parser.types.output[-8h]:`$"Single precision floating point";
.qdoc.parser.types.output[-9h]:`$"Double precision floating point";
.qdoc.parser.types.output[-10h]:`Character;
.qdoc.parser.types.output[-11h]:`Symbol;
.qdoc.parser.types.output[-12h]:`Timestamp;
.qdoc.parser.types.output[-13h]:`Month;
.qdoc.parser.types.output[-14h]:`Date;
.qdoc.parser.types.output[-15h]:`$"Datetime (deprecated)";
.qdoc.parser.types.output[-16h]:`Timespan;
.qdoc.parser.types.output[-17h]:`Minute;
.qdoc.parser.types.output[-18h]:`Second;
.qdoc.parser.types.output[-19h]:`Time;

.qdoc.parser.types.output[-30h]:`$"Boolean True";
.qdoc.parser.types.output[-31h]:`$"Boolean False";
.qdoc.parser.types.output[-35h]:`$"Any number type";
.qdoc.parser.types.output[-40h]:`$"File name";
.qdoc.parser.types.output[-41h]:`$"Folder name";
.qdoc.parser.types.output[-42h]:`$"File path";
.qdoc.parser.types.output[-43h]:`$"Folder path";
.qdoc.parser.types.output[-44h]:`$"Hostname";
.qdoc.parser.types.output[-45h]:`$"Port number";
.qdoc.parser.types.output[-46h]:`$"File or folder path";
.qdoc.parser.types.output[-50h]:`String;

.qdoc.parser.types.output,:(!).(abs;{ `$string[x]," list" })@/:'(key .qdoc.parser.types.output;value .qdoc.parser.types.output);

.qdoc.parser.types.output[0Nh]:`$"Any type";
.qdoc.parser.types.output[-0Wh]:`$"Any atom type";
.qdoc.parser.types.output[0h]:`$"Any list type";
.qdoc.parser.types.output[98h]:`Table;
.qdoc.parser.types.output[99h]:`Dictionary;
.qdoc.parser.types.output[100h]:`Function;

.qdoc.rst.namespaces:(`$())!();
.qdoc.rst.namespaces[`.z_ipc]:"Inter process communication";
.qdoc.rst.namespaces[`.z_failo]:"Fail over";
.qdoc.rst.namespaces[`.z_sec]:"Security";
.qdoc.rst.namespaces[`.z_stm]:"Local cache : engines)";
.qdoc.rst.namespaces[`.z_stm_mem]:"Global cache : shared memory";
.qdoc.rst.namespaces[`.z_msg]:"Events and messages";
.qdoc.rst.namespaces[`.z_trs]:"Transaction management";
.qdoc.rst.namespaces[`.z_da]:"Data access";
.qdoc.rst.namespaces[`.z_obj]:"Object management";
.qdoc.rst.namespaces[`.z_qu]:"Queue management";
.qdoc.rst.namespaces[`.z_lbal]:"Load balancing";
.qdoc.rst.namespaces[`.z_ast]:"Asserts";
.qdoc.rst.namespaces[`.z_test]:"Tests";
.qdoc.rst.namespaces[`.z_dt]:"Date functions";
.qdoc.rst.namespaces[`.z_log]:"Logging and recovery";
.qdoc.rst.namespaces[`.z_simul]:"Simulation management";
.qdoc.rst.namespaces[`.z_trc]:"Traces and audits";
.qdoc.rst.namespaces[`.z_util]:"Utilities";
.qdoc.rst.namespaces[`.z_zp]:"IPC hook";
.qdoc.rst.namespaces[`.z_parse]:"Parsing";
.qdoc.rst.namespaces[`.z_trsf]:"Transformation management";
.qdoc.rst.namespaces[`.z_seq]:"Sequence management";
.qdoc.rst.namespaces[`.z_rdb]:"RDB and context management";
.qdoc.rst.namespaces[`.z_db]:"Data file management";
.qdoc.rst.namespaces[`.z_map]:"Mapping of data";
.qdoc.rst.namespaces[`.z_err]:"Error management";
.qdoc.rst.namespaces[`.z_que]:"Query factory";
.qdoc.rst.namespaces[`.z_io]:"CSV and XML parsing";
