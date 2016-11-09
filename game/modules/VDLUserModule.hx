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
      var suc = UserCheckLogin(c, type);

       var response = null;
        switch (type) {
          case "user.logout":
            response = UserLogout(c, params);
          case "user.data":
            response = UserData(c, params);
          case "user.ping":
            response = UserPing(c, params);
          case "user.takeAll":
            response = UserAll(c, params);
          



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

      public function UserPing(c: VDLClient, params: Params): Dynamic {

        var msg: String = params.get("msg");
        trace( msg );

        return {errorCode: "ok"};
      }

      public function UserCheckLogin(c: VDLClient, type: String): Int {

        //var sendObj: Dynamic = (c.isLogin == true) ? { errorCode: "ok" } : { errorCode: 'notLogin' };
        var ret: Int = (c.isLogin == true) ? 0 : -1;
        if(c.isLogin == false) {
          c.response(type, { errorCode: 'notLogin' });
        }

        return ret;
      }

      public function UserAll(c: VDLClient, params: Params): Dynamic {
        var name = params.get('name');
        var ret = server.query("SELECT id, name FROM users WHERE name LIKE '%" + name + "%'");
        var users: Array<Dynamic> = [];

        for( el in ret ) {
          users.push({id: el.id, name: el.name});
        }

        return {errorCode: "ok", list: users };

      }

}
