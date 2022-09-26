create database sql_test;

GO

use sql_test;
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";
drop table if exists city;
drop table if exists account;
drop table if exists filial;
drop table if exists bank;
drop table if exists client;
drop table if exists socialStatus;
drop table if exists card;
EXEC sp_msforeachtable "ALTER TABLE ? CHECK CONSTRAINT all";

create table bank(
	id int check (id > 0) not null primary key identity,
    name varchar(255) not null
);

create table city(
	id int check (id > 0) not null primary key identity,
    name varchar(255) not null
);

create table filial(
	id int check (id > 0) not null primary key identity,
    cityId int check (cityId > 0) default null,
    adress varchar(255) not null,
    bankId int check (bankId > 0) default null,
    foreign key (bankId) references bank(id) on update cascade on delete cascade,
    foreign key (cityId) references city(id) on update cascade on delete cascade
);

create table socialStatus(
	id int check (id > 0) not null primary key identity,
    name varchar(255) not null default ''
);

create table client(
	id int check (id > 0) not null primary key identity,
    name varchar(255) not null,
    socialStatusId int check (socialStatusId > 0) not null
);

create table account(
	id int check (id > 0) not null primary key identity,
    bankId int check (bankId > 0) not null,
    clientId int check (clientId > 0) not null,
    amount int default 0,
    foreign key (bankId) references bank(id) on update cascade on delete cascade,
    foreign key (clientId) references client(id) on update cascade on delete cascade
);

create table card(
	id int check (id > 0) not null primary key identity,
    accountId int check (accountId > 0) not null,
    amount int default 0,
    foreign key (accountId) references account(id) on update cascade on delete cascade
);

alter table  client
add constraint FK_socialRoleId foreign key (socialStatusId) references socialStatus(id) on update cascade on delete cascade;

GO

insert into bank(name) values ('Belarusbank'), ('VTB'), ('Belinvest'), ('BNB'), ('Belagroprombank');

insert into city(name) values ('Minsk'), ('Gomel'), ('Grodno'), ('Mogilev'), ('Brest');

insert into filial(cityId, adress, bankId) values (1, 'Yakuba Kolasa 12', 1), 
(2, 'Dimitrava 20', 1),
(2, 'Frunze 3', 2),
(2, 'Lenina 45', 2),
(3, 'Sovetskih Pogranichnikov 92', 3),
(1, 'Pobedi 12', 4),
(4, 'Mira 55', 5);

insert into socialStatus(name) values ('veteran'), ('disabled'), ('retiree'), ('unemployed'), ('base');

insert into client(name, socialStatusId) values ('Petr', 1), ('Ivan', 2), ('Dmitry', 5), ('Vasya', 4), ('Maxim', 3);

insert into account(bankId, clientId, amount) values (1, 1, 1000), (2, 2, 1000), (3, 3, 1000), (4, 4, 500), (5, 5, 500);

insert into card(accountId, amount) values (1, 100), (1, 100),
(2, 100), (2, 200),
(3, 50), (3, 150),
(4, 25), (4, 75),
(5, 155), (5, 145);

GO

--TASKS
-- 1st task
SELECT DISTINCT bank.name
FROM bank
JOIN filial ON bank.id = filial.bankId
JOIN city ON filial.cityId = city.id
WHERE city.name = 'Gomel';

-- 2nd task
SELECT card.amount, client.name, bank.name
FROM bank
JOIN account ON bank.id = account.bankId
JOIN client ON account.clientId = client.id
JOIN card ON account.id = card.accountid;

-- 3rd task
SELECT accountId, sum(card.amount) AS summ, account.amount - sum(card.amount) AS difference
FROM card
LEFT JOIN account ON account.id = card.accountId
GROUP BY accountId, account.amount
ORDER BY accountId;

-- 4.1 task (group by)
SELECT socialStatus.name, count(card.id)
FROM socialStatus
LEFT JOIN client ON client.socialStatusId = socialStatus.id
LEFT JOIN account ON client.id = account.clientId
LEFT JOIN card ON card.accountId = account.Id
GROUP BY socialStatus.name;

-- 4.2 task
SELECT status.name,(
		SELECT COUNT(*)
		FROM socialStatus AS status2
		LEFT JOIN client ON client.socialStatusId = status2.id
		LEFT JOIN account ON client.id = account.clientId
		LEFT JOIN card ON card.accountId = account.Id
		WHERE status2.name = status.name
		) AS cards
FROM socialStatus AS status;

-- 5 task
DROP PROCEDURE IF EXISTS add_money;

GO

CREATE PROCEDURE add_money (@status_id INT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @result INT;

	SELECT @result = count(*)
	FROM account
	JOIN client ON client.id = account.clientId
	JOIN socialStatus ON socialStatus.id = client.socialStatusId
	WHERE client.socialStatusId = @status_id;

	IF @result = 0
	BEGIN
		RAISERROR ('45000',16,1)
		PRINT 'There is no such status or people with it!';
	END

	UPDATE account
		SET account.amount = CASE 
			WHEN @result != 0
				THEN account.amount + 10
			ELSE account.amount
			END
	FROM account
	JOIN client ON client.id = account.clientId
	JOIN socialStatus ON socialStatus.id = client.socialStatusId
	WHERE socialStatus.id = @status_id;
END

GO

SELECT *
FROM account;

EXECUTE add_money @status_id = 11;

SELECT *
FROM account;

-- 6 task
SELECT a.id, (
		SELECT a2.amount - sum(card.amount)
		FROM account as a2
		JOIN card ON a2.id = card.accountId
		WHERE a.id = a2.id
		GROUP BY a2.amount
		) AS result
FROM account AS a;

-- task 7
DROP PROCEDURE
IF EXISTS transfer_money;

GO

CREATE PROCEDURE transfer_money (@amount INT, @cardId INT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @free_money INT;

	BEGIN TRY
		BEGIN TRANSACTION

		SELECT @free_money = account.amount - sum(card.amount)
		FROM account
		JOIN card ON card.accountId = account.id
		WHERE account.id = (
				SELECT account.id
				FROM account
				JOIN card ON account.id = card.accountId
				WHERE card.id = @cardId
				)
		GROUP BY account.id, account.amount;

		IF @amount > @free_money
		BEGIN
			RAISERROR ('45000',16,1);
		END

		UPDATE card
		SET card.amount = card.amount + @amount
		WHERE card.id = @cardId;

   END TRY
   BEGIN CATCH

      ROLLBACK TRANSACTION
	  SELECT 'Insufficent amount on account' AS MESSAGE
      SELECT ERROR_NUMBER() AS [Номер ошибки],
             ERROR_MESSAGE() AS [Описание ошибки]
	  RETURN

   END CATCH

	COMMIT TRANSACTION;
END

GO

SELECT *
FROM card;

EXEC transfer_money 5000, 9;

SELECT *
FROM card;

-- 8 task
DROP TRIGGER IF EXISTS TR_Amount_Update;

GO

CREATE TRIGGER TR_Amount_Update ON account
FOR UPDATE
AS
BEGIN
	DECLARE @current_cards INT;
	DECLARE @cards_money INT;
	DECLARE @old_amount INT;
	DECLARE @new_amount  INT;

	SELECT @old_amount = amount FROM deleted;
	SELECT @new_amount = amount FROM inserted;

	SELECT @current_cards = count(card.id)
	FROM account
	JOIN card ON card.accountId = account.id
	WHERE account.id = (SELECT id from inserted)
	GROUP BY account.id;

	SELECT @cards_money = sum(card.amount)
	FROM account
	JOIN card ON card.accountId = account.id
	WHERE account.id = (SELECT id from inserted)
	GROUP BY account.id;

	IF @current_cards > 0
	BEGIN
		IF @new_amount < @cards_money
		BEGIN
			PRINT 'The new value is less than the amount on existing cards'
			ROLLBACK TRANSACTION;
		END
	END
END

GO

SELECT *
FROM account;

UPDATE account
SET account.amount = 10
WHERE account.id = 1;

SELECT *
FROM account;