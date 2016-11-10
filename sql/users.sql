-- users

create table Users
(
  ID serial PRIMARY KEY, -- ID

  Name text DEFAULT '' NOT NULL, -- name
  NetworkID text DEFAULT '' NOT NULL, -- id in social network
  NetworkType char(2) DEFAULT '' NOT NULL, -- social network type
  Language char(2) DEFAULT '', -- user language
  Password text DEFAULT '' NOT NULL, -- password
  Email text DEFAULT '' NOT NULL, -- email
  City text DEFAULT '' NOT NULL, -- city
  Year text DEFAULT '' NOT NULL, -- year
  Params text DEFAULT '' NOT NULL, -- parameters (JSON)
  RegDate timestamp with time zone DEFAULT now() NOT NULL, -- registration date
  IsBanned boolean DEFAULT 'f' NOT NULL, -- user banned?
  Deleted boolean DEFAULT 'f' NOT NULL -- user deleted?
);

create index users_name on users(name);
create index users_networkid on users(networkid);
create index users_networktype on users(networktype);
create index users_password on users(password);
create index users_email on users(email);
create index users_regdate on users(regdate);

insert into users (name, params) values ('--- DEFAULT ATTRIBUTES ---', '{"attrs":{},"inventory":{"list":[]}}, "info": {"city":"", "year": "", "email": ""}');


create or replace function pfunc_users_trigger_before_del()
returns trigger as $$
DECLARE
BEGIN
  IF OLD.ID = 1 THEN
    RETURN NULL;
  END IF;

  RETURN OLD;
END
$$ language plpgsql;

CREATE TRIGGER Users_before_del BEFORE DELETE ON Users
FOR EACH ROW EXECUTE PROCEDURE pfunc_users_trigger_before_del();

create or replace function pfunc_users_trigger_del()
returns trigger as $$
DECLARE
BEGIN
  DELETE FROM UserRatings WHERE UserID = OLD.ID;
--  DELETE FROM UserLog WHERE UserID = OLD.ID;
--  DELETE FROM UserInfos WHERE UserID = OLD.ID;
--  DELETE FROM StatsUsersLastLoginDate WHERE UserID = OLD.ID;
  RETURN OLD;
END
$$ language plpgsql;

CREATE TRIGGER Users_del AFTER DELETE ON Users
FOR EACH ROW EXECUTE PROCEDURE pfunc_users_trigger_del();
