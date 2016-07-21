# Remote shell using Net::Async::WebSocket

This work is based on https://github.com/vti/showmetheshell

## Changes

- Using `Net::Async::WebSocket` over `PocketIO`
- Using `IO::Tty::Util` over `IO::Pty`
  - `IO::Pty` creates pipe with already opened terminal only.
  - You have no control of the terminal to connect with.
  - If you open more then one connection, strange things happens (like ghost terminals)
  - `IO::Tty::Util::forkpty` **creates** new pseudoterminal for every new connection
- Cursor and F-keys works :)
