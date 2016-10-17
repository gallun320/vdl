-- tournament

create table Tournament
(
  ID serial PRIMARY KEY, -- ID
  Name text DEFAULT '' NOT NULL, -- name
  StartDate timestamp with time zone DEFAULT now() NOT NULL, -- startDate
  Round int DEFAULT 1 NOT NULL, -- round
  Status text DEFAULT '' NOT NULL, -- status
  Winner int DEFAULT -1 NOT NUll, -- winner ID
  Params text DEFAULT '' NOT NULL -- parameters (Haxe)
);
