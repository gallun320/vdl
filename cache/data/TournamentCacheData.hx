package  data;


import snipe.cache.Cache;
import snipe.cache.CacheManager;

class TournamentCacheData extends Cache
{
  public function new(mng: CacheManager)
    {
      super(mng);

      name = 'tournament';
      tableName = 'Tournament';
      hasParams = true;
    }

}
