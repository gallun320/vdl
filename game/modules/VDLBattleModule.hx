package modules;

import snipe.slave.Server;
import snipe.slave.Module;
import snipe.lib.Params;


class VDLBattleModule extends Module<VDLClient, ServerVDL>
{

  public var firstID: Int;
  public var secondID: Int;
  public var turnID: Int;
  public var roomID: Int;
  //public var TournamentModule: modules.VDLTournamentModule;

  public function new(srv: ServerVDL)
    {
      super(srv);
      name = "battle";

      server.subscribeModule("core/user.logoutPost", this);
      server.subscribeModule("core/user.loginPost", this);
      //TournamentModule  = untyped server.getModule('tournament');
    }


    public override function call(c: VDLClient, type: String, params: Params): Dynamic {
       var response = null;
        switch (type) {
          case "battle.find":
            response = FindRoomCall(c, params);
          case "battle.sendtask":
              response = TaskCall(c, params);
          case "battle.cubes":
              response = CubeCall(c, params);
          /*case "battle.lose":
              response = LoseCall(c, params);*/
          case "battle.end":
              response = EndCall(c, params);
        }

      return response;
      }

      public function FindRoomCall(c: VDLClient, params: Params): Dynamic {
        var suc = server.UserModule.UserCheckLogin(c);
        var ret = FindBattle(c, c.id, params);
  		  return ret;
      }

      public function TaskCall(c: VDLClient, params: Params): Dynamic {
        var roomId = params.get("roomId");
        var ret = Task(c, c.id, roomId, params);
        return ret;
      }

      public function FinishCall(c: VDLClient, params: Params): Dynamic {
        var roomId: Int = params.get('battleId');
        var ret = Finish(roomId);
        return ret;
      }

      public function CubeCall(c: VDLClient, params: Params): Dynamic {
        var ret = Cube();

        return ret;
      }

      public function EndCall(c: VDLClient, params: Params): Dynamic {
        var typeBattle: String = params.get("typeBattle");
        var type: String = params.get('type');
        var battleId: Int = params.get('battleId');
        var battle: Dynamic = RoomInfo(battleId);
        var idSend: Int = (c.id == battle.firstId) ? battle.secondId : battle.firstId;
        var winner: Int = (type == "winGame") ? c.id : idSend;
        var typeNotify: String = (type == "winGame") ? "battle.end" : "battle.leave";

        switch (typeBattle) {
          case "tournament":
            var tournamentId: Int = params.get('tournamentId');
            var paramsData: Params = new Params({tournamentId: tournamentId, battleId: battleId, winner: winner});
            server.TournamentModule.FinishCall(c, paramsData);
          case "random":
            var paramsData: Params = new Params({ battleId: battleId, winner: winner });
            FinishCall(c, paramsData);
        }

        server.sendTo(idSend, {
            _type: typeNotify
          });

        return { errorCode: 'ok' };
      }

      public function enemyEvent(msg: { id: Int, data: Dynamic }) {
        server.sendTo(msg.id, {
          _type: "battle.enemy",
          data: msg.data
        });
      }

    public function FindBattle(c: VDLClient, cid: Int, params: Params): Dynamic {
      var type = params.get('type');

      switch (type) {
        case "random":
          FindRandomBattle(cid);

      }

      /*var res = GetAvaliableRooms();
      var list: Array<Dynamic> = res.list;
      var count = res.count;
      if(res.errorCode == 'not') {
        var ret = CreateRoom(cid);

        return ret;
      } else {

				var r = Std.random(count);
				var i = 0;
        for(el in list)
						{

							if(i == r)
							{
								var res = JoinRoom(cid, el.id);
                if(res.errorCode == 'ok') {

                  var data = Enemy(c, cid, el.first);
                  if( data.errorCode == 'ok' ) {
                    return res;
                  }
                }

							}
							i++;
						}


      }
      return { errorCode: "Not battle" };*/
      return { errorCode: "ok" };
    }

    public function FindRandomBattle(userId: Int): Void {
      var ret = server.cacheRequest({
          _type: 'vdl/cache.battle.findRandom',
          userId: userId
        });
    }

/*public function Enemy(c: VDLClient,selfId: Int, enemId: Int): Dynamic {
        var selfName = server.query('SELECT name FROM users WHERE id=' + selfId);
        var enemName = server.query('SELECT name FROM users WHERE id=' + enemId);
        var sName = '';
        var eName = '';
        for(i in selfName) {
          sName = i.name;
        }
        for(i in enemName) {
          eName = i.name;
        }
        server.sendTo(enemId, {"enemy.num": 2,"enemy.id": enemId, name: eName, "enemy.name": sName, type: "battle.enemy", _type: "battle.enemy"});
        c.response('battle.enemy', {"enemy.num": 1, "enemy.id": selfId, name: sName, "enemy.name": eName, type: "battle.enemy"});
        return {errorCode: 'ok'};
    }*/

    public function Task(c: VDLClient, cid: Int, roomId: Int, params: Params) {
      var user = RoomInfo(roomId);
      var enemId = 0;
      if(cid == user.firstId) {
        enemId = user.secondId;
      } else if(cid == user.secondId){
        enemId = user.firstId;
      }
    /*  var obj = {
        type: "battle.task",
        _type: "battle.task",
        roomId: params.get('roomId'),
        name: params.get('name'),
        side: params.get('side'),
        diceID: params.get('diceID'),
        dice: params.get('dice'),
        dices: params.get('dices'),
        from: params.get('from'),
        to: params.get('to')
      }*/
      params.params.type = "battle.task";
      params.params._type = "battle.task";
      var obj: Dynamic = params.params;
      //c.listStatistic.push(params);
      server.sendTo(enemId, obj);

      return {errorCode: 'ok'}
    }

    public function Finish(roomId: Int): Dynamic {
      //server.query("INSERT INTO statistics (id, firstid,secondid, roomid, params) VALUES ('', "+ firstId +","+ secondId +","+ roomId +"," + scores + ")");
      FinishRoom(roomId);
      //DeleteRoom(roomId);
      //server.sendTo(secondId, {_type: "battle.end"});
      return {errorCode: 'ok'}
    }

    public function Cube(): Dynamic {
      var arr: Array<Int> = new Array<Int>();
      for (i in 0 ... 6) {
        arr.push(Std.random(6));
      }
      return { errorCode: 'ok', cube: arr};
    }

    public function GetAvaliableRooms(): Dynamic {
        var ret = server.cacheRequest({
          _type: 'vdl/cache.battle.find'
        });

        return ret;
    }

    public function CreateRoom(cid: Int) {
      var ret = server.cacheRequest({
        _type: 'vdl/cache.battle.create',
        selfId: cid
      });

      return ret;
    }

    public function JoinRoom(cid: Int, roomId: Int) {
      var ret = server.cacheRequest({
         _type: 'vdl/cache.battle.join',
         selfId: cid,
         roomId: roomId
        });
      return ret;
    }

    public function FinishRoom(roomId: Int) {
      var ret = server.cacheRequest({
          _type: 'vdl/cache.battle.finishRoom',
          roomId: roomId
        });
      return ret;
    }
    /*public function MakeTurn(userId: Int, roomId: Int) {
      var ret = server.cacheRequest({
         _type: 'vdl/cache.battle.makeTurn',
         userId: userId,
         roomId: roomId
        });
      return ret;
    }*/

    public function DeleteRoom(roomId: Int) {
      var ret = server.cacheRequest({
         _type: 'vdl/cache.battle.deleteRoom',
         roomId: roomId
        });
      return ret;
    }

    public function RoomInfo(roomId: Int) {
      var ret = server.cacheRequest({
         _type: 'vdl/cache.battle.infoRoom',
         roomId: roomId
        });
      return ret;
    }

    override function logoutPost(c: VDLClient) {
      var ret = server.query('SELECT id FROM battle WHERE firstid=' + c.id + ' OR secondid=' + c.id + ' AND finished <> true');
      var roomId = 0;
      for( i in ret  ) {
        roomId = i.id;
      }
      var user = RoomInfo(roomId);
      var enemId = 0;
      if(c.id == user.firstId) {
        enemId = user.secondId;
      } else if(c.id == user.secondId){
        enemId = user.firstId;
      }
      DeleteRoom(roomId);
      server.sendTo(enemId, {_type: 'battle.end'});
      trace('room destroy');
    }

    /*override function loginPost(c:VDLClient, params:Params, retParams:Dynamic, responseParams:Dynamic): Void {
      var paramsData: Params = new Params({battleId: 77, tournamentId: 1, winner: 94});
      var ret = server.TournamentModule.GetStatus(1);
      trace( '======================================' );
      trace( ret);
    }*/

}
