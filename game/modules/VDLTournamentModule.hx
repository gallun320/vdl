package modules;

import snipe.slave.Server;
import snipe.slave.Module;
import snipe.lib.Params;


class VDLTournamentModule extends Module<VDLClient, ServerVDL>
{
  public var id: Int;
  public var nameTournament: String;
  public var status: String;
  public var startDate: Date;
  public var usersList: Array<Int>;
  public var battleActive: Array<Int>;
  public var battleFinished: Array<Int>;


  public var firstID: Int;
  public var secondID: Int;
  public var turnID: Int;
  public var roomID: Int;

  public function new(srv: ServerVDL)
    {
      super(srv);
      name = "tournament";

      /*var timeTimers = 30 * 60;
      server.timer.add({
         name: 'Check tournament',
         log: true,
         time: timeTimers,
         isServerThread: true,
         method: checkTournament
         });*/
      server.subscribeModule("core/user.logoutPost", this);
      server.subscribeModule("core/user.registerPre", this);
      server.subscribeModule("core/user.loginPre", this);
      server.subscribeModule("core/user.loginPost", this);
    }

  /*  public function checkTournament() {

      var currentTime: String = DateTools.format(Date.now(), "%Y-%d-%m %H:%m");
      var res = server.query("SELECT * FROM tournament WHERE startdate = '" + currentTime + "' AND winner = -1 AND status = 'starting'");
      trace( currentTime, res.length );
      if(res.length > 0) {
        for( el in res ) {
          StartCall(el.id, el.round);
        }

      }

    }*/

    public override function call(c: VDLClient, type: String, params: Params): Dynamic {
       var response = null;
        switch (type) {
          case "tournament.getAvailableTournament":
            response = GetAvailableTournamentCall(c, params);
          case "tournament.addUsers":
            response = AddUsersCall(c, params);
          case "tournament.deleteUsers":
            response = DeleteUsersCall(c, params);
          case "tournament.end":
            response = FinishCall(c, params);
          case "tournament.lose":
            response = LoseCall(c, params);
          case "tournament.grid":
            response = GetTournamentGrid(c, params);
        /*  case "tournament.checkPrepare":
            response = CheckPrepare(c, params);*/

        }

      return response;
      }


      /*public function startEvent(msg: {tournamentId: Int, round: Int}) {
        StartCall(msg.tournamentId, msg.round);
      }*/

      public function enemyEvent(msg: { id: Int, data: Dynamic }) {
        server.sendTo(msg.id, {
          _type: "tournament.enemy",
          data: msg.data
        });
      }

      /*public function StartCall(tournamentId: Int, round: Int): Void {
        var res = GetAvailableTournamentUsers(tournamentId);
        var list: Array<Int> = res.users;
        var buffer: Float = list.length;
        var counter: Int = 0;
        while (buffer >= 2)
        {
          buffer = buffer / 2;
          counter++;
        }
        var players: Int = 1;
        while(counter > 0) {
          players = players * 2;
          counter--;
        }
        buffer = list.length - players;
        while(buffer > 0)
        {
          list.remove(list[list.length - 1]);
          buffer--;
        }
        buffer = list.length;
        var bufferInt: Int = Std.int(buffer);
        var battles: Array<Int> = new Array<Int>();
        while (bufferInt > 0) {
          battles.push(CreateBattle(list[bufferInt - 2], list[bufferInt - 1], tournamentId, round));
          bufferInt = bufferInt - 2;
        }
        if(battles.length > 0) {
            SetBattlesTournament(battles, tournamentId, "active");
        }

      }
      private function CreateBattle(player1: Int, player2: Int, tournamentId: Int, round: Int): Int {
        var retCreate = CreateRoom(player1);
        var retJoin = JoinRoom(player2, retCreate.room);
        Enemy(player1, player2, retCreate.room, tournamentId, round);
        return retCreate.room;
      }*/

      public function FinishCall(c: VDLClient, params: Params): Dynamic {
        var tournamentId: Int = params.get('tournamentId');
        var player1: Int = params.get("player1");
        var player2: Int = params.get("player2");
        var winner: Int = params.get('winner');
        var lose: Int = params.get('lose');
        var battleId: Int = params.get('battleId');
        var round: Int = params.get('round');
        var dateRound: String = params.get('dateRound');
        var battles: Array<Int> = GetBattlesTournaments(tournamentId);
        var res = GetAvailableTournamentUsers(tournamentId);
        var users: Array<Int> = res.users;
        var ret = Finish(tournamentId, dateRound, player1, player2, winner, lose, battleId, round, battles, users);
        return ret;
      }

      public function LoseCall(c: VDLClient, params: Params): Dynamic {
        var winner: Int = params.get("winner");

        server.sendTo(winner, {
          _type: "battle.leave"
          });
        return {errorCode: "ok"};
      }

      public function GetTournamentGrid(c: VDLClient, params: Params): Dynamic {
        var tournamentId = params.get('tournamentId');
        var round = params.get('round');
        if(round > 1) {
          var ret = SetGrid([], round, tournamentId);
          return ret;
        }
        var res = GetAvailableTournamentUsers(tournamentId);
        var list: Array<Int> = res.users;
        var buffer: Float = list.length;
        var counter: Int = 0;
        while (buffer >= 2)
        {
          buffer = buffer / 2;
          counter++;
        }
        var players: Int = 1;
        while(counter > 0) {
          players = players * 2;
          counter--;
        }
        buffer = list.length - players;
        while(buffer > 0)
        {
          list.remove(list[list.length - 1]);
          buffer--;
        }
        buffer = list.length;
        var bufferInt : Int = Std.int(buffer);
        //var bufferLenght: Int = Std.int(buffer);
        var battles: Array<Dynamic> = new Array<Dynamic>();
        while (bufferInt > 0) {
          battles.push({player1: list[bufferInt - 2], player2: list[bufferInt - 1], round: round, winner: -1});
          bufferInt = bufferInt - 2;
        }
        var ret = SetGrid(battles, round, tournamentId);
        return ret;
      }
      /*public function CubeCall(c: VDLClient, params: Params): Dynamic {
        var ret = Cube();

        return ret;
      }*/

      public function AddUsersCall(c: VDLClient, params: Params): Dynamic {
        var tournamentId : Int = params.get("tournamentId");
        var ret = AddUsers(c.id, tournamentId);

        return ret;
      }

      public function DeleteUsersCall(c: VDLClient, params: Params): Dynamic {
        var tournamentId : Int = params.get("tournamentId");
        var res = GetAvailableTournamentUsers(tournamentId);
        var list: Array<Int> = res.users;
        list.remove(c.id);
        SetUsersTournament(list, tournamentId);
        return { errorCode: 'ok' };
      }

      public function GetAvailableTournamentUsers(tournament: Int): Dynamic {
        var ret = server.cacheRequest({
          _type: 'vdl/cache.tournament.getAvailableTournamentUsers',
          tournamentId: tournament
        });
        return ret;
      }

      public function GetAvailableTournamentCall(c: VDLClient, params: Params): Dynamic {
        var ret = server.cacheRequest({
          _type: 'vdl/cache.tournament.getAvailableTournament'
        });
        return ret;
      }


      public function SetGrid(battleData: Array<Dynamic>, round: Int, tournament: Int): Dynamic {
        var ret = server.cacheRequest({
            _type: 'vdl/cache.tournament.setGrid',
            battles: battleData,
            round: round,
            tournamentId: tournament
          });
        return ret;
      }

    /*public function FindBattle(c: VDLClient, cid: Int, params: Params): Dynamic {

      var count = 0;
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
      return { errorCode: "Not battle" };
    }*/
  /*public function CheckPrepare(c: VDLClient, params: Params): Dynamic {
    var tournamentId = params.get('tournamentId');
    var userId = c.id;

    AddActive(tournamentId, userId);

    return  {errorCode: "ok"};
  }*/

/*public function Enemy(player1: Int, player2: Int, battleId: Int, tournamentId: Int, round: Int): Void {
        var playerOneName = server.query('SELECT name FROM users WHERE id=' + player1);
        var playerTwoName = server.query('SELECT name FROM users WHERE id=' + player2);
        var pOneName = playerOneName.first().name;
        var pTwoName = playerTwoName.first().name;
        var pOneName = '';
        var pTwoName = '';
        for(i in playerOneName) {
          pOneName = i.name;
        }
        for(i in playerTwoName) {
          pTwoName = i.name;
        }
        server.sendTo(player1, {"enemy.num": 2,
        "enemy.id": player1,
        name: pOneName,
        "enemy.name": pTwoName,
        round: round,
        tournamentId: tournamentId,
        battleId: battleId,
        type: "tournament.enemy",
        _type: "tournament.enemy"});

        server.sendTo(player2, {"enemy.num": 1,
        "enemy.id": player2,
        name: pTwoName,
        "enemy.name": pOneName,
        round: round,
        battleId: battleId,
        tournamentId: tournamentId,
        type: "tournament.enemy",
        _type: "tournament.enemy"});
    }*/

    /*public function Task(c: VDLClient, cid: Int, params: Params) {
      var roomId = params.get('roomId');
      var user = RoomInfo(roomId);
      var enemId = 0;
      if(cid == user.firstId) {
        enemId = user.secondId;
      } else if(cid == user.secondId){
        enemId = user.firstId;
      }
      var obj = {
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
      }
      c.listStatistic.push(obj);
      server.sendTo(enemId, obj);

      return {errorCode: 'ok'}
    }*/

    public function Finish(tournamentId: Int,
                            dateRound: String,
                            player1: Int,
                            player2: Int,
                            winner: Int,
                            lose: Int,
                            battleId: Int,
                            round: Int,
                             battles: Array<Int>,
                             users: Array<Int>): Dynamic
    {
      battles.remove(battleId);
      users.remove(lose);
      /*for(el in users) {
          if(el.id == lose) {
              users.remove(el);
            }
          }*/
      var arr: Array<Int> = [battleId];
      FinishRoom(battleId);
      DeleteRoom(battleId);
      SetBattlesTournament(arr, tournamentId, "finished");
      SetUsersTournament(users, tournamentId);
      var ret = SetGrid([{player1: player1, player2: player2, winner: winner, round: round}], round, tournamentId);
      //server.sendTo(secondId, {_type: "battle.end"});
      if(battles.length > 0) {
         return {errorCode: "wait"};
       } else {
         if(users.length > 1) {
           round++;
           AddRound(round, tournamentId, dateRound);
           //StartCall(tournamentId, round);
         } else {
           //DeleteTournament(tournamentId);
           FinishTournament(tournamentId);
           return {errorCode: "TournamentEnd"};
         }
       }
      return {errorCode: 'ok'}
    }

    /*public function Cube(): Dynamic {
      var arr: Array<Int> = new Array<Int>();
      for (i in 0 ... 6) {
        arr.push(Std.random(6));
      }
      return { errorCode: 'ok', cube: arr};
    }*/

    public function AddActive(tournamentId: Int, userId: Int): Void {
      var ret = server.cacheRequest({
          _type: "vdl/cache.tournament.addActive",
          tournamentId: tournamentId,
          userId: userId
        });
    }

    public function FinishTournament(tournamentId: Int): Void {
      var ret = server.cacheRequest({
          _type: "vdl/cache.tournament.finish",
          tournamentId: tournamentId
        });
    }


    public function AddRound(round: Int, tournamentId: Int, dateRound: String) {
      var ret = server.cacheRequest({
          _type: 'vdl/cache.tournament.addRound',
          round: round,
          tournamentId: tournamentId,
          dateRound: dateRound
        });
    }
    public function SetBattlesTournament(battles: Array<Int>, tournamentId: Int, typeBattle: String): Void {
      var ret = server.cacheRequest({
        _type: 'vdl/cache.tournament.setBattlesTournaments',
        battlesData: battles,
        tournament: tournamentId,
        typeBattle: typeBattle
      });
    }

    public function SetUsersTournament(users: Array<Int>, tournamentId: Int): Void {
      var ret = server.cacheRequest({
        _type: 'vdl/cache.tournament.setUsersTournament',
        usersData: users,
        tournament: tournamentId
      });
    }

    public function GetBattlesTournaments(tournamentId: Int): Array<Int> {
      var ret = server.cacheRequest({
        _type: 'vdl/cache.tournament.getBattlesTournaments',
        tournament: tournamentId
      });
      return ret;
    }

    public function AddUsers(cid: Int, tournamentId: Int): Dynamic {
      var ret = server.cacheRequest({
        _type: 'vdl/cache.tournament.addUsers',
        userId: cid,
        tournament: tournamentId
      });
      return ret;
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

    public function DeleteTournament(tournamentId: Int) {
      var ret = server.cacheRequest({
        _type: 'vdl/cache.tournament.deleteTournament',
        tournamentId: tournamentId
        });
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

    override function registerPre(c: VDLClient, params: Params): Bool {
      var name = params.get('name');
      var password = params.get('password');
      trace( params.params.length );
      if(name != null && password != null) return true;
    var res = server.query("SELECT * FROM users");
    var nameAndPass = 'uid' + (res.length + 1);
    var pass = haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(nameAndPass));
      params.params.password = nameAndPass;
      params.params.name = nameAndPass;
      c.response('user.auth', {token: pass});
      return true;
    }
    override function loginPre(c: VDLClient, params: Params): Bool {

      var token = params.get('token');
      if(token == null) return true;
      var data = haxe.crypto.Base64.decode(token);
      var dataStr : String  = data.toString();

      params.params.name = cast(dataStr, String);
      params.params.password = cast(dataStr, String);

      return true;
    }

    /*override  function loginPost(c: VDLClient, params: Params, retParams: Dynamic,
    responseParams: Dynamic) {
      server.sendTo(c.id, {
        _type: "tournament.enemy",
        data: {"enemy.num": 2,
        player: 1,
        "enemy.id": 1,
        name: "test",
        "enemy.name": "test1",
        round: 1,
        tournamentId: 1,
        battleId: 1}
      });
    }*/
}
