import snipe.cache.UniServer;

class UniServerVDL extends UniServer
{
  function new()
    {
      super();
    }


// main function
  static var u: UniServerVDL;
  static function main()
    {
      u = new UniServerVDL();
      u.print("UniServerMine " +
        snipe.lib.MacroBuild.getBuildBranch() + "-" +
        snipe.lib.MacroBuild.getBuildDate());
      u.print("Snipe Core " +
        snipe.lib.MacroBuild.getCoreBranch('../..') + "-" +
        snipe.lib.MacroBuild.getCoreDate('../..'));
      u.cacheClass = CacheServerVDL;
      u.slaveInfos = [
        {
          type: 'game',
          client: VDLClient,
          server: ServerVDL,
        },
        ];
      u.init();
      u.start();
    }
}
