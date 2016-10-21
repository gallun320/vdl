-- tournament

create table Tournament
(
  ID serial PRIMARY KEY, -- ID
  Name text DEFAULT '' NOT NULL, -- name
  StartDate text DEFAULT '' NOT NULL, -- startDate
  RoundDate text DEFAULT '' NOT NULL, -- roundDate
  Round int DEFAULT 1 NOT NULL, -- round
  Status text DEFAULT '' NOT NULL, -- status
  Type text DEFAULT 'once' NOT NULL, -- type
  RoundTime int DEFAULT 30 NOT NULL, -- round time
  RoundInterval int DEFAULT 1 NOT NULL, -- interval of round
  RepeatInterval int DEFAULT 0 NOT NULL, -- repeat interval tournament
  Winner int DEFAULT -1 NOT NUll, -- winner ID
  Params text DEFAULT '' NOT NULL -- parameters (Haxe)
);
