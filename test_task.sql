create database if not exists sql_test default character set utf8;

use sql_test;

-- droping the tables to be recreated again
SET foreign_key_checks = 0;
drop table if exists `bank`;
drop table if exists `account`;
drop table if exists `client`;
drop table if exists `socialRole`;
drop table if exists `card`;
SET foreign_key_checks = 1;

-- creating tables
create table if not exists `bank`(
	id int unsigned not null primary key auto_increment,
    `name` varchar(255) not null,
    `city` varchar(255) not null,
    `adress` varchar(255) not null
);

create table if not exists `client`(
	id int unsigned not null primary key auto_increment,
    `name` varchar(255) not null,
    accountId int unsigned default null,
    socialRoleId int unsigned not null
);

create table if not exists `account`(
	id int unsigned not null unique primary key auto_increment,
    bankId int unsigned not null,
    clientId int unsigned not null,
    `account` int default 0,
    foreign key (bankId) references `bank`(id) on update cascade on delete cascade,
    foreign key (clientId) references `client`(id) on update cascade on delete cascade
);

create table if not exists `socialRole`(
	id int unsigned not null primary key auto_increment,
    `name` varchar(255) not null default '',
    `addition` int unsigned default 0
);

create table if not exists `card`(
	id int unsigned not null primary key auto_increment,
    accountId int unsigned not null,
    `account` int unsigned default 0,
    foreign key (accountId) references `account`(id) on update cascade on delete cascade
);

-- adding constraints to client's table
alter table  `client`
add constraint FK_socialRoleId foreign key (socialRoleId) references `socialRole`(id) on update cascade on delete cascade,
add constraint FK_accountId foreign key (accountId) references `account`(id) on update cascade on delete cascade;

-- adding values into the tables
insert into `bank`(`name`, `city`, `adress`) values ('Belarusbank', 'Minsk', 'Yakuba Kolasa'), 
('Belarusbank', 'Gomel', 'Dimitrava'),
('VTB', 'Gomel', 'Frunze'),
('VTB', 'Gomel', 'Lenina'),
('Belinvest', 'Grodno', 'Pushkina');

insert into `socialRole`(`name`, `addition`) values ('veteran', '500'),
('disabled', '1000'),
('base', '0');