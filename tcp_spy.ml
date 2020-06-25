open Core
open Async


let rec pipe r w buffer dir =
  Reader.read r buffer
  >>= function
  | `Eof -> return ()
  | `Ok bytes_read ->
    let s = Bytes.sub buffer ~pos:0 ~len:bytes_read |> Bytes.to_string in
    print_string @@ String.substr_replace_all s ~pattern:"\n" ~with_:("\n"^dir^" ");
    Writer.write w s;
    Writer.flushed w
    >>= fun () ->
    pipe r w buffer dir



let run port (host, target) =
  print_endline @@ "Listening on port "^string_of_int port^", forwarding to "^host^":"^string_of_int target;
  Tcp.Server.create
    ~on_handler_error:`Raise
    (Tcp.Where_to_listen.of_port port)
    (fun _addr r_client w_client ->
      (* Make connection to server *)
      Tcp.with_connection
        (Tcp.Where_to_connect.of_host_and_port { host; port = target })
        (fun _addr r_server w_server ->
          (* Set up piping between client and server *)
          let buffer1 = Bytes.create (16 * 1024) in
          let buffer2 = Bytes.create (16 * 1024) in
          Deferred.any [
            pipe r_client w_server buffer1 ">";
            pipe r_server w_client buffer2 "<"
          ]))
  >>= Tcp.Server.close_finished 



let parse_target target =
  String.split_on_chars target ~on:[':']
  |> function
    | [host; port] -> (host, int_of_string port)
    | [port] -> ("localhost", int_of_string port)
    | _ -> ("localhost", 8080)



let () =
  Command.async
    ~summary:"TCP Spy" begin
      let open Command.Param in
      map (both
        (anon ("port" %: int))
        (anon ("target" %: string))
      )
      ~f:(fun (port, target) ->
        (fun () ->
          run port (parse_target target)
        ))
    end
  |> Command.run

