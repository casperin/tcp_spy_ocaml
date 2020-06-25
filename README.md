# TCP Spy in OCaml

My first OCaml program.

Run it with dune:
```sh
dune exec -- ./tcp_spy.exe 9000 8080
```

Then if you have something running on port 8080, you can point whatever at port
9000 instead, and this program will forward communication while printing it in
the terminal.

You can define the target host like this:
```sh
dune exec -- ./tcp_spy.exe 9000 example.com:80
```
Most places on the web will just forward you to their https port instead, which
won't be useful at all.
