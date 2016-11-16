package modules;

import rules.*;
import snipe.slave.Server;
import snipe.slave.Module;
import snipe.lib.Params;
using Lambda;

class VDLBattleModule extends Module<VDLClient, ServerVDL>
{

  public var firstID: Int;
  public var secondID: Int;
  public var turnID: Int;
  public var roomID: Int;
  public var FieldData: Map<Int,Array<Array<Int>>>;
  public var CubesData: Map<Int, Array<Int>>;
  public var FieldFunc: Field;
  //public var TournamentModule: modules.VDLTournamentModule;

  public function new(srv: ServerVDL)
    {
      super(srv);
      name = "battle";

      server.subscribeModule("core/user.logoutPost", this);
      server.subscribeModule("core/user.loginPost", this);
      FieldData = new Map<Int,Array<Array<Int>>>();
      CubesData = new Map<Int,Array<Int>>();
      FieldFunc = new Field();
      //TournamentModule  = untyped server.getModule('tournament');
    }


    public override function call(c: VDLClient, type: String, params: Params): Dynamic {
      var suc = server.UserModule.UserCheckLogin(c, type);
       var response = null;
        switch (type) {
          case "battle.find":
            response = FindRoomCall(c, params);
          case "battle.sendtask":
              response = TaskCall(c, params);
          case "battle.access":
              response = AccessBattle(c, params);
          case "battle.message":
              response = BattleMessage(c, params);
          /*case "battle.lose":
              response = LoseCall(c, params);*/
          case "battle.end":
              response = EndCall(c, params);
        }

      return response;
      }

      public function FindRoomCall(c: VDLClient, params: Params): Dynamic {

        var ret = FindBattle(c, c.id, params);
  		  return ret;
      }

      public function TaskCall(c: VDLClient, params: Params): Dynamic {
        var roomId = params.get("battleId");
        var ret = Task(c, c.id, roomId, params);
        return ret;
      }

      public function FinishCall(c: VDLClient, params: Params): Dynamic {
        var roomId: Int = params.get('battleId');
        var ret = Finish(roomId);
        return ret;
      }

      /*public function CubeCall(c: VDLClient, params: Params): Dynamic {
        var ret = Cube(c.id);

        return ret;
      }*/

      public function EndCall(c: VDLClient, params: Params): Dynamic {
        var typeBattle: String = params.get("typeBattle");
        var type: String = params.get('type');
        var battleId: Int = params.get('battleId');
        var battle: Dynamic = RoomInfo(battleId);

        if(type == "closeGame") {
          CloseFind( c.id);
          return { errorCode: "ok" };
        }

        var idSend: Int = (c.id == battle.firstId) ? battle.secondId : battle.firstId;
        var winner: Int = (type == "winGame") ? c.id : idSend;
        var typeNotify: String = (type == "winGame") ? "battle.end" : "battle.leave";

        server.sendTo(idSend, {
            _type: typeNotify
          });

        switch (typeBattle) {
          case "tournament":
            var tournamentId: Int = params.get('tournamentId');
            var paramsData: Params = new Params({tournamentId: tournamentId, battleId: battleId, winner: winner});
            server.TournamentModule.FinishCall(c, paramsData);
          case "battle":
            var paramsData: Params = new Params({ battleId: battleId, winner: winner });
            FinishCall(c, paramsData);
        }


        return { errorCode: 'ok' };
      }

      public function enemyEvent(msg: { id: Int, data: Dynamic}) {
        var ret = new Field();
        FieldData.set(msg.data.battleId, ret.Field);
        server.sendTo(msg.id, {
          _type: "battle.enemy",
          data: msg.data
        });
      }

      public function skipEvent(msg: { id: Int, type: String}) {
        if(msg.type == "skip") {
          server.sendTo(msg.id, {
              _type: "battle.task",
              name: "skip"
            });
        } else {
          server.sendTo(msg.id, {
              _type: "battle.task",
              name: "skip"
            });
        }
      }

      public function endEvent( msg: Dynamic) {

        var c: VDLClient = server.TournamentModule.getClient(server.slaveID);
        c.id = msg.win;
        var params: Params = new Params({ typeBattle: msg.typeBattle, type: msg.type, tournamentId: msg.tournamentId, battleId: msg.battleId });
        var ret = EndCall(c, params);
      }

    public function AccessBattle(c: VDLClient, params: Params): Dynamic {
      var ready: Bool = params.get('ready');
      var player1: Int = params.get('player1');
      var player2: Int = params.get('player2');
      var roundTime: Int = params.get('roundTime');

      if(ready) {
        FindBattlCheck(player1, player2, roundTime);
      } else {
        server.sendTo(player1, {
            _type: "battle.not",
            type: "battle.access"
          });
      }

      return {errorCode: "ok"};
    }

    public function BattleMessage(c, params): Dynamic {
      var battleId: Int = params.get('battleId');
      var msg = params.get('message');
      var idSend: Int = 0;
      var player: Int = 0;
      var battle: Dynamic = RoomInfo(battleId);

      if(c.id == battle.firstId) {
        player = 1;
        idSend = battle.secondId;
      } else {
        player = 2;
        idSend = battle.firstId;
      }

      server.sendTo(idSend, {
         _type: "battle.message",
         message: msg,
         player: player
        });

      return { errorCode: "ok" };
    }

    public function FindBattle(c: VDLClient, cid: Int, params: Params): Dynamic {
      var type: String = params.get('type');
      var roundTime: Int = params.get('roundTime');
      switch (type) {
        case "random":
          FindRandomBattle(cid, roundTime);
        case "specific":
          var player2 = params.get('userId');
          var player1 = c.id;
          server.sendTo(player2, {
             player1: player1,
             player2: player2,
             roundTime: roundTime,
             _type: "battle.access"
            });
          //FindBattlCheck(player1, player2);


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

    public function FindRandomBattle(userId: Int, roundTime: Int): Void {
      var user: Dynamic = { player: userId, time: roundTime };
      var ret = server.cacheRequest({
          _type: 'vdl/cache.battle.findRandom',
          user: user
        });
    }


    public function FindBattlCheck(player1: Int, player2: Int, roundTime: Int): Void {
      var ret = server.cacheRequest({
          _type: 'vdl/cache.battle.findCheck',
          player1: player1,
          player2: player2,
          roundTime: roundTime
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

    public function Task(c: VDLClient, cid: Int, roomId: Int, params: Params): Dynamic {
      var name: String = params.get('name');
      var player: Int = 0;

      var user = RoomInfo(roomId);
      var enemId = 0;
      if(cid == user.firstId) {
        player = 2;
        enemId = user.secondId;
      } else if(cid == user.secondId){
        player = 1;
        enemId = user.firstId;
      }

      if(name == "throw") {
        var arr: Array<Int> = new Array<Int>();
        for (i in 0 ... 6) {
          arr.push(Std.random(6));
        }
        CubesData.set(cid, arr);
        var dices = CubesData.get(cid).copy();
        var obj: Dynamic = {name: name, dices: dices, errorCode: "ok"};
        c.response("battle.sendtask", obj);
        obj._type = "battle.task";
        server.sendTo(enemId, obj);

        return { errorCode: "ok" };
      }

      if(name == "skip") {
        if(user.turnId == cid) {
          params.params.type = "battle.task";
          params.params._type = "battle.task";

          var obj: Dynamic = params.params;

          server.sendTo(enemId, obj);

          MakeTurn(cid, roomId);

          return {errorCode: 'ok'};
        } else {
          return { errorCode: "cannotSkip" };
        }
      }


      var dice: Int = params.get('dice');
      var side: Int = params.get('side');

      var from: Array<Int> = params.get('from');
      var to: Array<Int> = params.get('to');
      var battleId: Int = params.get('battleId');

      var cubes: Array<Int> = CubesData.get(cid).copy();
      //var cubesLocal: Array<Int> = cubes.copy();

      var field: Array<Array<Int>> = FieldData.get(roomId).copy();
      FieldFunc.Field = FieldData.get(roomId).copy();


      var stateTo: Int = Rules.CalcState(field[to[0]][to[1]]);
      var state: Int = Rules.CalcState(field[from[0]][from[1]]);

      var winBlock: Bool = FieldFunc.IsWinblockFigure(from);

      var winBlockTo: Bool = FieldFunc.IsWinblockFigure(to);
      var sideTo: Int = FieldFunc.GetSideFrom(to);





      if(!Rules.IsCanTake(dice, player, state, side, from[0], winBlock) ) {

        var dices: Array<Int> = CubesData.get(cid).copy();
        var field: Array<Array<Int>> =  FieldFunc.Field;

        var obj: Dynamic = { dices: dices, pole: field, errorCode: "cannotSwap"};
        return obj;
      }

      if(!Rules.IsCanSwapTo(dice, state, to[0], stateTo, sideTo, winBlockTo, side)) {

        var dices: Array<Int> = CubesData.get(cid).copy();
        var field: Array<Array<Int>> =  FieldFunc.Field;

        var obj: Dynamic = { dices: dices, pole: field, errorCode: "cannotSwap"};
        return obj;
      }

      if(cubes.has(dice)) {
        cubes.remove(dice);
        //CubesData.set(cid, cubes);
      } else {

        var dices: Array<Int> = CubesData.get(cid).copy();
        var field: Array<Array<Int>> = FieldFunc.Field;

        var obj: Dynamic = { dices: dices, pole: field, errorCode: "cannotSwap"};
        return obj;
      }

      params.params.dices = cubes;
      var obj: Dynamic = params.params;
      FieldFunc.Swap(obj);

      var scores: Array<Int> = FieldFunc.GetScoreForPlayers();
      SetBattleScores(user.firstId, user.secondId, scores, battleId);
      trace( FieldFunc.Field );
      FieldData.set(roomId, FieldFunc.Field);
      CubesData.set(cid, cubes);
      //var dices = CubesData.get(cid).toString();
    /*var obj = {
        type: "battle.task",
        _type: "battle.task",
        battleId: roomId,
        name: name,
        side: side,
        dice: dice,
        dices: dices,
        from: from.toString(),
        to: to.toString()
      }*/
      params.params.type = "battle.task";
      params.params._type = "battle.task";
      params.params.dices = CubesData.get(cid).copy();
      var obj: Dynamic = params.params;
      //c.listStatistic.push(params);
      server.sendTo(enemId, obj);

      return {errorCode: 'ok'};
    }

    public function Finish(roomId: Int): Dynamic {
      //server.query("INSERT INTO statistics (id, firstid,secondid, roomid, params) VALUES ('', "+ firstId +","+ secondId +","+ roomId +"," + scores + ")");
      FinishRoom(roomId);
      //DeleteRoom(roomId);
      //server.sendTo(secondId, {_type: "battle.end"});
      return {errorCode: 'ok'}
    }

    /*public function Cube(cid: Int): Dynamic {
      var arr: Array<Int> = new Array<Int>();
      for (i in 0 ... 6) {
        arr.push(Std.random(6));
      }
      CubesData.set(cid, arr);
      return { errorCode: 'ok', cube: arr};
    }*/

    public function SetBattleScores(player1: Int, player2: Int, scores: Array<Int>, battleId: Int): Void {
      var ret = server.cacheRequest({
          _type: 'vdl/cache.battle.setScores',
          player1: player1,
          player2: player2,
          scores: scores,
          battleId: battleId
        });
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
    public function MakeTurn(userId: Int, roomId: Int): Void {
      var ret = server.cacheRequest({
         _type: 'vdl/cache.battle.makeTurn',
         userId: userId,
         roomId: roomId
        });
    }

    public function DeleteRoom(roomId: Int) {
      var ret = server.cacheRequest({
         _type: 'vdl/cache.battle.deleteRoom',
         roomId: roomId
        });
      return ret;
    }

    public function CloseFind(userId: Int): Void {
      var ret = server.cacheRequest({
         _type: 'vdl/cache.battle.closeFind',
         userId: userId
        });
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
      FinishRoom(roomId);
      server.sendTo(enemId, {_type: 'battle.leave'});
      trace('room destroy');
    }

    /*override function loginPost(c:VDLClient, params:Params, retParams:Dynamic, responseParams:Dynamic): Void {
      var paramsData: Params = new Params({battleId: 77, tournamentId: 1, winner: 94});
      var ret = server.TournamentModule.GetStatus(1);
      trace( '======================================' );
      trace( ret);
    }*/

}
