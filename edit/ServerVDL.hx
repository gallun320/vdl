// test - editor server

import snipe.edit.EditServer;

class ServerVDL extends EditServer
{
  public function new()
    {
      super();
      moduleClasses = [
        ];
    }


  static var inst: ServerVDL;
  static function main()
    {
      inst = new ServerVDL();
      inst.init();


      inst.entry();
    }
}
