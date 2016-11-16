package modules;

import snipe.slave.Server;
import snipe.slave.Module;
import snipe.lib.Params;


class VDLShopModule extends Module<VDLClient, ServerVDL>
{
  public function new(srv: ServerVDL)
    {
      super(srv);
      name = "shop";
    }


    public override function call(c: VDLClient, type: String, params: Params): Dynamic
      {
        var response = null;

        switch (type) {
          case "shop.get":
            response = get(c, params);
          case "shop.buy":
            response = buy(c, params);
          case "shop.sell":
            response = sell(c, params);
        }

        return response;
      }

      function get(c: VDLClient, params: Params): Dynamic
    {
      // update shop items cache
      server.coreShopModule.getDiff();

      // make a list of shop items
      var items = new List<Dynamic>();
      for (shopItem in server.coreShopModule.iterator())
        {
          var item = shopItem.item;
          var o = item.dump(c.lang);
          o.isDisabled = shopItem.isDisabled;
          if (shopItem.amount >= 0)
            o.amount = shopItem.amount;

          items.add(o);
        }

      return { errorCode: "ok", shopItems: items };
    }

  function buy(c: VDLClient, params: Params): Dynamic
    {
      var itemID = params.getInt("itemID");

      var shopItem = server.coreShopModule.getItem(itemID);
      if (shopItem == null)
        throw "shop.buy(): item not in shop";

      if (shopItem.amount == 0)
        return { errorCode: "itemFinished" };

      if (shopItem.isDisabled)
        return { errorCode: "itemDisabled" };

      // check for money
      var item = shopItem.item;
      var price = item.attrs.getInt("price");
      if (c.money < price)
        return { errorCode: "notEnoughMoney" };

      // send request to buy to cache server
      var ret = server.coreShopModule.buy(itemID);
      if (ret != "ok")
        return { errorCode: ret };

      // try adding item to inventory
      var ret = c.user.inventory.put(item, 1);
      if (ret != "ok")
        return { errorCode : ret };

      // remove money
      c.money -= price;

      if (shopItem.amount > 0)
        shopItem.amount--;

      return { errorCode: "ok" };
    }

  function sell(c: VDLClient, params: Params): Dynamic
    {
      var id = params.getInt("id");

      var item = c.user.inventory.get(id);
      if (item == null)
        return { errorCode: "notInInventory" };

      var price = item.attrs.getInt("price");
      c.user.inventory.remove(item);
      c.money += price;

      // notify cache server
      server.coreShopModule.sell(item.id);

      return { errorCode: "ok" };
    }

}
