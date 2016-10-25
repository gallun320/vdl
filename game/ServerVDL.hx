import snipe.slave.MetaServer;
import snipe.slave.ServerGame;

class ServerVDL extends ServerGame
{
  function new(metav: MetaServer, idv: Int)
    {
      super(metav, idv);
    }


  override function initModulesGame()
    {
      loadModules([ modules.VDLBattleModule, modules.VDLTournamentModule, modules.VDLUserModule ]);
      //addNoLoginRequests([ 'user.ping' ]);

    }


  static var s: ServerVDL;
  static function main()
    {
      var meta = new MetaServer('game', ServerVDL, VDLClient);
      meta.initServer();
      meta.start();
    }
}
