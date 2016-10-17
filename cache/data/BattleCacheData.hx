package  data;


import snipe.cache.Cache;
import snipe.cache.CacheManager;

class BattleCacheData extends Cache
{
  public function new(mng: CacheManager)
    {
      super(mng);

      name = 'battle';
      tableName = 'Battle';
      hasParams = true;
    }

}
