package modules;

import snipe.cache.ModuleCache;

import snipe.cache.SlaveClient;
import snipe.cache.CacheServer;
import snipe.lib.Params;
import snipe.cache.Block;
using Lambda;

 class VDLCache extends ModuleCache<CacheServer>  {

   public var tournamentId: Int;
   public var nameTournament: String;
   public var startDate: Date;
   public var usersList: Array<Int>;
   public var usersAll: Array<Int>;
   public var usersLocal: Map<Int, Array<Dynamic>>;
   public var battleActive: Array<Int>;
   public var battleFinished: Array<Int>;
   public var tournament: Block;
   public var tournamentGrid: Map<Int, Dynamic>;


   public var id(get, null): Int;
   public var firstPlayerID(get, null): Int;
   public var secondPlayerID(get, null): Int;
   public var usersRandomList: Array<Int>;
   public var turnID(get, null): Int;
   public var _list: Dynamic;
   public var room: Block;

   public function new(c: CacheServer) {
     super(c);
     name = "vdl/cache";
     tournamentGrid = new Map<Int,Dynamic>();
     usersLocal = new Map<Int,Array<Dynamic>>();
        var timeTimers = 60;
        server.timer.add({
           name: 'Check tournament',
           time: timeTimers,
           method: checkTournament,
           log: true
          });
          server.subscribeModule("core/user.registerModify", this);
          server.subscribeModule("core/user.loginPost", this);
   }

   public function checkTournament() {
     /*===============================================================*/
     // Fixed for production server
    /* var curDate: String = DateTools.format(Date.now(), '%Y-%d-%m %H:%M');
     var currentTime: String = convertDate(curDate, 3);*/

     var currentTime: String = DateTools.format(Date.now(), '%Y-%d-%m %H:%M');

     var res = server.query("SELECT * FROM tournament WHERE startdate = '" + currentTime + "' OR rounddate = '" + currentTime + "' AND status <> 'finished'");
     if(res.length > 0) {
       for( el in res ) {
         /*server.broadcast('game', {
           _type: 'tournament.startEvent',
           tournamentId: el.id,
           round: el.round
          });*/
          if(el.type == 'periodically') {
            var startDate: String = el.startdate;

            var ret = server.cacheManager.getUnlocked(0,'tournament',el.id, -1);
            var tournament = ret.block;

            startDate = convertDate(startDate, el.repeatinterval);

            tournament.set('startdate', null, startDate);
            server.cacheManager.updated(0, 'tournament', el.id);
          }

         var ret = StartCall(el.id, el.round);
       }

     }

   }

   public override function call(c: SlaveClient, type: String, params: Params): Dynamic {
     var response = null;

     switch (type) {
       case 'vdl/cache.battle.find':
         response = getAvaliableRooms(c, params);
       case 'vdl/cache.battle.create':
         response = CreateRoomCall(c, params);
        case 'vdl/cache.battle.join':
          response = JoinRoomCall(c, params);
        /*case 'vdl/cache.battle.makeTurn':
            response = MakeTurnCall(c, params);*/
        case 'vdl/cache.battle.deleteRoom':
          response = DeleteRoomCall(c, params);
        case 'vdl/cache.battle.infoRoom':
          response = RoomInfoCall(c, params);
        case 'vdl/cache.battle.finishRoom':
          response = FinishRoomCall(c, params);
        case 'vdl/cache.tournament.addUsers':
          response = AddUsersCall(c, params);
          case 'vdl/cache.tournament.deleteUsers':
            response = DeleteTournamentUsers(c, params);
        case 'vdl/cache.tournament.getAvailableTournament':
          response = GetAvailableTournamentCall(c, params);
        case 'vdl/cache.tournament.getAvailableTournamentUsers':
          response = GetTournamentUsers(c, params);
        case 'vdl/cache.tournament.setBattlesTournaments':
          response = SetBattlesTournaments(c, params);
        case 'vdl/cache.tournament.getBattlesTournaments':
          response = GetBattlesTournaments(c, params);
        case 'vdl/cache.tournament.setUsersTournament':
          response = SetUsersTournament(c, params);
        case 'vdl/cache.tournament.setGrid':
          response = SetGridTournament(c, params);
        case 'vdl/cache.tournament.deleteTournament':
          response = DeleteTournament(c, params);
        case 'vdl/cache.tournament.addRound':
          response = AddRound(c, params);
      case "vdl/cache.tournament.getTournament":
          response = GetTournament(c, params);
        case "vdl/cache.user.getData":
          response = GetUserData(c, params);
        case "vdl/cache.tournament.finish":
          response = FinishTournament(c, params);
        case 'vdl/cache.tournament.getStatus':
          response = GetTournamentStatus(c, params);
        case 'vdl/cache.battle.findRandom':
          response = FindRandomBattle(c, params);





     }
     return response;
   }

   public function FinishRoomCall(c: SlaveClient, params: Params): Dynamic {
     var roomId = params.get('roomId');
     var ret = FinishRoom(roomId);
     return ret;
   }

   public function RoomInfoCall(c: SlaveClient, params: Params): Dynamic {
     var roomId = params.get('roomId');
     var ret = RoomInfo(roomId);
     return ret;
   }
   public function RoomInfo(roomId: Int) {
     var ret = server.cacheManager.getUnlocked(0,'battle', roomId, -1);
     var room = ret.block;
     var obj = {
       firstId: room.get(null, 'firstid'),
       secondId: room.get(null, 'secondid'),
       turnId: room.get(null, 'turnid')
     }
     return obj;
   }
   public function CreateRoomCall(c: SlaveClient, params: Params): Dynamic {
      var firstId = params.get('selfId');

      var ret = createRoom(firstId);

      return ret;
   }

  public function JoinRoomCall(c: SlaveClient, params: Params): Dynamic {
     var secondId = params.get('selfId');
     var roomId = params.get('roomId');
     var ret = joinRoom(secondId, roomId);

     return ret;
   }

   public function AddUsersCall(c: SlaveClient, params: Params): Dynamic {
     var userId : Int = params.get('userId');
     var tournamentId : Int = params.get('tournament');

     var ret = AddUsers(userId, tournamentId);

     return ret;
   }

  public function FindRandomBattle(c, params): Dynamic {
    var userId: Int = params.get('userId');

    if(usersRandomList == null) usersRandomList = [];

    usersRandomList.push(userId);


    while( usersRandomList.length > 1 ) {
        var ret = createRoom(usersRandomList[0]);
        var res = joinRoom(usersRandomList[1], ret.room);
        var suc = EnemyRandom(usersRandomList[0], usersRandomList[1], ret.room);
        usersRandomList = usersRandomList.slice(2);
    }



    return { errorCode: 'ok' };
  }


  public function StartCall(tournamentId: Int, round: Int): Int {
     var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
     var tournament = ret.block;
     battleActive = [];
     if(tournamentGrid[tournamentId] == null) {
       tournamentGrid.set(tournamentId, {
          battles: [],
          round: round,
          status: 'starting'
         });
     }

     /*var userList: Array<Int> = tournament.get('params', 'usersList');
     var res = GetAvailableTournamentUsers(tournamentId);*/
     var list: Array<Int> = tournament.get('params', 'usersList');
     var roundDate = tournament.get(null,'rounddate');
     if(round > 1) {
       var grid = tournamentGrid.get(tournamentId);
       var cacheBattles: Array<Dynamic> = grid.battles;
       for( el in cacheBattles  ) {
         if(el.winner == -1) {
           var ret: Dynamic = {};
           var res: Dynamic = {};
           if( el.player1 != null ) {
              ret = createRoom(el.player1);
           }
           if(el.player2 != null) {
             res = joinRoom(el.player2, ret.room);
           }
           var suc = EnemyTournament(el.player1, el.player2, ret.room, tournamentId, round, roundDate);
           battleActive.push(ret.room);
         }
       }
       tournament.set("params", "battleActive", battleActive);

       server.cacheManager.updated(0, 'tournament', tournamentId);
       return 0;
     }
     if(list == null) list = [];
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
     var battlesGrid: Array<Dynamic> = [];
     if(bufferInt == 0) return -1;
     while (bufferInt > 0) {
       var ret = createRoom(list[bufferInt - 1]);
       var res = joinRoom(list[bufferInt - 2], ret.room);
       var suc = EnemyTournament(list[bufferInt - 1], list[bufferInt - 2], ret.room, tournamentId, round, roundDate);
       var battles: Array<Dynamic> = [];
       battlesGrid.push({ player1: list[bufferInt - 1], player2: list[bufferInt - 2], winner: -1, round: round });
       battleActive.push(ret.room);
       bufferInt = bufferInt - 2;
     }
     tournamentGrid.set(tournamentId, {
        battles: battlesGrid,
        round: round,
        status: 'starting'
       });
     tournament.set("params", "battleActive", battleActive);
     tournament.set(null, "status", "active");
     server.cacheManager.updated(0, 'tournament', tournamentId);
     return 0;
   }

   function AddRound(c: SlaveClient, params: Params): Dynamic {
     var tournamentId:Int = params.get('tournamentId');
     var round: Int = params.get('round');
     var roundDate: String = params.get('dateRound');
     var status: String = params.get('status');

     var ret = server.cacheManager.getUnlocked(0,'tournament',tournamentId, -1);
     var tournament = ret.block;

     if(status != 'finished') {
       var interval: Int = tournament.get( null, 'roundinterval');
       roundDate = convertDate(roundDate, interval);
       tournament.set(null, 'rounddate', roundDate);
     }


     tournament.set(null, 'round',round);

     server.cacheManager.updated(0, 'tournament', tournamentId);

     return {errorCode: 'ok'};
   }


  function getAvaliableRooms(c: SlaveClient, params: Params): Dynamic {
    var res  = server.query('SELECT COUNT(*) FROM battle WHERE avaliable = true AND finished <> true');
    var count;
    try {
      for (row in res) {
         count = row.count;
      }
    } catch(e:Dynamic) {
       count = 0;
    }

    if(count > 0) {
        var ret = server.query('SELECT id, firstid FROM battle WHERE avaliable = true AND finished <> true');
        var arr = [];
        for(row in ret) {
          arr.push({id: row.id, first: row.firstid});
        }
        return {errorCode: 'ok', list: arr, count: ret.length};
    }
     return {errorCode: 'not', list: {}, count: 0};
   }


   function GetAvailableTournamentCall(c: SlaveClient, params: Params): Dynamic {
     var res  = server.query("SELECT * FROM tournament");
     var arr = [];
     for(row in res) {
       var ret = server.cacheManager.getUnlocked(0,'tournament', row.id, -1);


       var tournament = ret.block;
       var userAll: Array<Int> = tournament.get('params', 'usersAll');

       var users: Array<Dynamic> = [];
       try {
           for( i in userAll ) {
             var res  = server.query("SELECT name FROM users WHERE id = " + i);
             for( el in res  ) {
               users.push({id: i, name: el.name});
             }
           }


       } catch(e:Dynamic) {
         trace(e);
         users = [];
       }



       var active: Array<Dynamic> = tournament.get('params','battleActive');
       var finished: Array<Dynamic> = tournament.get('params','battleFinished');
       var name: String = row.name;
       var startdate: String = row.startdate;
       var status: String = row.status;
       var round: Int = row.round;
       var winner: Int = row.winner;
       var rounddate: Int = row.rounddate;

       var obj = {
         id: row.id,
         name: name,
         status: status,
         startdate: startdate,
         round: round,
         winner: winner,
         userList: users,
         battleActive: active,
         battleFinished: finished,
         rounddate: rounddate
       }

       arr.push(obj);
     }
     return {errorCode: 'ok', list: arr, count: arr.length};
    }

    function SetBattlesTournaments(c: SlaveClient, params: Params): Dynamic {
      var tournamentId = params.get('tournament');
      var battles: Array<Int> = params.get('battlesData');
      var type = params.get('typeBattle');

      var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
      var tournament = ret.block;
      switch (type) {
        case "active":
          tournament.set('params','battleActive', battles);
          tournament.set(null, 'status', 'active');
        case "finished":
          var active = tournament.get('params','battleActive');
          var arr = tournament.get('params','battleFinished');
          if(arr == null) arr = [];

          for( i in battles) {
            arr.push(i);
            active.remove(i);
          }
          tournament.set('params','battleActive', active);
          tournament.set('params','battleFinished', arr);

      }


      server.cacheManager.updated(0, 'tournament', tournamentId);
      return {errorCode: "ok"};
    }

    function SetGridTournament(c: SlaveClient, params: Params): Dynamic {
      var battles:Array<Dynamic> = params.get('battles');
      var round = params.get('round');
      var tournament = params.get('tournamentId');
      var status = params.get('status');
      if(tournamentGrid[tournament] == null) {
        tournamentGrid.set(tournament, {
          round: round,
          status: status,
          battles: battles
        });
        return {errorCode: 'ok', list: battles, tournamentId: tournament};
      }
        var data = tournamentGrid.get(tournament);
        if(status == 'starting') {
          tournamentGrid.set(tournament, {
            round: round,
            status: status,
            battles: battles
          });
          return {errorCode: 'ok', list: battles, tournamentId: tournament};
        }
        var cacheBattles: Array<Dynamic> = data.battles;

        if(status == 'active' || status == 'finished') {

          if(battles.length == 0) {
            return {errorCode: 'ok', list: cacheBattles, tournamentId: tournament};
          }

          for( i in 0 ... cacheBattles.length  ) {

            if(cacheBattles[i].player1 == battles[0].player1 && cacheBattles[i].player2 == battles[0].player2 && cacheBattles[i].winner == -1) {
              cacheBattles[i].winner = battles[0].winner;
            }
            if(cacheBattles[i].player2 == null) {
              cacheBattles[i].player2 = battles[0].winner;
              return {errorCode: 'ok', list: cacheBattles, tournamentId: tournament};
            }

          }
          var round = round + 1;
          cacheBattles.push({player1: battles[0].winner, player2: null, winner: -1, round: round});
          tournamentGrid.set(tournament, {
            round: round,
            battles: cacheBattles,
            status: status
          });
          return {errorCode: 'ok', list: cacheBattles, tournamentId: tournament};

        }
        return {errorCode: 'ok', list: battles, tournamentId: tournament};
    }


    public function EnemyRandom(player1: Int, player2: Int, battleId: Int): Int {

      var slaveId1 = server.coreUserModule.getServerID(player1);

      var client1 = server.getClient(slaveId1);

      var slaveId2 = server.coreUserModule.getServerID(player2);

      var client2 = server.getClient(slaveId2);

      var playerOneName = server.query('SELECT name FROM users WHERE id=' + player1);

      var pOneName = playerOneName.results().first().name;

      var playerTwoName = server.query('SELECT name FROM users WHERE id=' + player2);

      var pTwoName = playerTwoName.results().first().name;

      var obj1 = {"enemy.num": 2,
                  "enemy.id": player2,
                  id: player1,
                  name: pOneName,
                  "enemy.name": pTwoName,
                  battleId: battleId};

      var obj2 = {"enemy.num": 1,
                  "enemy.id": player1,
                  id: player2,
                  name: pTwoName,
                  "enemy.name": pOneName,
                  battleId: battleId};

      try {
        client1.notify({
          _type:"battle.enemyEvent",
           data: obj1,
           id: player1
          });
      } catch(e:Dynamic) {
        trace(e);
        trace( '=======================================' );
        trace( 'User 1 not login' );
      }

      try {

              client2.notify({
                _type:"battle.enemyEvent",
                 data: obj2,
                 id: player2
                });
      } catch(e:Dynamic) {
        trace(e);
        trace( '=========================================' );
        trace( 'User 2 not login' );
      }
      return 0;
    }

    public function EnemyTournament(player1: Int, player2: Int, battleId: Int, tournamentId: Int, round: Int, roundDate: String): Int {

      if(player1 == null && player2 == null) {
        return -1;
      }

      if(player1 == null) player1 = 0;

      if(player2 == null) player2 = 0;

      var slaveId1 = server.coreUserModule.getServerID(player1);

      var client1 = server.getClient(slaveId1);

      var slaveId2 = server.coreUserModule.getServerID(player2);

      var client2 = server.getClient(slaveId2);

      var playerOneName = server.query('SELECT name FROM users WHERE id=' + player1);

      var pOneName = playerOneName.results().first().name;

      var playerTwoName = server.query('SELECT name FROM users WHERE id=' + player2);

      var pTwoName = playerTwoName.results().first().name;

      var obj1 = {"enemy.num": 2,
      player: 1,
      id: player1,
      "enemy.id": player2,
      name: pOneName,
      "enemy.name": pTwoName,
      round: round,
      tournamentId: tournamentId,
      battleId: battleId,
      roundDate: roundDate};

      var obj2 = {"enemy.num": 1,
      "enemy.id": player1,
      player: 2,
      id: player2,
      name: pTwoName,
      "enemy.name": pOneName,
      round: round,
      battleId: battleId,
      tournamentId: tournamentId,
      roundDate: roundDate};

      try {
        client1.notify({
          _type:"tournament.enemyEvent",
           data: obj1,
           id: player1
          });
      } catch(e:Dynamic) {
        trace(e);
        trace( '=======================================' );
        trace( 'User 1 not login' );
        client2.notify({
          _type:"tournament.leaveEvent",
           id: player2
          });
      }

      try {

              client2.notify({
                _type:"tournament.enemyEvent",
                 data: obj2,
                 id: player2
                });
      } catch(e:Dynamic) {
        trace(e);
        trace( '=========================================' );
        trace( 'User 2 not login' );
        client1.notify({
          _type:"tournament.leaveEvent",
           id: player1
          });
      }
      return 0;
    }

    function GetBattlesTournaments(c: SlaveClient, params: Params): Array<Int> {
      var tournamentId: Int = params.get('tournament');

      var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
      var tournament = ret.block;
      var arr = tournament.get('params', 'battleActive');


      return arr;
    }

    function FinishTournament(c: SlaveClient, params: Params): Dynamic {
      var tournamentId = params.get('tournamentId');
      var winner = params.get("winner");

      var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
      var tournament = ret.block;
      tournament.set(null, 'status', 'finished');
      tournament.set(null, 'winner', winner);
      tournamentGrid.set(tournamentId, {
          round: tournament.get(null, 'round'),
          status: 'finished',
          battles: []
        });

      server.cacheManager.updated(0, 'tournament', tournamentId);


      return {};
    }

    function SetUsersTournament(c: SlaveClient, params: Params): Dynamic {
      var tournamentId: Int = params.get('tournament');
      var users: Array<Int> = params.get('usersData');

      var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
      var tournament = ret.block;
      tournament.set('params', 'usersList', users);
      server.cacheManager.updated(0, 'tournament', tournamentId);

      return {errorCode: 'ok'};
    }

    function GetTournamentStatus(c: SlaveClient, params: Params): Dynamic {
      var tournamentId: Int = params.get('tournamentId');

      var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
      var tournament = ret.block;
      var status: String = tournament.get(null, 'status');

      return {errorCode: "ok", status: status};
    }


    function GetTournament(c: SlaveClient, params: Params): Dynamic {
      var tournamentId: Int = params.get('tournamentId');
      var ret = server.query("SELECT * FROM tournament WHERE id = " + tournamentId);
      var tournament: Dynamic = ret.results().first();
      return tournament;
    }
    /*function CheckPrepare(c: SlaveClient, params: Params): Dynamic {
      var tournamentId: Int = params.get('tournamentId');
      var userId: Int = params.get('userId');

      var active = usersActive.get(tournamentId);
      var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
      var tournament = ret.block;
      var usersList = tournament.get('params', 'usersList');
      if(usersList == null) return {errorCode: "usersNotFound"};
      if(active == null) active = [];

      if(!active.has(userId)) {
        active.push(userId);
      } else {
        return {errorCode: "userExist"};
      }


      if(usersList.length == active.length) {
        for( i in 0 ... usersList.length ) {
          var gameNotify = server.getClient(usersList[i]);
          gameNotify.notify({
            _type: 'tournament.startEvent',
            tournamentId: tournamentId,
            round: 1
           });
        }


      }
        usersActive.set(tournamentId, active);
        return {errorCode: "ok"};
    }*/

   /*public function MakeTurnCall(c: SlaveClient, params: Params): Dynamic {
     var userId = params.get('userId');
     var roomId = params.get('roomId');
     var data = MakeTurn(userId, roomId);
     return data;
   }*/

   public function DeleteRoomCall(c: SlaveClient, params: Params): Dynamic {
     var roomId = params.get('roomId');
     var ret = deleteRoom(roomId);

     return ret;
   }

   public function AddUsers(userId: Int, tournamentId: Int): Dynamic {
     var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
     var tournament = ret.block;
     //var res = server.query('SELECT name FROM users WHERE id = ' + userId);
     var userList: Array<Int> = tournament.get('params', 'usersList');
     var usersAll: Array<Int> = tournament.get('params', 'usersAll');
     if(userList == null) userList = [];
     if(usersAll == null) usersAll = [];
     /*var name = '';
     for( el in res ) {
       name = el.name;
     }*/

     if(userList.length > 0) {
       for( el in userList ) {
         if(el == userId) {
           return {errorCode: "userExist"};
         }
       }
     }


     userList.push(userId);
     usersAll.push(userId);
     tournament.set('params', 'usersList', userList);
     tournament.set('params', 'usersAll', usersAll);
     server.cacheManager.updated(0, 'tournament', tournamentId);


     return {errorCode: "ok"};

   }

   public function DeleteTournamentUsers(c: SlaveClient, params: Params): Dynamic {
     var userId: Int = params.get('userId');
     var tournamentId: Int = params.get('tournamentId');

     var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
     var tournament = ret.block;

     var userList: Array<Int> = tournament.get('params', 'usersList');
     var usersAll: Array<Int> = tournament.get('params', 'usersAll');

     userList.remove(userId);
     usersAll.remove(userId);

     return { errorCode: 'ok' };
   }

   public function GetTournamentUsers(c: SlaveClient, params: Params): Dynamic {
     var tournamentId = params.get("tournamentId");
     var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
     var tournament = ret.block;

     var userList: Array<Int> = tournament.get('params', 'usersList');
     server.cacheManager.updated(0, 'tournament', tournamentId);


     return {errorCode: "ok", users: userList};

   }

   public function GetUserData(c: SlaveClient, params: Params): Dynamic {
     var userId = params.get('userId');
     var ret = server.cacheManager.getUnlocked(0,'user', userId, -1);
     var user = ret.block;
     var info = user.get( null, 'params').info;
     if(info == null) info = {city: null, email: null, year: null};
     return {errorCode: "ok", info: info};
   }

   public function FinishRoom(roomId: Int): Dynamic {
     var ret = server.cacheManager.getUnlocked(0,'battle', roomId, -1);
     var room = ret.block;
     room.set(null, 'finished', true);
     server.cacheManager.updated(0, 'battle', roomId);

     return {errorCode: 'ok'};
   }
  public function createRoom(userId: Int): Dynamic {
      var id = server.nextID('Battle');

       server.cacheManager.create(0, 'battle', id);

      var ret = server.cacheManager.getUnlocked(0, 'battle', id, -1);


      room = ret.block;

      var retFirst = setFirst(userId, room.id);

      if(retFirst.errorCode == 'ok')
        return { errorCode: 'ok', player: 1, room: room.id }
      else
        return {errorCode: retFirst.errorCode  };

   }

  public function joinRoom(userId: Int, roomId: Int): Dynamic {



    room.set(null, 'secondid', userId);
    room.set(null, 'avaliable', false);
    server.cacheManager.updated(0, 'battle', roomId);

        return { errorCode: 'ok', player: 2, room: roomId };

   }


   public function setFirst(userId: Int, roomId: Int): Dynamic {
     room.set(null, 'firstid', userId);
     room.set(null, 'turnid', userId);
     room.set(null, 'avaliable', true);
     server.cacheManager.updated(0, 'battle', roomId);
     return { errorCode: 'ok' };
   }

   /*public function MakeTurn(userId: Int, roomId: Int): Dynamic {
     var room = server.cacheManager.get(0, 'battle', roomId, -1);
     var first = room.block.get(null, 'firstid');
     var second = room.block.get(null, 'secondid');
     if (first == userId)
       room.block.set(null, 'turnid', second);
     else if(second == userId)
       room.block.set(null, 'turnid', first);
    server.cacheManager.updated(0, 'battle', roomId);
     return {errorCode: true, turnId: turnID};
   }*/


   public function deleteRoom(roomID: Int): Dynamic {
          server.log('room', 'deleted room ' + roomID);

          server.cacheManager.unlock(0, 'battle', roomID);

      server.query("DELETE FROM Battle WHERE ID = " + roomID);

      return {errorCode: 'ok'};
    }

    public function DeleteTournament(c: SlaveClient, params: Params): Dynamic {
      var tournamentId: Int = params.get('tournamentId');
      server.log('tournament', 'deleted tournament ' + tournamentId);

      server.cacheManager.unlock(0, 'tournament', tournamentId);

  server.query("DELETE FROM tournament WHERE ID = " + tournamentId);
      return {errorCode: 'ok'};
    }



   public function get_id(): Int {
     return room.id;
   }

   public function get_firstPlayerID(): Int {
     return room.getInt(null, 'firstid');
   }

   public function get_secondPlayerID(): Int {
     return room.getInt(null, 'secondid');
   }

   public function get_turnID():Int {
     return room.getInt(null, 'turnid');
   }

   override function registerModify(params: Params, diffParams: Dynamic) {
     var city = params.get('city');
     var year = params.get('year');
     var email = params.get('email');
     diffParams.info = {city: city, year: year, email: email};
   }

   /*override function loginPost(c: SlaveClient, params: Params, response: Dynamic) {
     var ret = server.cacheManager.getUnlocked(0,'user', c.id, -1);
     var user = ret.block;
     var info = user.get('params', 'info');
     if(info == null) info = {city: null, email: null, year: null};
     params.params.info = info;
     response.info = info;
   }*/

   private function convertDate(strData: String, interval: Int): String {
     var str: String = new String(strData);
        var year: Int = Std.parseInt(str.substr(0, 4));
        var day: Int = Std.parseInt(str.substr(5, 2));
        var month: Int = Std.parseInt(str.substr(8, 2)) - 1;
        var hours: Int = Std.parseInt(str.substr(11, 2));
        var minute: Int = Std.parseInt(str.substr(14, 2));
        var dt: Float = new Date(year, month, day, hours, minute, 0).getTime() / 1000;
        var correctDt: Float = dt + (interval * 60 * 60);
        var formatDt: Date = Date.fromTime(correctDt * 1000);
       var endDate: String = DateTools.format(formatDt, "%Y-%d-%m %H:%M");
     return endDate;
   }


 }
