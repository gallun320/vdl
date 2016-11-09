package rules;



typedef SideType = {
   NEUTRAL: Int,
   SILVER: Int,
   GOLD: Int
}

typedef StateType = {
     NULL: Int,
     SOLDIERS: Int,
     TOWER: Int,
     SQUAD: Int,
     PRISON: Int,
     CITY: Int,
     WARLORD: Int
}

class Rules  {

  public static var Side: SideType = { NEUTRAL: 0, SILVER: 1, GOLD: 2 };
  public static var State: StateType = { NULL : 0,
            SOLDIERS : 1,
            TOWER : 2,
            SQUAD : 3,
            PRISON : 4,
            CITY : 5,
            WARLORD : 6 };

  public static function IsCanTake( dice: Int,  player  : Int,  state : Int,  side : Int, line: Int, winBlock: Bool): Bool
      {
        //исключим пустой ход
          if (dice == State.NULL || state == State.NULL) return false;
          trace( '==========================================taaaaaaaaaaaaaaake1================================' );
          trace( winBlock, WhatSideToCell(line), side );      //нельзя трогать заблокированную фигуру на чужой родине
          if (winBlock && WhatSideToCell(line) != side) return false;
                //можно взять нейтральную фигуру или своего цвета
          if (side == Side.NEUTRAL || player == side)
          {
       //если выбран тот же кубик
       trace( '==========================================taaaaaaaaaaaaaaake================================' );
       trace(state, dice);
            if (dice == state) return true;            //можно вытащить отряд из города
            if (dice == State.SQUAD && state == State.CITY) return true;            //или полководца из отряда
            if (dice == State.SOLDIERS && state == State.SQUAD) return true;
            
          }
          return false;
      }

      public static function IsCanSwapTo( dice : Int,  stateFrom : Int, lineTo: Int, stateTo: Int, sideTo: Int, winblockTo: Bool, side: Int): Bool
      {
        //можно передвинуть отряд из города в пустой замок
             if (dice == State.SQUAD && stateFrom == State.CITY && stateTo == State.TOWER) return true;        //командира можно отправить только из отряда в пустой замок
             if (dice == State.SOLDIERS && stateFrom == State.SQUAD)
             {
                 if (stateTo == State.TOWER)
                     return true;
                 else
                     return false;
             }        //можно подбить солдат заточением
           if (dice == State.PRISON && stateFrom == State.PRISON && stateTo == State.SOLDIERS)
           {
               //можно подбить свои или нейтральные
               if (sideTo == side || sideTo == Side.NEUTRAL) return true;            //или подбить чужие не заблокированные
               if (!winblockTo) return true;            //или подбить чужие заблокированные на собственной родине
               if (WhatSideToCell(lineTo) == side) return true;
           }        //можно подбить отряд замком
          if (dice == State.TOWER && stateFrom == State.TOWER && stateTo == State.SQUAD) return true;        //можно передвинуть в пустую ячейку
          if (stateTo == 0) return true;
          return false;
      }

      public static function IsCorrectState( state : Int): Bool
      {
          if (state >= 0 && state <= 6)
          {
              return true;
          }

          return false;
      }

      public static function IsCorrectSide( side : Int): Bool
      {
          if (side >= 0 && side <= 2)
          {
              return true;
          }

          return false;
      }

      public static function IsHomeland( i : Int, j : Int): Bool
      {
          if (i == 0 || i == 9 || j == 0 || j == 9)
              return true;
          else
              return false;
      }

      public static function IsRingHome( i : Int, j : Int): Bool
      {
          if (i == 0 || i == 9)
          {
              if (j >= 0 && j <= 2)
                  return true;
              if (j <= 9 && j >= 7)
                  return true;
          }
          return false;
      }



      public static function WhatSideToCell(i: Int): Int
      {
          if (i < 5)
              return 1;
          else
              return 2;
      }

      public static function WhatPlayerWithSide(i: Int): Int
      {
          return (i == 2) ? 1 : 2;
      }

      public static function WhatGiveUp( dice: Int, state: Int): Int
      {
          //если пытаемся поднять солдат из отряда то поднимаем командира
          if (IsWarlordFromSquad(dice, state)) return 6;

          //в других случаях поднимаем в соответствии с кубиком
          return dice;
      }

      public static function CalcSide(fullState: Int): Int
      {
          var state: Int = Std.int((fullState - 1) / 5);
          return state;
      }

      public static function CalcState(fullState: Int): Int
      {
          var state: Int = ((fullState - 1) % 5) + 1;
          return state;
      }

      public static function CorrectStateForWarlord(state: Int): Int
      {
          if (state > 0)
          {
              return 2;
          }
          else
          {
              return -2;
          }

      }



      public static function IsWarlordFromSquad(dice: Int, state: Int): Bool
      {
          if (dice == State.SOLDIERS && state == State.SQUAD) return true;

          return false;
      }

      public static function ContainsSoldiers(state: Int): Bool
      {
          if (state == State.SOLDIERS || state == State.SQUAD || state == State.CITY) return true;

          return false;
      }

      public static function ContainsTower( state: Int): Bool
      {
          if (state == State.TOWER || state == State.PRISON || state == State.CITY) return true;

          return false;
      }

      public static function ContainsWarlord(state: Int): Bool
      {
          if (state == State.SQUAD || state == State.PRISON || state == State.CITY || state == State.WARLORD) return true;

          return false;
      }



      public static function GetZone( i: Int, j: Int, side: Int): Int
      {
          if (WhatSideToCell(i) != side) return -1;
          if (IsZoneLeftRing(i, j, side)) return 1;
          if (IsZoneRightRing(i, j, side)) return 2;
          if (IsZoneMidle(i, j, side)) return 3;
          if (IsZoneLeftCity(i, j, side)) return 4;
          if (IsZoneRightCity(i, j, side)) return 5;
          return 0;
      }

      public var ZoneLeftRing: Int = 1;
      public var ZoneRightRing: Int = 1;
      public var ZoneMidle: Int = 1;
      public var ZoneLeftCity: Int = 1;
      public var ZoneRightCity: Int = 1;

      public static function IsZoneLeftRing(i: Int, j: Int, side: Int): Bool
      {
          if(WhatSideToCell(i) == side)
          {
              if ((i == 0 || i == 9) && (j >= 0 && j <= 2))
                  return true;
          }
          return false;
      }

      public static function IsZoneRightRing( i: Int, j: Int, side: Int): Bool
      {
          if (WhatSideToCell(i) == side)
          {
              if ((i == 0 || i == 9) && (j >= 7 && j <= 9))
                  return true;
          }
          return false;
      }

      public static function IsZoneMidle( i: Int, j: Int, side: Int): Bool
      {
          if (WhatSideToCell(i) == side)
          {
              if ((i == 0 || i == 9) && (j >= 3 && j <= 6))
                  return true;
          }
          return false;
      }

      public static function IsZoneLeftCity( i: Int, j: Int, side: Int): Bool
      {
          if (WhatSideToCell(i) == side)
          {
              if ((j == 0 ) && (i >= 1 && i <= 8))
                  return true;
          }
          return false;
      }

      public static function IsZoneRightCity(i: Int, j: Int, side: Int): Bool
      {
          if (WhatSideToCell(i) == side)
          {
              if ((j == 9) && (i >= 1 && i <= 8))
                  return true;
          }
          return false;
      }
}
