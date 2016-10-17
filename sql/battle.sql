-- battle

create table Battle
(
  ID serial PRIMARY KEY, -- ID

  FirstID int DEFAULT 0 NOT NULL, -- first ID
  SecondID int DEFAULT 0 NOT NULL, -- second ID

  TurnID int DEFAULT 0 NOT NULL, -- Turn Player ID
  Avaliable boolean DEFAULT true NOT NULL,
  Finished boolean DEFAULT false NOT NULL,
  Params text DEFAULT '' NOT NULL -- parameters (Haxe)
);
