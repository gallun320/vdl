package rules;

import rules.Rules.Rules;


class Field {

  public  var Field: Array<Array<Int>>;


            public function new()
              {
                Field = MakeField();
              }

  public function MakeField(): Array<Array<Int>> {

    var matrix: Array<Array<Int>> = makeMatrix(10,10);

    for( i in 0 ... 10  ) {
      for( j in 0 ... 10  ) {
        if ((i > 1) && (i < 8) && (j > 1) && (j < 8))
              {
                  //нейтральные
                  matrix[i][j] = 5;
                  //cеребрянные
                  if (i == j) matrix[i][j] += 5;
                  //золотые
                  if (i == (9-j)) matrix[i][j] += 10;
              }
              else
              {
                  matrix[i][j] = 0;
              }

      }

    }
    return matrix;
  }

  private function makeMatrix(columns: Int, rows: Int): Array<Array<Int>> {
        var arr: Array<Array<Int>> = new Array<Array<Int>>();
        for(i in 0 ... columns){
         arr[i] = new Array<Int>();
         for(j in 0...rows){
           arr[i][j] = 0;
         }
       }
     return arr;
  }

   public function Swap(task: Dynamic): Void
   {
       var state: Int;

       if (Rules.IsWarlordFromSquad(task.dice, GetStateFrom(task.from)))
           state = 2;
       else
           state = GetSideFrom(task.from) * 5 + task.dice;

       Field[task.from[0]][task.from[1]] -= state;
       Field[task.to[0]][task.to[1]] += state;


       //if (onSwap != null) onSwap();
   }

   public function GetScoreForPlayers(): Array<Int>
   {
       var score: Array<Int> = [ 0, 0 ];

       for (player in 0 ... 2) {
         for (i in 0 ... 10) {
           for (j in 0...10)
           {
               //ищем родину этого игрока
               if (!Rules.IsHomeland(i, j)) continue;
               if (Rules.WhatPlayerWithSide(Rules.WhatSideToCell(i)) != player + 1) continue;

               var pos: Array<Int> = [i, j];

               //нейтральный город
               if (GetSideFrom(pos) == Rules.Side.NEUTRAL && GetStateFrom(pos) == Rules.State.CITY)
                   score[player] += 1;

               //собственное кольцо
               if (Rules.WhatPlayerWithSide(GetSideFrom(pos)) == player+1 && GetStateFrom(pos) == Rules.State.SOLDIERS)
                   score[player] += 1;

           }
         }
       }



       return score;
   }

   public function GetSideFrom(from: Array<Int>): Int
   {
       return Rules.CalcSide(Field[from[0]][from[1]]);
   }

   public function GetStateFrom(from: Array<Int>): Int
   {
       return Rules.CalcState(Field[from[0]][from[1]]);
   }

   /*public function GetWaysFrom(from: Array<Int>, dice: Int): List<Array<Int>>
   {
       var list: List<Array<Int>> = new List<Array<Int>>();

      var stateFrom: Int = GetStateFrom(from);

       //ищем пути вокруг точки (в радиус 1)
       for ( i in -1 ... 2) {
         for (j in -1 ... 2)
         {
             //убераем диагонали
             if (i == j || i == -j) continue;

             var ni: Int = from[0] - i;
             var nj: Int = from[1] - j;

             //проверяем границы доски
             if (ni > 9 || ni < 0 || nj > 9 || nj < 0) continue;

             var stateTo: Int = GetStateFrom([ni,nj]);

             //проверяем возможность хода в эту точку с такими параметрами
             if (Rules.IsCanSwapTo(dice, stateFrom, stateTo))
                 list.add([ni, nj]);
         }
       }

       return list;
   }*/

   /// <summary>
   /// Ищет координаты всех фигур с которыми можно сходить
   /// </summary>
   /// <param name="dice">значение кубика с которым будем совершать ход</param>
   /// <returns>список координат фигур</returns>
   /*public function GetAllPointsWhenCanStep( dice: Int,  player: Int): List<Array<Int>>
   {
       var list: List<Array<Int>> = new List<Array<Int>>();

       for ( i in 0 ... 10) {
         for (j in 0 ... 10)
         {
             //берем координаты фигуры
             var fullState: Int = Field[i][j];
             if (fullState == 0) continue;

             //собираем информацию о фигуре
             var vec = [i, j];
             var state: Int = Rules.CalcState(fullState);
             var side: Int = Rules.CalcSide(fullState);
             var canTake: Bool = Rules.IsCanTake(dice, player, state, side);
             var countWays: Int = GetWaysFrom(vec, dice).length;

             //и суем их если у нее есть ходы
             if (canTake && countWays > 0)
                 list.add(vec);
         }
       }

       return list;
   }*/

   /// <summary>
   /// проверяет блокировку фигур в диапазоне точки
   /// </summary>
   /// <returns>список точек где заблокированы фигуры</returns>
   public function GetBlockFigures(): List<Array<Int>>
   {
       var list: List<Array<Int>> = new List<Array<Int>>();

       for (i in 0 ... 10) {
         for (j in 0 ... 10)
         {
             //берем только родину
             if (!Rules.IsHomeland(i, j)) continue;

             var fullState: Int = Field[i][j];

             //считаются только нейтральные города и кольца
             if (fullState != Rules.State.CITY && fullState != 6 && fullState != 11) continue;

             //кольца должны быть только на нижней и верхней родине
             if (fullState == 6 || fullState == 11)
                 if (i != 0 || i != 9) continue;

             if (ContainNeighborInHomeland(fullState, [i, j]))
                 list.add([i, j]);
         }
       }

       return list;
   }

   public function IsWinblockFigure(from: Array<Int>): Bool
   {  trace( from[1], from[0], Rules.IsHomeland(from[1], from[0]) );
      if(!Rules.IsHomeland(from[0], from[1])) return false;
      return ContainNeighborInHomeland(GetFullStateFrom(from), from);
   }
   public function GetFullStateFrom( from: Array<Int>): Int
   {
       return Field[from[0]][from[1]];
   }

   function ContainNeighborInHomeland(fullState: Int, from: Array<Int>): Bool
   {
      if(fullState != 5 && fullState != 6 && fullState != 11) return false;
       //ищем в радиус 1
       for ( i in -1 ... 2) {
         for ( j in -1 ... 2)
         {
             //убераем диагонали
             if (i == j || i == -j) continue;

             var ni: Int = from[0] - i;
             var nj: Int = from[1] - j;

             //проверяем границы доски
             if (ni > 9 || ni < 0 || nj > 9 || nj < 0) continue;

             //берем только родину
             trace( '=======================================IsHomeland' );
             trace( Rules.IsHomeland(ni, nj) );
             if (!Rules.IsHomeland(ni, nj)) continue;

             //если это кольца то ищем только по вертикали
             trace( '=================================hooooooomelaaaaaaand=====================' );
             if (fullState > 5 && ni != from[0]) continue;
              trace( '=================================hooooooomelaaaaaaand2=====================' );
             //если состояние соседа такое же то это что и нужно было нам
             trace(  fullState, Field[ni][nj]);
             if (fullState == Field[ni][nj]) return true;
         }
       }

       return false;
   }

}
