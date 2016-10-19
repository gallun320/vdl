package modules;

import snipe.slave.Server;
import snipe.slave.Module;
import snipe.lib.Params;


class VDLUserModule extends Module<VDLClient, ServerVDL>
{
  public function new(srv: ServerVDL)
    {
      super(srv);
      name = "user";
    }

    public override function call(c: VDLClient, type: String, params: Params): Dynamic {
       var response = null;
        switch (type) {
          case "user.logout":
            response = UserLogout(c, params);
          case "user.data":
            response = UserData(c, params);

        }

      return response;
      }

      public function UserLogout(c: VDLClient, params: Params): Int {
        c.response('user.logout', {errorCode: 'ok'});
        server.disconnect(c);
        return 0;
      }

      public function UserData(c: VDLClient, params: Params): Dynamic {
        var userId = c.id;
        var ret = server.cacheRequest({
           _type: "vdl/cache.user.getData",
           userId: userId
          });
        return ret;
      }
}
