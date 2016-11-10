package modules;


import snipe.slave.Server;
import snipe.slave.Module;
import snipe.lib.Params;


class VDLUserModule extends Module<VDLClient, ServerVDL>
{

  public var userPrepareFriend: Map<Int,Array<Int>>;
  public function new(srv: ServerVDL)
    {
      super(srv);
      name = "user";
      userPrepareFriend = new Map<Int,Array<Int>>();
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
          case "user.addFriend":
            response = UserFriends(c, params);




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

      public function UserFriends(c: VDLClient, params: Params): Dynamic {
        var userId = params.get("userId");
        var type = params.get("type");
        var friendPrepareList = [];
        switch (type) {
          case "add":
            friendPrepareList = userPrepareFriend.get(c.id);
            friendPrepareList.push(userId);
            FriendAdd(c.id, userId, "prepare");
            server.sendTo(userId, {
               player: c.id,
               _type: "user.friendAccess"
              });
          case "access":
            friendPrepareList = userPrepareFriend.get(userId);
            friendPrepareList.remove(c.id);
            FriendAdd(c.id, userId, "add");
            FriendAdd(userId, c.id, "add");
            server.sendTo(c.id, {
               player: userId,
               _type: "user.friendAdd"
              });
          case "denied":
            friendPrepareList = userPrepareFriend.get(userId);
            friendPrepareList.remove(c.id);
            FriendAdd(userId, c.id, "denied");
            server.sendTo(c.id, {
               player: userId,
               _type: "user.denied"
              });
        }

        return {errorCode: "ok"};

      }

      public function FriendAdd(player: Int, friend: Int, type: String): Void {
        var ret = server.cacheRequest({
            _type: "vdl/cache.user.addFriend",
            player: player,
            friend: friend,
            type: type
          });
      }

}
