// client info

import sys.net.Socket;

import snipe.slave.ServerGame;
import snipe.slave.Block;
import snipe.slave.ClientGame;

class VDLClient extends ClientGame
{
  public var money(get, set): Int;
  public function new(s: Socket, srv: ServerGame)
    {
      super(s, srv);

    }

  public function get_money(): Int
    {
      return user.attrs.get("money");
    }

  public function set_money(v: Int)
    {
      user.attrs.set("money", v);
      return v;
    }
}
