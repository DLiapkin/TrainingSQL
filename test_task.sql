create database if not exists sql_test default character set utf8;

use sql_test;

-- droping the tables to be recreated again
SET foreign_key_checks = 0;
drop table if exists `bank`;
drop table if exists `city`;
drop table if exists `account`;
drop table if exists `client`;
drop table if exists `filial`;
drop table if exists `socialStatus`;
drop table if exists `card`;
SET foreign_key_checks = 1;

-- creating tables
create table if not exists `bank`(
	id int unsigned not null primary key auto_increment,
    `name` varchar(255) not null
);

create table if not exists `city`(
	id int unsigned not null primary key auto_increment,
    `name` varchar(255) not null
);

create table if not exists `filial`(
	id int unsigned not null primary key auto_increment,
    cityId int unsigned default null,
    `adress` varchar(255) not null,
    bankId int unsigned default null,
    foreign key (bankId) references `bank`(id) on update cascade on delete cascade,
    foreign key (cityId) references `city`(id) on update cascade on delete cascade
);

create table if not exists `socialStatus`(
	id int unsigned not null primary key auto_increment,
    `name` varchar(255) not null default '',
    `addition` int unsigned default 0
);

create table if not exists `client`(
	id int unsigned not null primary key auto_increment,
    `name` varchar(255) not null,
    socialStatusId int unsigned not null
);

create table if not exists `account`(
	id int unsigned not null primary key auto_increment,
    bankId int unsigned not null,
    clientId int unsigned not null,
    `account` int default 0,
    foreign key (bankId) references `bank`(id) on update cascade on delete cascade,
    foreign key (clientId) references `client`(id) on update cascade on delete cascade
);

create table if not exists `card`(
	id int unsigned not null primary key auto_increment,
    accountId int unsigned not null,
    `account` int unsigned default 0,
    foreign key (accountId) references `account`(id) on update cascade on delete cascade
);

-- adding constraints to client's table
alter table  `client`
add constraint FK_socialRoleId foreign key (socialStatusId) references `socialStatus`(id) on update cascade on delete cascade;

-- adding values into the tables
insert into `bank`(`name`) values ('Belarusbank'), ('VTB'), ('Belinvest'), ('BNB'), ('Belagroprombank');

insert into `city`(`name`) values ('Minsk'), ('Gomel'), ('Grodno'), ('Mogilev'), ('Brest');

insert into `filial`(cityId, `adress`, bankId) values (1, 'Yakuba Kolasa 12', 1), 
(2, 'Dimitrava 20', 1),
(2, 'Frunze 3', 2),
(2, 'Lenina 45', 2),
(3, 'Sovetskih Pogranichnikov 92', 3),
(1, 'Pobedi 12', 4),
(4, 'Mira 55', 5);