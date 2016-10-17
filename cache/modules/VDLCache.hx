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
   public var usersActive: Map<Int,Array<Int>>;
   public var battleActive: Array<Int>;
   public var battleFinished: Array<Int>;
   public var tournament: Block;
   public var tournamentGrid: Map<Int, Dynamic>;


   public var id(get, null): Int;
   public var firstPlayerID(get, null): Int;
   public var secondPlayerID(get, null): Int;
   public var turnID(get, null): Int;
   public var _list: Dynamic;
   public var room: Block;

   public function new(c: CacheServer) {
     super(c);
     name = "vdl/cache";
     tournamentGrid = new Map<Int,Dynamic>();
     usersActive = new Map<Int,Array<Int>>();
        var timeTimers = 60;
        server.timer.add({
           name: 'Check tournament',
           time: timeTimers,
           method: checkTournament,
           log: true
          });

   }

   public function checkTournament() {

     var currentTime: String = DateTools.format(Date.now(), '%Y-%d-%m %H:%M');
     var res = server.query("SELECT * FROM tournament WHERE startdate = '" + currentTime + "' AND status = 'starting'");
     if(res.length > 0) {
       for( el in res ) {
         /*server.broadcast('game', {
           _type: 'tournament.startEvent',
           tournamentId: el.id,
           round: el.round
          });*/
         //StartCall(el.id, el.round, el.name);
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
        case "vdl/cache.tournament.addActive":
          response = CheckPrepare(c, params);




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


  public function StartCall(tournamentId: Int, round: Int, name: String): Void {
     var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
     var tournament = ret.block;
     /*var userList: Array<Int> = tournament.get('params', 'usersList');
     var res = GetAvailableTournamentUsers(tournamentId);*/
     var list: Array<Int> = tournament.get('params', 'usersList');
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
     while (bufferInt > 0) {
       var gameNotify = server.getClient(list[bufferInt]);
       gameNotify.notify({
         _type: 'tournament.accessEvent',
         name: name,
         client: gameNotify.id
        });
       bufferInt--;
     }

   }

   function AddRound(c: SlaveClient, params: Params): Dynamic {
     var tournamentId = params.get('tournamentId');
     var round = params.get('round');

     var ret = server.cacheManager.getUnlocked(0,'tournament',tournamentId, -1);
     var tournament = ret.block;

     tournament.set('round', null, round);

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
       var userList: Array<Int> = tournament.get('params', 'usersList');

       var users = [];
       try {
         for( i in userList ) {
           var res  = server.query("SELECT name FROM users WHERE id = " + i);
           for( el in res  ) {
             users.push({id: i, name: el.name});
           }

         }
       } catch(e:Dynamic) {
         trace(e);
         users = null;
       }



       var active: Array<Dynamic> = tournament.get('params','battleActive');
       var finished: Array<Dynamic> = tournament.get('params','battleFinished');
       var name: String = row.name;
       var startdate: String = row.startdate;
       var status: String = row.status;
       var round: Int = row.round;
       var winner: Int = row.winner;

       var obj = {
         id: row.id,
         name: name,
         status: status,
         startdate: startdate,
         round: round,
         winner: winner,
         userList: users,
         battleActive: active,
         battleFinished: finished
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
      if(tournamentGrid[tournament] == null) {
        tournamentGrid.set(tournament, {
          round: round,
          battles: battles
        });
        return {errorCode: 'ok', list: battles, tournamentId: tournament};
      }
        var data = tournamentGrid.get(tournament);
        if(round == 1) {
          tournamentGrid.set(tournament, {
            round: round,
            battles: battles
          });
          return {errorCode: 'ok', list: battles, tournamentId: tournament};
        }
        var cacheBattles: Array<Dynamic> = data.battles;

        if(round > 1) {

          if(battles.length == 0) {
            return {errorCode: 'ok', list: cacheBattles, tournamentId: tournament};
          }

          for( el in cacheBattles  ) {
            if(el.player1 == battles[0].player1 && el.player2 == battles[0].player2 && el.winner == -1) {
              el.winner = battles[0].winner;
            }
            if(el.player2 == null) {
              el.player2 = battles[0].winner;
            } else {
              cacheBattles.push({player1: battles[0].winner, player2: null, winner: -1, round: round});
            }

          }
          tournamentGrid.set(tournament, {
            round: round,
            battles: cacheBattles
          });
          return {errorCode: 'ok', list: cacheBattles, tournamentId: tournament};

        }
        return {errorCode: 'ok', list: battles, tournamentId: tournament};
        /*if(data.round == round) {
          if(round == 1 && data.round == 1) {
            tournamentGrid.set(tournament, {
              round: round,
              battles: battles
            });
            return {errorCode: 'ok', list: battles, tournamentId: tournament};
          }
          return {errorCode: 'ok', list: data.battles, tournamentId: tournament};
        } else {
          data.round = round;
          data.battles = data.battles.concat(battles);
          tournamentGrid.set(tournament, {
            round: data.round,
            battles: data.battles
          });
          return {errorCode: 'ok', list: data.battles, tournamentId: tournament};
        }*/


    }

    function GetBattlesTournaments(c: SlaveClient, params: Params): Array<Int> {
      var tournamentId: Int = params.get('tournament');

      var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
      var tournament = ret.block;
      var arr = tournament.get('params', 'battleActive');


      return arr;
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

    function CheckPrepare(c: SlaveClient, params: Params): Dynamic {
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
    }

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
     if(userList == null) userList = [];
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
     tournament.set('params', 'usersList', userList);
     server.cacheManager.updated(0, 'tournament', tournamentId);


     return {errorCode: "ok"};

   }

   public function GetTournamentUsers(c: SlaveClient, params: Params): Dynamic {
     var tournamentId = params.get("tournamentId");
     var ret = server.cacheManager.getUnlocked(0,'tournament', tournamentId, -1);
     var tournament = ret.block;

     var userList: Array<Int> = tournament.get('params', 'usersList');
     server.cacheManager.updated(0, 'tournament', tournamentId);


     return {errorCode: "ok", users: userList};

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

      var ret = server.cacheManager.get(0, 'battle', id, -1);


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

 }
