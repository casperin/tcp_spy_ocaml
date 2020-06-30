open Core
open Async

let rec pipe r w prefix =
  match%bind Reader.read_line r with
  | `Eof -> return ()
  | `Ok line ->
    printf "%s %s\n" prefix line;
    Writer.write w line;
    Writer.write w "\n";
    pipe r w prefix

let run port (host, target) =
  printf "Listening on port %d, forwarding to %s:%d\n" port host target;
  let%bind socket =
    Tcp.Server.create
      ~on_handler_error:`Raise
      (Tcp.Where_to_listen.of_port port)
      (fun _addr r_client w_client ->
        (* Make connection to server *)
        Tcp.with_connection
        (Tcp.Where_to_connect.of_host_and_port { host; port = target })
        (fun _addr r_server w_server ->
          let%bind () =
            pipe r_client w_server "> "
          and () =
            pipe r_server w_client "< "
          in
          return ()
        ))
  in
  Tcp.Server.close_finished socket

let parse_target target =
  String.split_on_chars target ~on:[':'] |> function
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
