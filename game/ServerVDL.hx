import snipe.slave.MetaServer;
import snipe.slave.ServerGame;

class ServerVDL extends ServerGame
{

  public var BattleModule(default, null): modules.VDLBattleModule;
  public var TournamentModule(default, null): modules.VDLTournamentModule;
  public var UserModule(default, null): modules.VDLUserModule;

  function new(metav: MetaServer, idv: Int)
    {
      super(metav, idv);
    }


  override function initModulesGame()
    {
      loadModules([ modules.VDLTournamentModule, modules.VDLBattleModule, modules.VDLUserModule ]);
      addNoLoginRequests([ 'user.check' ]);

      BattleModule = getModule('battle');
      TournamentModule = getModule('tournament');
      UserModule = getModule('user');

    }


  static var s: ServerVDL;
  static function main()
    {
      var meta = new MetaServer('game', ServerVDL, VDLClient);
      meta.initServer();
      meta.start();
    }
}
