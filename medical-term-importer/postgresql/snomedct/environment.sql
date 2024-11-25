/** Sourced from the SNOMED database loader repository: https://github.com/IHTSDO/snomed-database-loader/blob/master/PostgreSQL/environment-postgresql.sql **/

/*create table description_f*/
drop table if exists description_f cascade;
create table description_f(
  id varchar(18) not null,
  effectivetime char(8) not null,
  active char(1) not null,
  moduleid varchar(18) not null,
  conceptid varchar(18) not null,
  languagecode varchar(2) not null,
  typeid varchar(18) not null,
  term text not null,
  casesignificanceid varchar(18) not null,
  PRIMARY KEY(id, effectivetime)
);
