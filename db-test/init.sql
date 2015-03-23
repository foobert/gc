CREATE TABLE geocaches
( id char(8) PRIMARY KEY
, updated timestamp with time zone NOT NULL
, data jsonb
);

