import snipe.cache.CacheServer;

class CacheServerVDL extends CacheServer
{
  function new()
    {
      super();
    }


  public override function initModules()
    {
      loadModules([modules.VDLCache]);
      cacheManager.loadModules([ data.BattleCacheData, data.TournamentCacheData ]);
    }


  static var s: CacheServerVDL;
  static function main()
    {
      s = new CacheServerVDL();
      s.initServer();
      s.start();
    }
}
