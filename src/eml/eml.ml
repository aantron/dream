module Command_line :
sig
  val parse : unit -> string
end =
struct
  let usage = {|Usage:

  eml FILE
|}

  let input_file =
    ref None

  let options = []

  let set_file file =
    match !input_file with
    | None -> input_file := Some file
    | Some _ ->
      Arg.usage options usage;
      exit 2

  let parse () =
    Arg.parse options set_file usage;

    match !input_file with
    | None ->
      Arg.usage options usage;
      exit 2
    | Some input_file ->
      input_file
end



(* Location handling is done by updating a reference with the location of the
   last character read. This is pretty fragile, and depends on the tokenizer
   never looking so far forward as to invalidate the locations that it cares
   about. Locations are 0-based. The line is first. *)
module Location :
sig
  val current : unit -> int * int
  val adjust : int -> unit
  val stream : (unit -> char option) -> char Stream.t
end =
struct
  let line =
    ref 0

  let column =
    ref 0

  let current () =
    !line, !column

  let adjust by =
    column := !column + by

  let stream underlying =
    let ended = ref false in

    Stream.from begin fun _index ->
      if !ended then
        None
      else
        match underlying () with
        | None ->
          ended := true;
          None
        | Some '\n' as c ->
          incr line;
          column := 0;
          c
        | c ->
          incr column;
          c
    end
end



(* We need to retain the locations of code tokens, so we can emit the proper
   #line directives for good error messages from the compiler. *)
type 'a with_location = {
  line : int;
  column : int;
  what : 'a;
}

type code_block_token = [
  (* A block of OCaml code. These start at the beginning of the input file, and
     continue until the first line that is indented by at least two spaces, and
     starts with <.. They occur again whenever the template text is broken out
     of. Template text ends on the next line that is un-indented again. *)
  | `Code_block of string with_location
]

type newline_token = [
  (* A newline character within template text. The tokenizer notes these for
     future passes that un-indent the template and remove lines containing only
     embedded code. *)
  | `Newline
]

type template_token = [
  (* Once the template starts, text, by default, is accumulated into these
     tokens. These strings contain no newlines. *)
  | `Text of string

  (* Code found within the template text, i.e. in <% ... %> and its variants.
     The variant indicates what to do with the code - but this is irrelevant at
     the token level; the tokenizer just needs to note it for the later
     transformers to process. *)
  | `Embedded of (string * string) with_location
]

type token = [
  | code_block_token
  | newline_token
  | template_token
]

module Token :
sig
  val show : token -> string
end =
struct
  let show = function
    | `Code_block {line; column; what = code} ->
      Printf.sprintf "(%i, %i) Code_block\n%s" (line + 1) column code
    | `Text payload ->
      Printf.sprintf "Text {|%s|}" payload
    | `Newline ->
      "Newline"
    | `Embedded {line; column; what = options, code} ->
      Printf.sprintf "(%i, %i) Embedded (%s) %s" (line + 1) column options code
end

(* TODO Add start and end information to the end of file exception. *)
(* The tokenizer responds to some ASCII characters, and passes everything else
   through unchanged. So, it is UTF-8 safe. *)
module Tokenizer :
sig
  val scan : char Stream.t -> token list
end =
struct

  (* Individual token type scanners. *)

  let token_buffer =
    Buffer.create 4096

  let lookahead_buffer =
    Buffer.create 128

  let finish buffer =
    let result = Buffer.contents buffer in
    Buffer.clear buffer;
    result

  (* Consumes all characters line-by-line, until a line begins with at least two
     spaces followed by <. At the end of this scan, the stream is at the first
     significant character on the line that ended the code block, or at the end
     of input. The string contains the whitespace characters from the beginning
     of the line that terminated the code block. *)
  let scan_code_block : char Stream.t -> token * string =

    let is_template_line stream : bool * string =
      let rec scan_whitespace columns =
        match Stream.peek stream with
        | Some ' ' ->
          Stream.junk stream;
          Buffer.add_char lookahead_buffer ' ';
          scan_whitespace (columns + 1)
        | Some '<' ->
          columns >= 2
        | _ ->
          false
      in

      let result = scan_whitespace 0 in
      result, finish lookahead_buffer
    in

    let rec scan_lines stream =
      let is_template, whitespace = is_template_line stream in
      if is_template then
        finish token_buffer, whitespace
      else begin
        Buffer.add_string token_buffer whitespace;
        let rec finish_line stream =
          match Stream.peek stream with
          | Some '\n' ->
            Buffer.add_char token_buffer '\n';
            Stream.junk stream;
            scan_lines stream
          | Some c ->
            Buffer.add_char token_buffer c;
            Stream.junk stream;
            finish_line stream
          | None ->
            finish token_buffer, ""
        in
        finish_line stream
      end
    in

    fun stream ->
      let line, column = Location.current () in
      let code, leftover_whitespace = scan_lines stream in
      `Code_block {
        line;
        column;
        what = code;
      },
      leftover_whitespace

  (* Consumes up to one line of input that may contain text. Stops on newlines,
     <%, and end of input. *)
  let scan_text : string -> char Stream.t -> token =

    let rec finish_line stream =
      match Stream.peek stream with
      | Some '\n' | None ->
        finish token_buffer
      | Some '<' ->
        begin match Stream.npeek 2 stream with
        | ['<'; '%'] ->
          finish token_buffer
        | _ ->
          Buffer.add_char token_buffer '<';
          Stream.junk stream;
          finish_line stream
        end
      | Some c ->
        Buffer.add_char token_buffer c;
        Stream.junk stream;
        finish_line stream
    in

    fun leading_whitespace stream ->
      Buffer.add_string token_buffer leading_whitespace;
      `Text (finish_line stream)

  (* This is called when <% is found in template text; the stream front is <%.
     Matches options until the first space, then scans for %>. *)
  let scan_embedded : char Stream.t -> token =

    let rec scan_options stream =
      match Stream.peek stream with
      | None ->
        failwith "End of input in embedded code block"
      | Some ' ' ->
        Stream.junk stream;
        finish token_buffer
      | Some c ->
        Buffer.add_char token_buffer c;
        Stream.junk stream;
        scan_options stream
    in

    let rec scan_code stream =
      match Stream.peek stream with
      | None ->
        failwith "End of input in embedded code block"
      | Some '%' ->
        begin match Stream.npeek 2 stream with
        | [_; '>'] ->
          Stream.junk stream;
          Stream.junk stream;
          finish token_buffer
        | _ ->
          Buffer.add_char token_buffer '%';
          Stream.junk stream;
          scan_code stream
        end
      | Some c ->
        Buffer.add_char token_buffer c;
        Stream.junk stream;
        scan_code stream
    in

    fun stream ->
      (* Get rid of the <% and read any options. *)
      Stream.junk stream;
      Stream.junk stream;
      let options = scan_options stream in

      (* Note the current location, read the code, and emit the token. *)
      let line, column = Location.current () in
      `Embedded {
        line;
        column;
        what = options, scan_code stream;
      }



  (* Tokenizer state machine. *)

  let rec at_code_block tokens stream =
    let token, leftover_whitespace = scan_code_block stream in
    let tokens = token::tokens in
    (* A code block can only be terminated by template text or end of input. *)
    match Stream.peek stream with
    | None -> tokens
    | Some _ -> at_text tokens leftover_whitespace stream

  and at_text tokens leading_whitespace stream =
    let token = scan_text leading_whitespace stream in
    let tokens = token::tokens in
    (* Template text could have been terminated by embedded code, a newline, or
       end of input. In case it was terminated by a newline, check if the next
       line begins with text in the first column. If so, that is another code
       block. Otherwise, it is more template text. *)
    match Stream.peek stream with
    | None -> tokens
    | Some '\n' ->
      Stream.junk stream;
      let tokens = `Newline::tokens in
      begin match Stream.peek stream with
      | None -> tokens
      | Some ' ' -> at_text tokens "" stream
      | Some '\n' -> at_text tokens "" stream
      | Some _ -> Location.adjust (-1); at_code_block tokens stream
      end;
    (* If the text scanner stopped at <, it is actually <% and this is an
       embedded code block. *)
    | Some '<' ->
      let tokens = (scan_embedded stream)::tokens in
      at_text tokens "" stream
    (* This case should be impossible, because the text parser would have
       consumed any other character. *)
    | Some _ ->
      assert false

  let scan stream =
    stream
    |> at_code_block []
    |> List.rev
end



type template = [
  | code_block_token
  | `Template of template_token list list
]

module Transform :
sig
  (* Groups text chunks into templates. A template begins at the first chunk
     following a code block, and ends at the last chunk before the next code
     block or end of input. *)
  val delimit : token list -> template list
  val flatten : template list -> token list

  (* Within each template, finds the maximum amount of leading whitespace on
     all the lines, and removes that much whitespace from each line. *)
  val unindent : template list -> template list

  (* Removes lines that consist of only whitespace, including embedded code
     without options. *)
  val empty_lines : template list -> template list

  (* Combines adjacent texts. *)
  val coalesce : template list -> template list

  (* Filters out empty text. *)
  val trim : template list -> template list
end =
struct
  let delimit tokens =

    (* During this function, we unconditionally insert Begin before the first
       Text, Newline, or Embedded, because we have already seen a code block,
       and are looking for the beginning of the template. It will practically
       always be the next token, but be careful in case a future pass allows
       consecutive Code_blocks. *)
    let rec top_level (accumulator : template list) = function
      | (#template_token | `Newline)::_ as tokens ->
        template_level accumulator [] [] tokens
      | (`Code_block _ as token)::tokens ->
        top_level (token::accumulator) tokens
      | [] ->
        List.rev accumulator

    (* This function runs when in a template. It scans for Code_block or end of
       input; upon finding either, it appends End, and returns to the
       insert_begin state. *)
    and template_level accumulator template line = function
      | (`Code_block _)::_ | [] as tokens ->
        let template = (List.rev line)::template in
        top_level ((`Template (List.rev template))::accumulator) tokens
      | `Newline::tokens ->
        template_level accumulator ((List.rev line)::template) [] tokens
      | (#template_token as token)::tokens ->
        template_level accumulator template (token::line) tokens

    in

    top_level [] tokens



  let flatten templates =
    templates
    |> List.map (function
      | `Template template -> (List.flatten template :> token list)
      | `Code_block _ as token -> [token])
    |> List.flatten



  let map_templates f templates =
    templates
    |> List.map (function
      | `Template template -> `Template (f template)
      | `Code_block _ as token -> token)



  let rec whitespace_prefix index s =
    if index >= String.length s then
      max_int
    else
      if s.[index] != ' ' then
        index
      else
        whitespace_prefix (index + 1) s

  let common_whitespace template =
    template
    |> List.fold_left begin fun amount line ->
      match line with
      | (`Text text)::_ -> min amount (whitespace_prefix 0 text)
      | _ -> amount
    end max_int
    |> fun amount ->
      if amount = max_int then 0
      else amount

  let unindent_template amount template =
    template
    |> List.map begin function
      | (`Text text)::line ->
        let text =
          if amount >= String.length text then ""
          else String.sub text amount (String.length text - amount)
        in
        (`Text text)::line
      | line -> line
    end

  let unindent templates =
    templates |> map_templates (fun template ->
      unindent_template (common_whitespace template) template)



  let is_empty line =
    line |> List.for_all (function
      | `Text text -> String.trim text = ""
      | `Embedded {what = options, _; _} -> options = "")

  let leave_embdedded line =
    line |> List.filter (function
      | `Embedded _ -> true
      | _ -> false)

  let rec append_embeddeds accumulator = function
    | (`True line)::(`Embeddeds orphans)::lines ->
      append_embeddeds accumulator ((`True (line @ orphans))::lines)
    | line::lines ->
      append_embeddeds (line::accumulator) lines
    | [] ->
      List.rev accumulator

  let rec prepend_embeddeds accumulator = function
    | (`Embeddeds orphans)::(`Embeddeds more)::lines ->
      prepend_embeddeds accumulator ((`Embeddeds (orphans @ more))::lines)
    | (`Embeddeds orphans)::(`True line)::lines ->
      prepend_embeddeds ((`True (orphans @ line))::accumulator) lines
    | line::lines ->
      prepend_embeddeds (line::accumulator) lines
    | [] ->
      List.rev accumulator

  let empty_lines_from_template template =
    template
    |> List.map (fun line ->
      if is_empty line then
        `Embeddeds (leave_embdedded line)
      else
        `True line)
    |> append_embeddeds []
    |> prepend_embeddeds []
    |> function
      | [`Embeddeds tokens] -> [tokens]
      | true_lines ->
        true_lines |> List.map (function
          | `True line -> line
          | `Embeddeds _ -> assert false)

  let empty_lines templates =
    templates |> map_templates empty_lines_from_template



  let rec coalesce_tokens accumulator = function
    | (`Text text)::(`Text text')::tokens ->
      coalesce_tokens accumulator ((`Text (text ^ text'))::tokens)
    | token::tokens ->
      coalesce_tokens (token::accumulator) tokens
    | [] ->
      List.rev accumulator

  let coalesce_template template =
    template
    |> List.map (fun line -> (`Text "\n")::line)
    |> List.flatten
    |> (function
      | [] -> []
      | _newline::tokens -> tokens)
    |> coalesce_tokens []
    |> fun tokens -> [tokens]

  let coalesce templates =
    templates |> map_templates coalesce_template



  let trim templates =
    templates |> map_templates (fun lines ->
      lines |> List.map (fun line ->
        line |> List.filter (function
          | `Text "" -> false
          | _ -> true)))
end



module Generate :
sig
  val generate : string -> (string -> unit) -> token list -> unit
end =
struct
  let generate source_file print tokens =
    tokens |> List.iter begin function
      | `Code_block {line; what; _} ->
        Printf.ksprintf print "#%i \"%s\"\n" (line + 1) source_file;
        print what

      | `Newline ->
        assert false

      | `Text text ->
        Printf.ksprintf print "(print_string %S; flush stdout);\n" text

      (* TODO If there are options, print something else. At least parens. *)
      | `Embedded {line; column; what = "", code} ->
        Printf.ksprintf print "#%i \"%s\"\n" (line + 1) source_file;
        Printf.ksprintf print "%s%s\n" (String.make column ' ') code

      | `Embedded {line; column; what = "=", code} ->
        print "(print_string (\n";
        Printf.ksprintf print "#%i \"%s\"\n" (line + 1) source_file;
        Printf.ksprintf print "%s%s\n" (String.make column ' ') code;
        print "));\n"

      (* TODO Print location. *)
      | `Embedded {what = _, _; _} ->
        failwith "Unsupported option"
    end
end



let () =
  let input_file = Command_line.parse () in

  let output_file =
    let rec remove_extensions filename =
      match Filename.chop_extension filename with
      | filename -> remove_extensions filename
      | exception Invalid_argument _ -> filename
    in
    remove_extensions input_file ^ ".ml"
  in

  (* We don't bother closing these - the OCaml runtime and/or kernel will close
     it automatically on process exit, anyway. *)
  let input_channel = open_in input_file in
  let output_channel = open_out output_file in

  let input_stream = Location.stream (fun () ->
    try Some (input_char input_channel)
    with End_of_file -> None)
  in

  input_stream
  |> Tokenizer.scan
  |> Transform.delimit
  |> Transform.unindent
  |> Transform.empty_lines
  |> Transform.coalesce
  |> Transform.trim
  |> Transform.flatten
  |> Generate.generate input_file (output_string output_channel)
