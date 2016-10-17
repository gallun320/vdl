-- statistics

create table Statistics
(
  ID serial PRIMARY KEY, -- ID

  FirstID int DEFAULT 0 NOT NULL, -- first ID
  SecondID int DEFAULT 0 NOT NULL, -- second ID

  RoomID int DEFAULT 0 NOT NULL, 
  Params text DEFAULT '' NOT NULL -- parameters (Haxe)
);
